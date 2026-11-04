import 'dart:convert';

import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The notification an alert stands for, decoded from its payload: where tapping it should lead.
typedef AlertTarget = ({String pairId, String notificationId});

/// The reply typed into a mirrored alert, decoded from the notification's payload.
final class AlertReply {
  const AlertReply({required this.pairId, required this.notification, required this.text});

  final String pairId;
  final MirroredNotification notification;
  final String text;
}

/// Shows mirrored notifications as system alerts on the receiver, with a "Reply" text action where the platform has
/// one: Android, iOS, macOS (notification text actions) and Windows (toast text input). Linux and web alerts open the
/// app instead.
final class MirroredAlerts {
  MirroredAlerts(this._plugin);

  static const replyActionId = 'reply';
  static const _channelId = 'mirrored';
  static const _appleReplyCategory = 'mirrored_reply';

  /// Windows toast buttons report their own `arguments` instead of the notification payload, so the reply button
  /// carries the payload itself, behind this prefix.
  static const _windowsReplyPrefix = 'reply|';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize({
    DidReceiveNotificationResponseCallback? onResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) {
    final l10n = appL10n();
    final apple = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _appleReplyCategory,
          actions: [
            DarwinNotificationAction.text(
              replyActionId,
              l10n.alertReply,
              buttonTitle: l10n.actionSend,
              placeholder: l10n.alertReplyHint,
            ),
          ],
        ),
      ],
    );
    return _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_stat_air_reply'),
        iOS: apple,
        macOS: apple,
        linux: LinuxInitializationSettings(defaultActionName: l10n.alertOpenApp),
        windows: WindowsInitializationSettings(
          appName: 'AirReply',
          appUserModelId: 'com.airreply.AirReply',
          guid: '7c3f9a52-4d1e-4b8a-9f2c-1e6d5a0b3c84',
        ),
        web: const WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
  }

  /// Raises the alert. With [showContent] false (Settings → "Show message text in alerts"), the alert names only the
  /// app, so nothing private appears on a lock screen or a shared display. The user's own messages (a reply's copy,
  /// or words typed on the phone) raise no alert: they still arrive in the Notifications tab.
  Future<void> show(
    MirroredNotification notification, {
    required String pairId,
    String? deviceName,
    bool showContent = true,
  }) {
    final content = notification.content;
    if (isTitledAsUser(content)) return Future.value();
    final l10n = appL10n();
    final canReply = notification.acceptsReplies;
    // The icon stays out of the payload: the alert never shows it, and payloads should stay small.
    final payload = jsonEncode({
      'pairId': pairId,
      'id': notification.id,
      'canReply': canReply,
      'c': content.withIcon(null).toJson(),
    });
    final source = deviceName == null ? content.appName : '${content.appName} · $deviceName';
    final title = !showContent || content.title.isEmpty ? content.appName : content.title;
    final body = showContent ? content.text : l10n.alertNewNotification;
    final apple = DarwinNotificationDetails(
      subtitle: source,
      threadIdentifier: content.packageName,
      categoryIdentifier: canReply ? _appleReplyCategory : null,
    );

    return _plugin.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          l10n.alertChannelName,
          channelDescription: l10n.alertChannelDescription,
          // the app's accent on the status-bar icon and app name, as on the launcher icon
          color: AppPalette.light.accent,
          importance: Importance.high,
          priority: Priority.high,
          // The running app and a push can both raise the same notification: alert once.
          onlyAlertOnce: true,
          category: AndroidNotificationCategory.message,
          subText: source,
          groupKey: content.packageName,
          styleInformation: BigTextStyleInformation(body),
          visibility: showContent ? NotificationVisibility.private : NotificationVisibility.secret,
          actions: [
            if (canReply)
              AndroidNotificationAction(
                replyActionId,
                l10n.alertReply,
                inputs: [AndroidNotificationActionInput(label: l10n.alertReplyHint)],
                semanticAction: SemanticAction.reply,
              ),
          ],
        ),
        iOS: apple,
        macOS: apple,
        windows: WindowsNotificationDetails(
          subtitle: source,
          inputs: [if (canReply) WindowsTextInput(id: replyActionId, placeHolderContent: l10n.alertReplyHint)],
          actions: [
            if (canReply)
              WindowsAction(
                content: l10n.actionSend,
                arguments: '$_windowsReplyPrefix$payload',
                inputId: replyActionId,
              ),
          ],
        ),
        linux: LinuxNotificationDetails(
          category: LinuxNotificationCategory.imReceived,
          defaultActionName: l10n.alertOpenApp,
        ),
        web: const WebNotificationDetails(),
      ),
    );
  }

  /// The alert that launched the app, when it was started by tapping one.
  Future<AlertTarget?> launchTarget() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    return details?.didNotificationLaunchApp == true && response != null ? targetFrom(response) : null;
  }

  /// Which notification a tap on an alert refers to; null for replies and unreadable payloads.
  static AlertTarget? targetFrom(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.startsWith(_windowsReplyPrefix) || response.actionId == replyActionId) return null;
    try {
      final json = (jsonDecode(payload) as Map).cast<String, Object?>();
      return (pairId: json['pairId']! as String, notificationId: json['id']! as String);
    } on Object {
      return null;
    }
  }

  /// The reply typed into an alert, or null when [response] was a plain tap (or carried no text).
  static AlertReply? replyFrom(NotificationResponse response) {
    var payload = response.payload;
    String? text;
    if (payload != null && payload.startsWith(_windowsReplyPrefix)) {
      payload = payload.substring(_windowsReplyPrefix.length);
      text = response.data[replyActionId] as String?;
    } else if (response.actionId == replyActionId) {
      text = response.input;
    }
    text = text?.trim();
    if (text == null || text.isEmpty || payload == null) return null;

    try {
      final json = (jsonDecode(payload) as Map).cast<String, Object?>();
      return AlertReply(
        pairId: json['pairId']! as String,
        text: text,
        notification: MirroredNotification(
          id: json['id']! as String,
          content: NotificationContent.fromJson((json['c']! as Map).cast<String, Object?>()),
          canReply: json['canReply'] == true,
          dismissedOnSender: false,
        ),
      );
    } on Object {
      return null;
    }
  }
}
