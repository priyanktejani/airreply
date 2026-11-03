import 'dart:convert';

import 'package:air_reply/core/firebase/rest/document_polls.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/rest_auth_gateway.dart';
import 'package:air_reply/core/firebase/server_time.dart';
import 'package:air_reply/features/mirror/data/rest_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:air_reply/features/pairing/data/rest_pairing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../support/fakes.dart';

const _config = FirebaseRestConfig(apiKey: 'key', projectId: 'demo');
const _root = 'projects/demo/databases/(default)/documents';

/// A fake Google backend: records Firestore requests and answers auth calls.
final class _Backend {
  final firestoreRequests = <http.Request>[];
  var signUps = 0;
  var refreshes = 0;
  http.Response Function(http.Request request) firestore = (_) => http.Response('{}', 200);

  late final client = MockClient((request) async {
    final url = request.url.toString();
    if (url.contains('accounts:signUp')) {
      signUps++;
      return _json({'localId': 'uid-1', 'idToken': 'id-$signUps', 'refreshToken': 'refresh-1', 'expiresIn': '3600'});
    }
    if (url.contains('securetoken')) {
      refreshes++;
      return _json({
        'user_id': 'uid-1',
        'id_token': 'refreshed-$refreshes',
        'refresh_token': 'refresh-1',
        'expires_in': '3600',
      });
    }
    firestoreRequests.add(request);
    return firestore(request);
  });

  static http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);
}

