import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Receiver work that runs outside the UI: turning a mirrored-notification push into a local alert, and sending the
// reply typed into an alert. Both take the isolate's ProviderContainer so they reuse the app's wiring.

/// Shows the alert for a `type: notification` push, unless that app is muted on this device. [data] is the FCM
/// data map.
Future<void> presentMirroredPush(ProviderContainer container, Map<String, dynamic> data) async {
  final session = await container.read(deviceSessionProvider.future);
  final pairId = data['pairId'] as String?;
  final pair = pairId == null ? null : session.pair(pairId);
  final id = data['id'] as String?;
  if (pair == null || pair.role != DeviceRole.receiver || id == null) return;

  final feed = container.read(notificationFeedProvider(pair.pairId));
  final payload = data['payload'] as String?;
  // Large payloads are left out of the push by the backend; read those from Firestore instead.
  final MirroredNotification? notification = payload == null
      ? await feed.fetchNotification(id)
      : await feed.decodePushed(id: id, payload: payload, canReply: data['canReply'] == 'true');
  if (notification == null) return;

  final preferences = await container.read(appPreferencesProvider.future);
  if (!preferences.alertsFor(notification.content.packageName)) return;
  await container
      .read(mirroredAlertsProvider)
      .show(
        notification,
        pairId: pair.pairId,
        deviceName: session.pairs.length > 1 ? pair.peerName : null,
        showContent: preferences.alertShowsContent,
      );
}

/// Sends the reply typed into a mirrored alert, to the pair the alert came from.
Future<void> sendAlertReply(ProviderContainer container, AlertReply reply) async {
  final session = await container.read(deviceSessionProvider.future);
  if (session.pair(reply.pairId) == null) return;
  await container.read(sendReplyProvider(reply.pairId)).call(reply.notification, reply.text);
}
