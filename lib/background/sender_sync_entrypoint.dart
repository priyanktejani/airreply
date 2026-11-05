import 'dart:async';

import 'package:air_reply/background/background_bootstrap.dart';
import 'package:air_reply/background/push_entrypoints.dart';
import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/notifications/background/arrival_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/sender/data/icon_delivery.dart';
import 'package:air_reply/features/sender/sender_providers.dart';
import 'package:air_reply/features/session/domain/device_session.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Body of the headless engine started by the Android `SyncForegroundService` (entry point `backgroundMain` in
/// main.dart): a phone's sharing, or a receiver's receiving while the app is closed. Lives as long as the service
/// does; native restarts it when pairs are added or removed.
Future<void> runSenderSync() async {
  // Built directly, not from the container: it must work even when Firebase fails to start.
  final NotificationBridge bridge = MethodChannelNotificationBridge();
  try {
    final container = await bootstrapBackgroundIsolate();
    final session = await container.read(deviceSessionProvider.future);
    if (!session.isPaired) {
      appLog('Not paired; stopping the background service.', name: 'air_reply.sync');
      container.dispose();
      await bridge.stopSync();
      return;
    }
    if (session.role == DeviceRole.receiver) return await _runReceiving(container, session, bridge);

    // Records of icons sent to devices that have since been removed: this engine restarts whenever a pair ends.
    await PreferencesIconDeliveryLog(
      container.read(sharedPreferencesProvider),
    ).keepOnly({for (final pair in session.pairs) pair.pairId});

    // A receiver ended its pair: forget that key here too (this also restarts or stops this engine).
    for (final pair in session.pairs) {
      container.listen(pairActiveProvider(pair.pairId), (_, next) {
        if (next.value == false) {
          unawaited(container.read(deviceSessionProvider.notifier).unpair(pair.pairId, notifyPeer: false));
        }
      });
    }

    await container.read(senderSyncRunnerProvider).start();
    appLog('Sender sync running for ${session.pairs.length} paired device(s)', name: 'air_reply.sync');
  } on Object catch (e, st) {
    appLog('Sender sync could not start', error: e, stackTrace: st, name: 'air_reply.sync');
    await bridge.stopSync();
  }
}

/// A device that shows notifications, kept receiving while AirReply is closed (Android): the same service, here
/// watching each phone's mailbox, keeping what arrives and raising its alerts, as the app does while it is open.
/// While the app's window is in front, the app raises them itself.
Future<void> _runReceiving(ProviderContainer container, DeviceSession session, NotificationBridge bridge) async {
  final alerts = container.read(mirroredAlertsProvider);
  await alerts.initialize(onBackgroundResponse: onAlertActionInBackground);
  final arrivals = ArrivalAlerts(alerts);
  final preferencesStore = container.read(appPreferencesStoreProvider);
  final many = session.pairs.length > 1;
  for (final pair in session.pairs) {
    // the phone ended the pair: forget it here too (this restarts or stops this engine)
    container.listen(pairActiveProvider(pair.pairId), (_, next) {
      if (next.value == false) {
        unawaited(container.read(deviceSessionProvider.notifier).unpair(pair.pairId, notifyPeer: false));
      }
    });
    container.listen(mirroredNotificationsProvider(pair.pairId), (_, next) async {
      final items = next.value;
      if (items == null) return;
      final fresh = arrivals.arrived(pair.pairId, items);
      if (fresh.isEmpty || await bridge.isAppVisible()) return;
      // read again each time: the person may have changed them in the app meanwhile
      final preferences = await preferencesStore.load();
      for (final n in fresh.where((n) => ArrivalAlerts.alertable(n, preferences))) {
        try {
          await arrivals.show(
            n,
            pairId: pair.pairId,
            preferences: preferences,
            deviceName: many ? pair.peerName : null,
          );
        } on Object catch (e) {
          appLog('Alert not shown: $e', name: 'air_reply.alerts');
        }
      }
    }, fireImmediately: true);
  }
  appLog('Receiving in the background from ${session.pairs.length} paired phone(s)', name: 'air_reply.sync');
}