void main() {
  late _Backend backend;
  late MemorySecretStore secrets;
  late RestAuthGateway auth;
  late FirestoreRestClient client;

  setUp(() {
    backend = _Backend();
    secrets = MemorySecretStore();
    auth = RestAuthGateway(_config, backend.client, secrets);
    client = FirestoreRestClient(_config, backend.client, auth);
  });

  group('RestAuthGateway', () {
    test('signs up once, then reuses the session and keeps the uid across restarts', () async {
      expect(await auth.ensureSignedIn(), 'uid-1');
      expect(await auth.idToken(), 'id-1');
      expect(backend.signUps, 1);

      // A new process: the refresh token from the secret store brings back the same anonymous user.
      final restarted = RestAuthGateway(_config, backend.client, secrets);
      expect(await restarted.ensureSignedIn(), 'uid-1');
      expect(await restarted.idToken(), 'refreshed-1');
      expect(backend.signUps, 1);
      expect(backend.refreshes, 1);
    });

    test('concurrent callers share one sign-in', () async {
      await Future.wait([auth.idToken(), auth.idToken(), auth.ensureSignedIn()]);
      expect(backend.signUps, 1);
    });
  });

  group('FirestoreRestClient', () {
    test('encodes values, server timestamps and preconditions in commits', () async {
      await client.commit([
        RestWrite.set('pairs/p1/notifications/n1', {
          'payload': 'v1.abc',
          'canReply': true,
          'count': 3,
          'postedAt': DateTime.utc(2026, 10, 24, 12),
          'members': ['a', 'b'],
          'meta': {'x': null},
          'createdAt': ServerTime.value,
        }, mustNotExist: true),
        RestWrite.update('pairs/p1', {'active': false, 'deactivatedAt': ServerTime.value}),
        const RestWrite.delete('pairingSessions/123456'),
      ]);

      final request = backend.firestoreRequests.single;
      expect(request.url.path, '/v1/$_root:commit');
      expect(request.headers['authorization'], 'Bearer id-1');
      final writes = (jsonDecode(request.body) as Map)['writes'] as List;

      expect(writes[0], {
        'update': {
          'name': '$_root/pairs/p1/notifications/n1',
          'fields': {
            'payload': {'stringValue': 'v1.abc'},
            'canReply': {'booleanValue': true},
            'count': {'integerValue': '3'},
            'postedAt': {'timestampValue': '2026-10-24T12:00:00.000Z'},
            'members': {
              'arrayValue': {
                'values': [
                  {'stringValue': 'a'},
                  {'stringValue': 'b'},
                ],
              },
            },
            'meta': {
              'mapValue': {
                'fields': {
                  'x': {'nullValue': null},
                },
              },
            },
          },
        },
        'updateTransforms': [
          {'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'},
        ],
        'currentDocument': {'exists': false},
      });
      final update = writes[1] as Map;
      expect(update['updateMask'], {
        'fieldPaths': ['active'],
      });
      expect(update['currentDocument'], {'exists': true});
      expect(writes[2], {'delete': '$_root/pairingSessions/123456'});
    });

    test('reads documents into plain Dart values, and a missing one as null', () async {
      backend.firestore = (request) => request.url.path.endsWith('missing')
          ? http.Response('{"error":{"status":"NOT_FOUND"}}', 404)
          : http.Response(
              jsonEncode({
                'name': '$_root/pairs/p1',
                'updateTime': '2026-10-24T12:00:00.123456Z',
                'fields': {
                  'active': {'booleanValue': true},
                  'createdAt': {'timestampValue': '2026-10-24T11:00:00Z'},
                  'members': {
                    'arrayValue': {
                      'values': [
                        {'stringValue': 'a'},
                      ],
                    },
                  },
                },
              }),
              200,
            );

      final doc = (await client.get('pairs/p1'))!;
      expect(doc.id, 'p1');
      expect(doc.path, 'pairs/p1');
      expect(doc.data, {
        'active': true,
        'createdAt': DateTime.utc(2026, 10, 24, 11),
        'members': ['a'],
      });
      expect(await client.get('pairs/missing'), isNull);
    });

    test('builds structured queries on subcollections', () async {
      backend.firestore = (_) => http.Response(
        jsonEncode([
          {'readTime': '2026-10-24T12:00:00Z'},
        ]),
        200,
      );

      final docs = await client.runQuery(
        RestQuery(
          'notifications',
          filters: [
            const RestFilter('keyHash', RestOperator.equal, 'h'),
            const RestFilter('status', RestOperator.equal, 'PENDING'),
          ],
          limit: 50,
        ),
        parent: 'pairs/p1',
      );

      expect(docs, isEmpty);
      final request = backend.firestoreRequests.single;
      expect(request.url.path, '/v1/$_root/pairs/p1:runQuery');
      final query = (jsonDecode(request.body) as Map)['structuredQuery'] as Map;
      expect(query['from'], [
        {'collectionId': 'notifications'},
      ]);
      expect((query['where'] as Map)['compositeFilter'], {
        'op': 'AND',
        'filters': [
          {
            'fieldFilter': {
              'field': {'fieldPath': 'keyHash'},
              'op': 'EQUAL',
              'value': {'stringValue': 'h'},
            },
          },
          {
            'fieldFilter': {
              'field': {'fieldPath': 'status'},
              'op': 'EQUAL',
              'value': {'stringValue': 'PENDING'},
            },
          },
        ],
      });
      expect(query['limit'], 50);
    });

    test('refreshes the ID token once on 401, and surfaces other errors with their status', () async {
      var calls = 0;
      backend.firestore = (request) {
        calls++;
        if (calls == 1) return http.Response('{"error":{"status":"UNAUTHENTICATED"}}', 401);
        if (calls == 2) return http.Response('{}', 200);
        return http.Response('{"error":{"status":"PERMISSION_DENIED","message":"no"}}', 403);
      };

      await client.commit(const [RestWrite.delete('pairs/p1')]);
      expect(backend.refreshes, 1);
      expect(backend.firestoreRequests.last.headers['authorization'], 'Bearer refreshed-1');

      await expectLater(
        client.commit(const [RestWrite.delete('pairs/p1')]),
        throwsA(isA<RestFirestoreException>().having((e) => e.status, 'status', 'PERMISSION_DENIED')),
      );
    });
  });

  group('document polls', () {
    test('a pair polled for its status and for whether it is active is read once per interval', () async {
      backend.firestore = (_) => http.Response(
        jsonEncode({
          'name': '$_root/pairs/p1',
          'fields': {
            'active': {'booleanValue': true},
          },
          'updateTime': '2026-11-04T00:00:00Z',
        }),
        200,
      );
      final polls = DocumentPolls(client, every: const Duration(milliseconds: 40));
      final pairing = RestPairingRepository(client, auth, pairPolls: polls);
      final mailbox = RestMailbox(client, 'p1', pairPolls: polls);

      final active = <bool>[];
      final states = <SyncHealth>[];
      final a = pairing.watchPairActive('p1').listen(active.add);
      final b = mailbox.watchSyncState().listen((s) => states.add(s.health));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await a.cancel();
      await b.cancel();

      expect(active, [true]);
      expect(states, everyElement(SyncHealth.live));
      final reads = backend.firestoreRequests.where((r) => r.method == 'GET').length;
      expect(reads, inInclusiveRange(3, 5), reason: 'one read per interval for both watchers, not two');

      // nobody watching: the poll stops
      final after = backend.firestoreRequests.length;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(backend.firestoreRequests.length, after);
    });

    test('a pair that is gone reads as inactive, and the connection as offline', () async {
      backend.firestore = (_) => http.Response('{"error":{"status":"PERMISSION_DENIED","message":"no"}}', 403);
      final polls = DocumentPolls(client, every: const Duration(seconds: 30));
      final pairing = RestPairingRepository(client, auth, pairPolls: polls);
      final mailbox = RestMailbox(client, 'p1', pairPolls: polls);
      expect(await pairing.watchPairActive('p1').first, isFalse);
      expect((await mailbox.watchSyncState().first).health, isNot(SyncHealth.live));
    });
  });
}
