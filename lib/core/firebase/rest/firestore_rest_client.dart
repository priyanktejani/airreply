import 'dart:convert';
import 'dart:math';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/rest_auth_gateway.dart';
import 'package:air_reply/core/firebase/server_time.dart';
import 'package:http/http.dart' as http;

/// A document read over REST. [data] holds plain Dart values (timestamps as UTC [DateTime]).
final class RestDocument {
  const RestDocument({required this.path, required this.data, required this.updateTime});

  /// Relative to the database root, e.g. `pairs/abc/notifications/xyz`.
  final String path;
  final Map<String, Object?> data;

  /// Server-side version, usable as a write precondition (optimistic concurrency).
  final DateTime updateTime;

  String get id => path.substring(path.lastIndexOf('/') + 1);
}

/// One write of an atomic [FirestoreRestClient.commit].
sealed class RestWrite {
  const RestWrite(this.path);

  final String path;

  /// Creates (or replaces) the whole document. [mustNotExist] fails the commit if it already exists.
  const factory RestWrite.set(String path, Map<String, Object?> data, {bool mustNotExist}) = _SetWrite;

  /// Changes only the given fields of an existing document; [ifUpdateTime] makes it conditional on the version read.
  const factory RestWrite.update(String path, Map<String, Object?> data, {DateTime? ifUpdateTime}) = _UpdateWrite;

  const factory RestWrite.delete(String path) = _DeleteWrite;
}

final class _SetWrite extends RestWrite {
  const _SetWrite(super.path, this.data, {this.mustNotExist = false});
  final Map<String, Object?> data;
  final bool mustNotExist;
}

final class _UpdateWrite extends RestWrite {
  const _UpdateWrite(super.path, this.data, {this.ifUpdateTime});
  final Map<String, Object?> data;
  final DateTime? ifUpdateTime;
}

final class _DeleteWrite extends RestWrite {
  const _DeleteWrite(super.path);
}

enum RestOperator { equal }

final class RestFilter {
  const RestFilter(this.field, this.op, this.value);

  final String field;
  final RestOperator op;
  final Object? value;
}

/// The subset of Firestore structured queries the app needs: equality filters and a limit.
final class RestQuery {
  const RestQuery(this.collection, {this.filters = const [], this.limit});

  final String collection;
  final List<RestFilter> filters;
  final int? limit;
}

/// Failure reported by the Firestore REST API. [status] is the gRPC status name, e.g. `FAILED_PRECONDITION`.
final class RestFirestoreException implements Exception {
  const RestFirestoreException(this.status, this.message);

  final String status;
  final String message;

  @override
  String toString() => 'RestFirestoreException($status): $message';
}

/// Minimal Cloud Firestore client over the REST API (v1), authenticated as the anonymous user of [RestAuthGateway].
/// Security rules apply exactly as for the SDKs.
final class FirestoreRestClient {
  FirestoreRestClient(this._config, this._http, this._auth, {Random? random}) : _random = random ?? Random.secure();

  final FirebaseRestConfig _config;
  final http.Client _http;
  final RestAuthGateway _auth;
  final Random _random;

  static const _idAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// A random 20-character id, like the SDKs generate.
  String newId() =>
      String.fromCharCodes(Iterable.generate(20, (_) => _idAlphabet.codeUnitAt(_random.nextInt(_idAlphabet.length))));

  /// Null when the document does not exist.
  Future<RestDocument?> get(String path) async {
    final json = await _send('GET', '${_config.documentsRoot}/$path', allowNotFound: true);
    return json == null ? null : _document((json as Map).cast<String, Object?>());
  }

  /// Runs [query] on the collection under [parent] (`''` for top-level collections, `pairs/abc` for subcollections).
  Future<List<RestDocument>> runQuery(RestQuery query, {String parent = ''}) async {
    final resource = parent.isEmpty ? _config.documentsRoot : '${_config.documentsRoot}/$parent';
    final rows = await _send('POST', '$resource:runQuery', body: {'structuredQuery': _structuredQuery(query)});
    return [
      for (final row in (rows as List<Object?>? ?? const []).cast<Map<String, Object?>>())
        if (row['document'] case final Map<String, Object?> doc) _document(doc),
    ];
  }

  /// Applies [writes] atomically.
  Future<void> commit(List<RestWrite> writes) =>
      _send('POST', '${_config.documentsRoot}:commit', body: {'writes': writes.map(_write).toList()});

  // ------------------------------------------------------------------ HTTP

  Future<Object?> _send(String method, String resource, {Object? body, bool allowNotFound = false}) async {
    for (var attempt = 0; ; attempt++) {
      final request = http.Request(method, _config.firestore(resource))
        ..headers['authorization'] = 'Bearer ${await _auth.idToken(forceRefresh: attempt > 0)}'
        ..headers['content-type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);

      final http.Response response;
      try {
        response = await http.Response.fromStream(await _http.send(request));
      } on Exception catch (e) {
        throw SyncException(AppError.offline, cause: e);
      }

      if (response.statusCode == 200) return response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 404 && allowNotFound) return null;
      if (response.statusCode == 401 && attempt == 0) continue; // expired token: refresh once and retry

      final error = _decodeError(response.body);
      throw RestFirestoreException(error.$1, error.$2);
    }
  }

