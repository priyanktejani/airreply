import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/l10n/describe_error.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/background/arrival_alerts.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Receiver work that runs outside the UI: turning a mirrored-notification push into a local alert, and sending the
// reply typed into an alert. Both take the isolate's ProviderContainer so they reuse the app's wiring.

/// Shows the alert for a `type: notification` push, unless that app is muted on this device. [data] is the FCM
/// data map.
/// Whether a push that the server sent at [sentAt] reaches the device too late to alert: it waited while the device was
/// offline (FCM keeps them for an hour), and arrives with the others that waited. Those still land in the app, as
/// the open app's do (`ArrivalAlerts.window`); one late burst never rings for each of them.
bool isLatePush(DateTime? sentAt, DateTime now) => sentAt != null && now.difference(sentAt) > ArrivalAlerts.window;

Future<void> presentMirroredPush(ProviderContainer container, Map<String, dynamic> data, {DateTime? sentAt}) async {
  if (isLatePush(sentAt, DateTime.now())) {
    appLog('Push delivered late: kept without an alert', name: 'air_reply.push');
    return;
  }
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
  // a push can start this isolate cold: the alert's buttons follow the language chosen in Settings
  chosenLocale ??= await AppLanguageStore(container.read(sharedPreferencesProvider)).read();
  await container
      .read(mirroredAlertsProvider)
      .show(
        notification,
        pairId: pair.pairId,
        deviceName: session.pairs.length > 1 ? pair.peerName : null,
        showContent: preferences.alertShowsContent,
        style: preferences.alertStyle,
      );
}

/// Sends the reply typed into a mirrored alert, to the pair the alert came from. It is saved here first and shows in
/// the conversation as waiting, then as sent or failed once the phone reports back. When it cannot even be queued
/// (the device was removed, the notification can no longer be answered), an alert says so and why: a reply typed
/// into a notification never disappears without a word.
Future<void> sendAlertReply(ProviderContainer container, AlertReply reply) async {
  try {
    final session = await container.read(deviceSessionProvider.future);
    if (session.pair(reply.pairId) == null) throw const NotPairedException();
    await container.read(sendReplyProvider(reply.pairId)).call(reply.notification, reply.text);
    appLog('Reply from alert queued for ${reply.pairId}', name: 'air_reply.alerts');
    // answered: the alert leaves the panel (else it keeps a spinner, or the old message, there)
    try {
      await container.read(mirroredAlertsProvider).dismiss([reply.notification.id]);
    } on Object catch (e) {
      appLog('Answered alert not taken down: $e', name: 'air_reply.alerts');
    }
  } on Object catch (e, st) {
    appLog('Reply from alert not sent', error: e, stackTrace: st, name: 'air_reply.alerts');
    try {
      await container.read(mirroredAlertsProvider).showReplyFailed(reply, appL10n().describe(e));
    } on Object {
      // alerts unavailable: the log is all there is
    }
  }
}
