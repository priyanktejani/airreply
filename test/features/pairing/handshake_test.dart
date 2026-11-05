import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/mirror/cleanup_providers.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/data/secure_archived_pairs_store.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/pairing/presentation/controllers/sender_pairing_controller.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

void main() {
  final crypto = CryptoService();
  late InMemoryPairingRepository backend;

  setUp(() => backend = InMemoryPairingRepository());

  /// A session the receiver joined, with both sides' secrets.
  Future<(JoinedPairing, PairingSecrets)> joined() async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final joined = await JoinPairingSession(
      backend,
      crypto,
      const FixedDeviceIdentity('MacBook'),
    ).call(code: pending.session.code);
    return (joined, await DeriveSenderSecrets(crypto).call(pending, joined.session));
  }

  group('the phone confirms', () {
    test('keeps the key before the server has the pair, and acknowledges it', () async {
      final (join, secrets) = await joined();
      final store = InMemoryCredentialsStore();
      final credentials = await ConfirmSenderPairing(backend, store).call(join.session, secrets);

      expect(store.single?.pairId, credentials.pairId);
      expect(backend.pairs[credentials.pairId], isTrue);
      expect(backend.ready[credentials.pairId], {DeviceRole.sender});
    });

    test('a confirmation the server refuses takes the key away again: neither side is half paired', () async {
      final (join, secrets) = await joined();
      final store = InMemoryCredentialsStore();
      await expectLater(
        ConfirmSenderPairing(_RefusingBackend(backend), store).call(join.session, secrets),
        throwsA(isA<SyncException>()),
      );
      expect(store.pairs, isEmpty);
    });

    test(
      'a slow confirmation keeps the key: the receiver may still get it, and its acknowledgement will tell',
      () async {
        final (join, secrets) = await joined();
        final store = InMemoryCredentialsStore();
        final credentials = await ConfirmSenderPairing(
          _SlowBackend(backend),
          store,
          serverTimeout: const Duration(milliseconds: 20),
        ).call(join.session, secrets);
        expect(store.single?.pairId, credentials.pairId);
      },
    );
  });

  group('the receiver finishes', () {
    test('keeps the key and acknowledges the pair, retrying when the first tries fail', () async {
      final (join, secrets) = await joined();
      await ConfirmSenderPairing(backend, InMemoryCredentialsStore()).call(join.session, secrets);
      final flaky = _FlakyAckBackend(backend, failures: 2);
      final store = InMemoryCredentialsStore();

      final credentials = await FinishReceiverPairing(
        store,
        flaky,
        retryDelay: Duration.zero,
      ).call(join, backend.sessions[join.session.code]!);

      expect(store.single?.pairId, credentials.pairId);
      expect(flaky.attempts, 3);
      expect(backend.ready[credentials.pairId], containsAll({DeviceRole.sender, DeviceRole.receiver}));
    });

    test('an acknowledgement that never gets through still leaves this device paired', () async {
      final (join, secrets) = await joined();
      await ConfirmSenderPairing(backend, InMemoryCredentialsStore()).call(join.session, secrets);
      final store = InMemoryCredentialsStore();
      await FinishReceiverPairing(
        store,
        _FlakyAckBackend(backend, failures: 99),
        retryDelay: Duration.zero,
      ).call(join, backend.sessions[join.session.code]!);
      expect(store.pairs, hasLength(1));
    });
  });

  group('a join interrupted by the app closing', () {
    late _MemoryPendingJoin pending;
    late InMemoryCredentialsStore store;
    ResumeReceiverPairing resume() =>
        ResumeReceiverPairing(pending, backend, FinishReceiverPairing(store, backend, retryDelay: Duration.zero));

    setUp(() {
      pending = _MemoryPendingJoin();
      store = InMemoryCredentialsStore();
    });

    test('finishes on the next start once the phone confirmed it', () async {
      final (join, secrets) = await joined();
      await pending.save(PendingJoin(code: join.session.code, sharedKey: join.secrets.sharedKey));
      await ConfirmSenderPairing(backend, InMemoryCredentialsStore()).call(join.session, secrets);

      final credentials = await resume().call();

      expect(credentials, isNotNull);
      expect(store.single?.sharedKey, join.secrets.sharedKey);
      expect(backend.ready[credentials!.pairId], contains(DeviceRole.receiver));
      expect(await pending.read(), isNull);
    });

    test('keeps waiting while the phone has not confirmed; forgets a cancelled one; offline, tries again', () async {
      final (join, _) = await joined();
      await pending.save(PendingJoin(code: join.session.code, sharedKey: join.secrets.sharedKey));

      expect(await resume().call(), isNull);
      expect(await pending.read(), isNotNull, reason: 'still joined: the phone may confirm');

      expect(
        await ResumeReceiverPairing(pending, _OfflineBackend(), FinishReceiverPairing(store, backend)).call(),
        isNull,
      );
      expect(await pending.read(), isNotNull, reason: 'offline proves nothing');

      await backend.cancelSession(join.session.code);
      expect(await resume().call(), isNull);
      expect(await pending.read(), isNull);
      expect(store.pairs, isEmpty);
    });
  });

  test('a code joined once cannot be joined again: a second scan or a second device is refused', () async {
    final pending = await StartPairingSession(backend, crypto, const FixedDeviceIdentity('Pixel 9')).call();
    final join = JoinPairingSession(backend, crypto, const FixedDeviceIdentity('MacBook'));
    final both = await Future.wait([
      join.call(code: pending.session.code).then<Object>((j) => j).catchError((Object e) => e),
      join.call(code: pending.session.code).then<Object>((j) => j).catchError((Object e) => e),
    ]);
    expect(both.whereType<JoinedPairing>(), hasLength(1));
    expect(both.whereType<PairingException>(), hasLength(1));
  });

  group('the phone\'s pairing screen', () {
    late ProviderContainer container;
    late InMemoryCredentialsStore store;
    late FakeNotificationBridge bridge;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      store = InMemoryCredentialsStore();
      bridge = FakeNotificationBridge();
      container = ProviderContainer(
        overrides: [
          pairingRepositoryProvider.overrideWithValue(backend),
          pairingCredentialsStoreProvider.overrideWithValue(store),
          archivedPairsStoreProvider.overrideWithValue(SecureArchivedPairsStore(MemorySecretStore())),
          notificationBridgeProvider.overrideWithValue(bridge),
          removeDoorbellProvider.overrideWithValue((_) async {}),
          historySizeProvider.overrideWithValue((_) async => (notifications: 0, replies: 0)),
          eraseHistoryProvider.overrideWithValue((_) async {}),
          deviceIdentityProvider.overrideWithValue(const FixedDeviceIdentity('Pixel 9')),
          pairingTimingsProvider.overrideWithValue((
            ackTimeout: const Duration(milliseconds: 200),
            poll: const Duration(milliseconds: 20),
          )),
        ],
      );
    });

    tearDown(() => container.dispose());

    /// Shows a code, lets a receiver join it, waits for the codes to compare.
    Future<SenderPairingController> toVerifying() async {
      final controller = container.read(senderPairingProvider.notifier);
      container.listen(senderPairingProvider, (_, _) {});
      final waiting = await _until<SenderPairingWaiting>(container);
      await JoinPairingSession(
        backend,
        crypto,
        const FixedDeviceIdentity('MacBook'),
      ).call(code: waiting.pending.session.code);
      await _until<SenderPairingVerifying>(container);
      return controller;
    }

    test('shares at once, and says done once the receiver acknowledged', () async {
      final controller = await toVerifying();
      unawaited(controller.confirm());
      await _until<SenderPairingFinishing>(container);
      // paired and sharing already: leaving this screen now never leaves a key that shares nothing
      final pairId = store.single!.pairId;
      expect(container.read(pairedDevicesProvider).single.pairId, pairId);
      expect(bridge.syncStarted, isTrue);

      await backend.markReady(pairId, DeviceRole.receiver);
      await _until<SenderPairingDone>(container);
    });

    test('no acknowledgement in time: asks; cancelling ends the pair and shows a new code', () async {
      final controller = await toVerifying();
      unawaited(controller.confirm());
      await _until<SenderPairingUnconfirmed>(container);
      final pairId = store.single!.pairId;

      await controller.cancelUnconfirmed();
      await _until<SenderPairingWaiting>(container);
      expect(store.pairs, isEmpty);
      expect(backend.pairs[pairId], isFalse);
      expect(container.read(pairedDevicesProvider), isEmpty);
    });

    test('no acknowledgement in time, but the person sees it paired there: carries on', () async {
      final controller = await toVerifying();
      unawaited(controller.confirm());
      await _until<SenderPairingUnconfirmed>(container);
      await controller.finishAnyway();
      expect(container.read(senderPairingProvider), isA<SenderPairingDone>());
      expect(container.read(pairedDevicesProvider), hasLength(1));
    });

    test('a join the live updates missed is still seen, by asking the server again', () async {
      backend.muteUpdates = true;
      final controller = await toVerifying();
      expect(controller, isNotNull);
    });
  });
}

