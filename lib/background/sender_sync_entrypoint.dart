import 'dart:async';

import 'package:air_reply/background/background_bootstrap.dart';
import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/sender/data/icon_delivery.dart';
import 'package:air_reply/features/sender/sender_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';

/// Body of the headless engine started by the Android `SyncForegroundService` (entry point `backgroundMain` in
/// main.dart). Lives as long as the service does; native restarts it when pairs are added or removed.
Future<void> runSenderSync() async {
  // Built directly, not from the container: it must work even when Firebase fails to start.
  final NotificationBridge bridge = MethodChannelNotificationBridge();
  try {
    final container = await bootstrapBackgroundIsolate();
    final session = await container.read(deviceSessionProvider.future);
    if (!session.isPaired || session.role != DeviceRole.sender) {
      appLog('Not paired as a sender; stopping sync.', name: 'air_reply.sync');
      container.dispose();
      await bridge.stopSync();
      return;
    }

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
