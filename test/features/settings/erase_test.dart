import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/firebase/auth_gateway.dart';
import 'package:air_reply/features/mirror/cleanup_providers.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/data/secure_archived_pairs_store.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/settings/erase_everything.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

PairingCredentials pair(String id) => PairingCredentials(
  pairId: id,
  role: DeviceRole.receiver,
  sharedKey: Uint8List(32),
  peerName: 'Pixel 9',
  pairedAt: DateTime(2026, 3),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemorySecretStore secrets;
  late _FakeAuth auth;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    secrets = MemorySecretStore()..values.addAll({'air_reply.pairs.v2': '[]', 'air_reply.history_key': 'k'});
    auth = _FakeAuth();
  });

  group('a fresh install', () {
    ProviderContainer container() => ProviderContainer(
      overrides: [secretStoreProvider.overrideWithValue(secrets), authGatewayProvider.overrideWithValue(auth)],
    );

    test('forgets what an earlier install left in the keychain (Apple keeps it after the app is deleted)', () async {
      await forgetEarlierInstall(container());
      expect(secrets.values, isEmpty);
      expect(auth.signedOut, isTrue);
      expect(auth.deleted, isFalse, reason: 'the other devices may still be paired with that account');
      expect(await SharedPreferencesAsync().getBool(installedKey), isTrue);
    });

    test('an upgrade from a version before the mark keeps everything, and so does every later start', () async {
      await SharedPreferencesAsync().setString('air_reply.preferences.v1', '{}');
      await forgetEarlierInstall(container());
      await forgetEarlierInstall(container());
      expect(secrets.values, isNotEmpty);
      expect(auth.signedOut, isFalse);
    });
  });

  group('erasing everything', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    late List<String> alertCalls;
    late HistoryDatabase db;

    setUp(() {
      alertCalls = [];
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        alertCalls.add(call.method);
        return call.method == 'getNotificationChannels' ? <Object?>[] : null;
      });
      db = HistoryDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      await db.close();
    });

    test('leaves nothing: no pairs, history, keys, sign-in, alerts or settings, here or on the server', () async {
      final backend = InMemoryPairingRepository()..pairs['active'] = true;
      final store = InMemoryCredentialsStore()..pairs.add(pair('active'));
      final archive = SecureArchivedPairsStore(MemorySecretStore());
      await archive.save(ArchivedPair(pair('removed'), unpairedAt: DateTime(2026, 5)));
      await MessageHistory(
        db,
        'removed',
      ).putNotifications([StoredNotification(id: 'n', payload: 'sealed', postedAt: DateTime(2026, 4))]);
      await SharedPreferencesAsync().setString('air_reply.preferences.v1', '{"haptics":false}');
      final container = ProviderContainer(
        overrides: [
          secretStoreProvider.overrideWithValue(secrets),
          authGatewayProvider.overrideWithValue(auth),
          pairingRepositoryProvider.overrideWithValue(backend),
          pairingCredentialsStoreProvider.overrideWithValue(store),
          archivedPairsStoreProvider.overrideWithValue(archive),
          historyDatabaseProvider.overrideWithValue(db),
          notificationBridgeProvider.overrideWithValue(FakeNotificationBridge()),
          removeDoorbellProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);

      await container.read(eraseEverythingProvider)();

      expect(backend.pairs['active'], isFalse, reason: 'the other device sees the pair end');
      expect(store.pairs, isEmpty);
      expect(await archive.readAll(), isEmpty);
      expect((await MessageHistory(db, 'removed').size()).notifications, 0);
      expect(secrets.values, isEmpty);
      expect(auth.deleted, isTrue, reason: 'no account left on the server');
      expect(alertCalls, contains('cancelAll'));
      expect((await SharedPreferencesAsync().getKeys()), {installedKey});
    });
  });
}

final class _FakeAuth implements AuthGateway {
  var signedOut = false;
  var deleted = false;

  @override
  String? get currentUid => signedOut ? null : 'me';

  @override
  Future<String> ensureSignedIn() async => 'me';

  @override
  Future<String> idToken({bool forceRefresh = false}) async => 'token';

  @override
  Future<void> signOut({bool deleteAccount = false}) async {
    signedOut = true;
    deleted = deleteAccount;
  }
}
