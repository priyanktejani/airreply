import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 24, 9);
  final live = SyncState(SyncHealth.live, lastSyncedAt: t0);
  const sharing = SyncStatus(enabled: true, running: true, listenerConnected: true);

  group('sync state', () {
    test('connecting until the server first answers, then live', () {
      final cached = SyncState.connecting.next(fromServer: false, now: t0);
      expect(cached.health, SyncHealth.connecting);
      expect(cached.lastSyncedAt, isNull);

      final up = cached.next(fromServer: true, now: t0);
      expect(up.health, SyncHealth.live);
      expect(up.lastSyncedAt, t0);
    });

    test('going offline remembers when the connection dropped', () {
      final dropped = live.next(fromServer: false, now: t0.add(const Duration(minutes: 5)));
      expect(dropped.health, SyncHealth.offline);
      expect(dropped.lastSyncedAt, t0.add(const Duration(minutes: 5)));

      // Further cache-only updates keep that moment.
      final still = dropped.next(fromServer: false, now: t0.add(const Duration(hours: 1)));
      expect(still.health, SyncHealth.offline);
      expect(still.lastSyncedAt, t0.add(const Duration(minutes: 5)));
    });
  });

  group('a receiver sees its phone', () {
    test('connected only once the server confirmed it', () {
      expect(phoneStatus(null).state, DeviceState.connecting);
      expect(phoneStatus(SyncState.connecting).state, DeviceState.connecting);
      expect(phoneStatus(live).state, DeviceState.connected);
      expect(phoneStatus(live).lastSyncedAt, t0);
    });

    test('offline, with a retry', () {
      final status = phoneStatus(SyncState(SyncHealth.offline, lastSyncedAt: t0));
      expect(status.state, DeviceState.disconnected);
      expect(status.fix, DeviceFix.retrySync);
      expect(status.label, 'Offline');
    });
  });

  group('a sender sees each receiver', () {
    test('missing notification access comes first', () {
      final status = receiverStatus(sharing: sharing, accessGranted: false, sync: live);
      expect(status.state, DeviceState.permissionRequired);
      expect(status.fix, DeviceFix.grantNotificationAccess);
    });

    test('paused sharing', () {
      final status = receiverStatus(sharing: SyncStatus.off, accessGranted: true, sync: live);
      expect(status.state, DeviceState.disconnected);
      expect(status.fix, DeviceFix.resumeSharing);
    });

    test('a listener Android unbound', () {
      final status = receiverStatus(
        sharing: const SyncStatus(enabled: true, running: true, listenerConnected: false),
        accessGranted: true,
        sync: live,
      );
      expect(status.label, 'Not receiving');
      expect(status.fix, DeviceFix.reconnectListener);
    });

    test('otherwise the server connection decides', () {
      expect(receiverStatus(sharing: sharing, accessGranted: true, sync: live).state, DeviceState.connected);
      expect(receiverStatus(sharing: sharing, accessGranted: true, sync: null).state, DeviceState.connecting);
      expect(
        receiverStatus(
          sharing: sharing,
          accessGranted: true,
          sync: SyncState(SyncHealth.offline, lastSyncedAt: t0),
        ).fix,
        DeviceFix.retrySync,
      );
    });
  });
}
