import 'package:air_reply/background/background_bootstrap.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/sync_wake_port.dart';
import 'package:air_reply/features/notifications/background/alert_handlers.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Data pushes the backend sends (see functions/src/index.ts):
/// * `type: reply`        -> to the sender: a reply is waiting; wake the sync isolate so it fetches now.
/// * `type: notification` -> to the receiver: show the mirrored notification as a local alert.
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) async {
  switch (message.data['type']) {
    case 'reply':
      SyncWakePort.wake();
    case 'notification':
      final container = await bootstrapBackgroundIsolate();
      try {
        await container.read(mirroredAlertsProvider).initialize(onBackgroundResponse: onAlertActionInBackground);
        await presentMirroredPush(container, message.data, sentAt: message.sentTime);
      } on Object catch (e, st) {
        appLog('Could not show mirrored alert', error: e, stackTrace: st, name: 'air_reply.push');
      } finally {
        container.dispose();
      }
  }
}

/// "Reply" typed into a mirrored alert while the app is not running.
@pragma('vm:entry-point')
Future<void> onAlertActionInBackground(NotificationResponse response) async {
  final reply = MirroredAlerts.replyFrom(response);
  if (reply == null) return;
  final container = await bootstrapBackgroundIsolate();
  try {
    await sendAlertReply(container, reply);
  } on Object catch (e, st) {
    appLog('Could not send reply from alert', error: e, stackTrace: st, name: 'air_reply.push');
  } finally {
    container.dispose();
  }
}
