import 'dart:async';
import 'dart:convert';

import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/polling.dart';
import 'package:air_reply/features/mirror/data/doorbell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = FirebaseRestConfig(apiKey: 'k', projectId: 'demo', databaseEmulatorHost: '127.0.0.1:9000');
const _bell = '0123456789abcdef0123456789abcdef';

/// The Realtime Database's side of the doorbell: each listening connection is a stream of server-sent events.
final class _Server {
  final connections = <http.BaseRequest>[];
  final streams = <StreamController<List<int>>>[];
  final puts = <http.Request>[];
  var refuseNextPut = false;

  http.Client connect() => MockClient.streaming((request, _) async {
    connections.add(request);
    final events = StreamController<List<int>>();
    streams.add(events);
    return http.StreamedResponse(events.stream, 200, headers: {'content-type': 'text/event-stream'});
  });

  late final http.Client client = MockClient((request) async {
    puts.add(request);
    if (refuseNextPut) {
      refuseNextPut = false;
      return http.Response('{"error":"Permission denied"}', 401);
    }
    return http.Response('1730000000000', 200);
  });

  void send(String event, String data) => streams.last.add(utf8.encode('event: $event\ndata: $data\n\n'));
}

void main() {
  late _Server server;
  late List<bool> refreshes;

  Doorbell bell({Duration silence = const Duration(seconds: 75)}) => Doorbell(
    config: _config,
    client: server.client,
    idToken: ({bool forceRefresh = false}) async {
      refreshes.add(forceRefresh);
      return forceRefresh ? 'fresh' : 'token';
    },
    name: () async => _bell,
    connect: server.connect,
    silence: silence,
    maxRetry: const Duration(milliseconds: 20),
  );

  Future<void> settle([int ms = 30]) => Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    server = _Server();
    refreshes = [];
  });

  test('listens over one streamed connection; each ring wakes the device at once', () async {
    final doorbell = bell();
    var wakes = 0;
    final sub = doorbell.wakes.listen((_) => wakes++);
    await settle();

    final request = server.connections.single;
    expect(request.url.path, '/doorbells/$_bell.json');
    expect(request.url.queryParameters, {'ns': 'demo-default-rtdb', 'auth': 'token'});
    expect(request.headers['accept'], 'text/event-stream');
    expect(doorbell.live, isFalse);

    server.send('put', '{"path":"/","data":null}'); // the first answer: catch up
    await settle();
    expect((wakes, doorbell.live), (1, true));

    server
      ..send('keep-alive', 'null')
      ..send('put', '{"path":"/","data":1730000000000}');
    await settle();
    expect(wakes, 2, reason: 'a keep-alive is not a ring');

    await sub.cancel();
    expect(doorbell.live, isFalse);
  });

  test('an expired sign-in reconnects at once with a fresh token', () async {
    final sub = bell().wakes.listen((_) {});
    await settle();
    server.send('auth_revoked', '"credential is no longer valid"');
    await settle();
    expect(server.connections, hasLength(2));
    expect(server.connections.last.url.queryParameters['auth'], 'fresh');
    await sub.cancel();
  });

  test('a dropped connection sends the mailbox checking again, and reconnects', () async {
    final doorbell = bell();
    var wakes = 0;
    final sub = doorbell.wakes.listen((_) => wakes++);
    await settle();
    server.send('put', '{"path":"/","data":null}');
    await settle();
    expect(doorbell.live, isTrue);

    await server.streams.last.close();
    await settle(60);
    expect(wakes, 2, reason: 'dropping wakes the mailbox, so it checks now and goes back to frequent checks');
    expect(server.connections, hasLength(greaterThanOrEqualTo(2)), reason: 'reconnected');
    await sub.cancel();
  });

  test('a silent connection is taken for dead and replaced', () async {
    final sub = bell(silence: const Duration(milliseconds: 30)).wakes.listen((_) {});
    await settle(120);
    expect(server.connections.length, greaterThanOrEqualTo(2));
    await sub.cancel();
  });

  test('ringing writes the server time, retrying once with a fresh sign-in', () async {
    server.refuseNextPut = true;
    await bell().ring();
    expect(server.puts, hasLength(2));
    expect(server.puts.last.method, 'PUT');
    expect(server.puts.last.url.path, '/doorbells/$_bell.json');
    expect(server.puts.last.body, '{".sv":"timestamp"}');
    expect(refreshes, [false, true]);
  });

  test('a poll woken by a ring reads at once, and waits longer while the doorbell is live', () async {
    final wake = StreamController<void>.broadcast();
    var reads = 0;
    final poll = pollingStream<int>(
      () async => ++reads,
      every: const Duration(milliseconds: 20),
      wake: wake.stream,
      slower: () => const Duration(hours: 1),
    ).listen((_) {});
    await settle();
    expect(reads, 1, reason: 'the first read, then nothing for an hour');
    wake.add(null);
    await settle();
    expect(reads, 2);
    await poll.cancel();
  });
}