  static (String, String) _decodeError(String body) {
    try {
      final error = ((jsonDecode(body) as Map)['error'] as Map).cast<String, Object?>();
      return ('${error['status'] ?? error['code']}', '${error['message']}');
    } on Object {
      return ('UNKNOWN', body);
    }
  }

  // ------------------------------------------------------------------ encoding

  RestDocument _document(Map<String, Object?> json) {
    final name = json['name']! as String;
    return RestDocument(
      path: name.substring(_config.documentsRoot.length + 1),
      data: _decodeFields(json['fields'] as Map<String, Object?>?),
      updateTime: DateTime.parse(json['updateTime']! as String),
    );
  }

  Map<String, Object?> _write(RestWrite write) {
    final name = '${_config.documentsRoot}/${write.path}';
    return switch (write) {
      _SetWrite(:final data, :final mustNotExist) => {
        'update': {'name': name, 'fields': _encodeFields(data)},
        ..._serverTimeTransforms(data),
        if (mustNotExist) 'currentDocument': {'exists': false},
      },
      _UpdateWrite(:final data, :final ifUpdateTime) => {
        'update': {'name': name, 'fields': _encodeFields(data)},
        'updateMask': {
          'fieldPaths': [
            for (final e in data.entries)
              if (e.value is! ServerTime) e.key,
          ],
        },
        ..._serverTimeTransforms(data),
        'currentDocument': ifUpdateTime == null ? {'exists': true} : {'updateTime': _timestamp(ifUpdateTime)},
      },
      _DeleteWrite() => {'delete': name},
    };
  }

  /// Fields set to [ServerTime] become `REQUEST_TIME` transforms (omitted entirely when there are none).
  static Map<String, Object?> _serverTimeTransforms(Map<String, Object?> data) {
    final transforms = [
      for (final e in data.entries)
        if (e.value is ServerTime) {'fieldPath': e.key, 'setToServerValue': 'REQUEST_TIME'},
    ];
    return transforms.isEmpty ? const {} : {'updateTransforms': transforms};
  }

  Map<String, Object?> _structuredQuery(RestQuery query) {
    Map<String, Object?> fieldFilter(RestFilter f) => {
      'fieldFilter': {
        'field': {'fieldPath': f.field},
        'op': switch (f.op) {
          RestOperator.equal => 'EQUAL',
        },
        'value': _encodeValue(f.value),
      },
    };

    return {
      'from': [
        {'collectionId': query.collection},
      ],
      if (query.filters.length == 1) 'where': fieldFilter(query.filters.single),
      if (query.filters.length > 1)
        'where': {
          'compositeFilter': {'op': 'AND', 'filters': query.filters.map(fieldFilter).toList()},
        },
      if (query.limit != null) 'limit': query.limit,
    };
  }

  static Map<String, Object?> _encodeFields(Map<String, Object?> data) => {
    for (final e in data.entries)
      if (e.value is! ServerTime) e.key: _encodeValue(e.value),
  };

  static Map<String, Object?> _encodeValue(Object? value) => switch (value) {
    null => {'nullValue': null},
    bool() => {'booleanValue': value},
    int() => {'integerValue': '$value'},
    double() => {'doubleValue': value},
    String() => {'stringValue': value},
    DateTime() => {'timestampValue': _timestamp(value)},
    List<Object?>() => {
      'arrayValue': {'values': value.map(_encodeValue).toList()},
    },
    Map<String, Object?>() => {
      'mapValue': {'fields': _encodeFields(value)},
    },
    _ => throw ArgumentError('Unsupported Firestore value: ${value.runtimeType}'),
  };

  static Map<String, Object?> _decodeFields(Map<String, Object?>? fields) => {
    for (final e in (fields ?? const {}).entries) e.key: _decodeValue((e.value! as Map).cast<String, Object?>()),
  };

  static Object? _decodeValue(Map<String, Object?> value) {
    final MapEntry(:key, value: raw) = value.entries.single;
    return switch (key) {
      'nullValue' => null,
      'booleanValue' => raw! as bool,
      'integerValue' => int.parse('$raw'),
      'doubleValue' => (raw! as num).toDouble(),
      'stringValue' => raw! as String,
      'timestampValue' => DateTime.parse(raw! as String),
      'arrayValue' => [
        for (final v in ((raw! as Map)['values'] as List<Object?>? ?? const []))
          _decodeValue((v! as Map).cast<String, Object?>()),
      ],
      'mapValue' => _decodeFields(((raw! as Map)['fields'] as Map?)?.cast<String, Object?>()),
      _ => raw, // bytes, references, geo points: not used by the app
    };
  }

  static String _timestamp(DateTime time) => time.toUtc().toIso8601String();
}