Future<T> _until<T>(ProviderContainer container) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (container.read(senderPairingProvider) is! T) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Never reached $T; stuck at ${container.read(senderPairingProvider)}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return container.read(senderPairingProvider) as T;
}

final class _RefusingBackend extends _Delegating {
  _RefusingBackend(super.inner);

  @override
  Future<void> confirmSession(PairingSession session, String pairId) =>
      Future.error(const SyncException(AppError.pairingNotAvailable));
}

final class _SlowBackend extends _Delegating {
  _SlowBackend(super.inner);

  @override
  Future<void> confirmSession(PairingSession session, String pairId) => Completer<void>().future;
}

final class _FlakyAckBackend extends _Delegating {
  _FlakyAckBackend(super.inner, {required this.failures});

  final int failures;
  var attempts = 0;

  @override
  Future<void> markReady(String pairId, DeviceRole role) async {
    attempts++;
    if (attempts <= failures) throw const SyncException(AppError.offline);
    await inner.markReady(pairId, role);
  }
}

final class _OfflineBackend extends InMemoryPairingRepository {
  @override
  Future<PairingSession?> fetchSession(String code) => Future.error(const SyncException(AppError.offline));
}

/// The in-memory backend, with one call changed by each subclass.
class _Delegating extends InMemoryPairingRepository {
  _Delegating(this.inner);

  final InMemoryPairingRepository inner;

  @override
  String newPairId() => inner.newPairId();

  @override
  Future<void> confirmSession(PairingSession session, String pairId) => inner.confirmSession(session, pairId);

  @override
  Future<void> markReady(String pairId, DeviceRole role) => inner.markReady(pairId, role);
}

final class _MemoryPendingJoin implements PendingJoinStore {
  PendingJoin? _join;

  @override
  Future<PendingJoin?> read() async => _join;

  @override
  Future<void> save(PendingJoin join) async => _join = join;

  @override
  Future<void> clear() async => _join = null;
}
