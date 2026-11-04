import 'dart:async';
import 'dart:convert';

import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:http/http.dart' as http;

/// A pair's doorbell: one tiny entry in the Firebase Realtime Database that the phone rings after each write a polling
/// device waits for, and that a Windows or Linux device listens to over one streamed HTTP connection (server-sent
/// events), so it reads its mailbox the moment something arrives instead of asking every few seconds. That is how
/// WhatsApp's desktop apps work: an open connection the server speaks on, not polling.
///
/// The entry holds only the time of the last ring. Its name is a blind index of the pair key, so only the two devices
/// can find it: the server never learns which pair it belongs to, and nobody else can listen or ring.
final class Doorbell {
  Doorbell({
    required this._config,
    required this._client,
    required this._idToken,
    required this._name,
    http.Client Function()? connect,
    this.silence = const Duration(seconds: 75),
    this.maxRetry = const Duration(minutes: 1),
  }) : _connect = connect ?? http.Client.new {
    _wakes = StreamController<void>.broadcast(onListen: _listen, onCancel: _stop);
  }

  final FirebaseRestConfig _config;
  final http.Client _client;
  final Future<String> Function({bool forceRefresh}) _idToken;
  final Future<String> Function() _name;
  final http.Client Function() _connect;

  /// The server sends a keep-alive every 30 seconds: this long without anything means the connection is dead.
  final Duration silence;

  /// The longest wait before connecting again after failures.
  final Duration maxRetry;

  late final StreamController<void> _wakes;
  http.Client? _open;
  var _listening = false;
  var _live = false;
  var _failures = 0;

  /// Whether the connection is up: rings will arrive, so the mailbox needs no frequent checks.
  bool get live => _live;

  /// An event for each ring, for the connection's first answer (catching up on what came meanwhile), and when the
  /// connection drops (back to checking often until it is up again).
  Stream<void> get wakes => _wakes.stream;

  /// Tells the listening device to read its mailbox now.
  Future<void> ring() async {
    Future<http.Response> put({bool forceRefresh = false}) async => _client.put(
      _config.database(await _path(), auth: await _idToken(forceRefresh: forceRefresh)),
      body: '{".sv":"timestamp"}',
    );
    var response = await put();
    if (response.statusCode == 401) response = await put(forceRefresh: true);
    if (response.statusCode != 200) throw SyncException(AppError.syncFailed, detail: 'doorbell ${response.statusCode}');
  }

  /// Takes the doorbell away: the pair has ended.
  Future<void> remove() async {
    final response = await _client.delete(_config.database(await _path(), auth: await _idToken()));
    if (response.statusCode != 200) throw SyncException(AppError.syncFailed, detail: 'doorbell ${response.statusCode}');
  }

  /// The doorbell's name for a pair: a blind index of its key, so only its two devices can find it.
  static Future<String> nameFor(PairCipher cipher) => cipher.blindIndex('air_reply.doorbell');

  void dispose() {
    _stop();
    unawaited(_wakes.close());
  }

  Future<String> _path() async => 'doorbells/${await _name()}';

  void _listen() {
    _listening = true;
    unawaited(_run());
  }

  void _stop() {
    _listening = false;
    _live = false;
    _open?.close();
  }

  Future<void> _run() async {
    var refresh = false;
    while (_listening) {
      final client = _open = _connect();
      var again = Duration.zero;
      try {
        final request = http.Request(
          'GET',
          _config.database(await _path(), auth: await _idToken(forceRefresh: refresh)),
        )..headers['accept'] = 'text/event-stream';
        refresh = false;
        final response = await client.send(request);
        if (response.statusCode == 401) {
          refresh = true;
          throw const SyncException(AppError.syncFailed, detail: 'doorbell sign-in expired');
        }
        if (response.statusCode != 200) {
          throw SyncException(AppError.syncFailed, detail: 'doorbell ${response.statusCode}');
        }
        String? event;
        await for (final line
            in response.stream.transform(utf8.decoder).transform(const LineSplitter()).timeout(silence)) {
          if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            switch (event) {
              case 'put' || 'patch':
                _connected();
                _wakes.add(null);
              case 'keep-alive':
                _connected();
              case 'auth_revoked':
                // the ID token expired (they last an hour): connect again with a fresh one, at once
                refresh = true;
                break;
              case 'cancel':
                throw const SyncException(AppError.syncFailed, detail: 'doorbell refused');
            }
            if (refresh) break;
          }
        }
        // the server closed it: connect again, waiting longer each time it keeps happening
        if (!refresh) throw const SyncException(AppError.syncFailed, detail: 'doorbell closed');
      } on Object catch (e) {
        if (_listening && !refresh) {
          if (_failures++ == 0) appLog('Doorbell disconnected: $e', name: 'air_reply.sync');
          final backoff = Duration(seconds: 1 << (_failures < 7 ? _failures : 6));
          again = backoff > maxRetry ? maxRetry : backoff;
        }
      } finally {
        client.close();
        if (_live) {
          _live = false;
          // check the mailbox now, and often, until the doorbell is back
          if (!_wakes.isClosed) _wakes.add(null);
        }
      }
      if (again > Duration.zero) await Future<void>.delayed(again);
    }
  }

  void _connected() {
    _live = true;
    _failures = 0;
  }
}
