import 'dart:convert';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/auth_gateway.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/storage/secret_store.dart';
import 'package:http/http.dart' as http;

/// Anonymous Firebase Auth over the Identity Toolkit REST API, for platforms without FlutterFire.
///
/// The refresh token is kept in the OS secret store, so this install keeps the same uid across restarts (pair
/// membership in the security rules is by uid). ID tokens live in memory and are refreshed shortly before expiry.
final class RestAuthGateway implements AuthGateway {
  RestAuthGateway(this._config, this._http, this._secrets, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _storageKey = 'air_reply.rest_auth.v1';
  static const _refreshMargin = Duration(minutes: 2);

  final FirebaseRestConfig _config;
  final http.Client _http;
  final SecretStore _secrets;
  final DateTime Function() _clock;

  _Session? _session;
  Future<_Session>? _inFlight;

  @override
  String? get currentUid => _session?.uid;

  @override
  Future<String> ensureSignedIn() async => (await _validSession()).uid;

  /// A fresh ID token for the `Authorization: Bearer` header.
  Future<String> idToken({bool forceRefresh = false}) async {
    if (forceRefresh && _session != null) _session = _session!.expired();
    return (await _validSession()).idToken!;
  }

  // One sign-in / refresh at a time, however many requests ask for a token at once.
  Future<_Session> _validSession() => _inFlight ??= _resolve().whenComplete(() => _inFlight = null);

  Future<_Session> _resolve() async {
    var session = _session ?? await _load();
    if (session == null) {
      session = await _signUp();
    } else if (session.idToken == null || session.expiresAt.isBefore(_clock().add(_refreshMargin))) {
      session = await _refresh(session);
    }
    _session = session;
    return session;
  }

  Future<_Session> _signUp() async {
    final Map<String, Object?> json;
    try {
      json = await _post(_config.identityToolkit('accounts:signUp'), jsonEncode({'returnSecureToken': true}), {
        'content-type': 'application/json',
      });
    } on _AuthRejected {
      throw const SyncException('Sign-in was refused. Is Anonymous sign-in enabled in the Firebase project?');
    }
    final session = _Session(
      uid: json['localId']! as String,
      refreshToken: json['refreshToken']! as String,
      idToken: json['idToken']! as String,
      expiresAt: _expiry(json['expiresIn']),
    );
    await _save(session);
    return session;
  }

  Future<_Session> _refresh(_Session session) async {
    try {
      final json = await _post(
        _config.secureToken,
        'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(session.refreshToken)}',
        {'content-type': 'application/x-www-form-urlencoded'},
      );
      final refreshed = _Session(
        uid: json['user_id']! as String,
        refreshToken: json['refresh_token']! as String,
        idToken: json['id_token']! as String,
        expiresAt: _expiry(json['expires_in']),
      );
      if (refreshed.refreshToken != session.refreshToken) await _save(refreshed);
      return refreshed;
    } on _AuthRejected {
      // The account was deleted or the token revoked: start over as a new anonymous user (unpaired).
      await _secrets.delete(_storageKey);
      return _signUp();
    }
  }

  Future<Map<String, Object?>> _post(Uri uri, String body, Map<String, String> headers) async {
    final http.Response response;
    try {
      response = await _http.post(uri, headers: headers, body: body);
    } on Exception catch (e) {
      throw SyncException('Could not reach AirReply servers. Check your connection.', cause: e);
    }
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    if (response.statusCode == 200) return json;
    if (response.statusCode == 400) throw _AuthRejected();
    throw SyncException('Sign-in failed (${response.statusCode}).', cause: json['error']);
  }

  DateTime _expiry(Object? expiresInSeconds) =>
      _clock().add(Duration(seconds: int.tryParse('$expiresInSeconds') ?? 3600));

  Future<_Session?> _load() async {
    final raw = await _secrets.read(_storageKey);
    if (raw == null) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, Object?>();
      return _Session(uid: json['uid']! as String, refreshToken: json['refreshToken']! as String);
    } on Object {
      return null;
    }
  }

  Future<void> _save(_Session session) =>
      _secrets.write(_storageKey, jsonEncode({'uid': session.uid, 'refreshToken': session.refreshToken}));
}

final class _Session {
  _Session({required this.uid, required this.refreshToken, this.idToken, DateTime? expiresAt})
    : expiresAt = expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String uid;
  final String refreshToken;
  final String? idToken;
  final DateTime expiresAt;

  _Session expired() => _Session(uid: uid, refreshToken: refreshToken);
}

final class _AuthRejected implements Exception {}
