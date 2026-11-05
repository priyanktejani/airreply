import 'dart:convert';

import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
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
  static const _statusChannelId = 'mirrored_status';
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

  /// Raises the alert, as [style] says for its kind (a message or another notification): popping up, in the list,
  /// silently, or not at all. With [showContent] false (Settings → "Show message text in alerts"), the alert names only
  /// the app, so nothing private appears on a lock screen or a shared display. The user's own messages (a reply's
  /// copy, or words typed on the phone) raise no alert: they still arrive in the Notifications tab.
  Future<void> show(
    MirroredNotification notification, {
    required String pairId,
    String? deviceName,
    bool showContent = true,
    AlertStyle style = const AlertStyle(),
  }) {
    final content = notification.content;
    if (isTitledAsUser(content)) return Future.value();
    final mode = style.modeFor(content);
    if (mode == AlertMode.off) return Future.value();
    final l10n = appL10n();
    final canReply = notification.acceptsReplies;
    final payload = _payload(pairId, notification, canReply: canReply);
    final source = deviceName == null ? content.appName : '${content.appName} · $deviceName';
    final title = !showContent || content.title.isEmpty ? content.appName : content.title;
    final body = showContent ? content.text : l10n.alertNewNotification;
    final sound = style.soundFor(mode);
    final apple = DarwinNotificationDetails(
      subtitle: source,
      threadIdentifier: content.packageName,
      categoryIdentifier: canReply ? _appleReplyCategory : null,
      presentAlert: mode != AlertMode.silent,
      presentBanner: mode != AlertMode.silent,
      presentList: true,
      presentSound: sound,
      // a silent alert waits in the list without lighting the screen
      interruptionLevel: mode == AlertMode.silent ? InterruptionLevel.passive : InterruptionLevel.active,
    );

    return _plugin.show(
      id: alertId(notification.id),
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelFor(mode, style),
          _channelName(l10n, mode),
          channelDescription: l10n.alertChannelDescription,
          // the app's accent on the status-bar icon and app name, as on the launcher icon
          color: AppPalette.light.accent,
          importance: switch (mode) {
            AlertMode.popUp => Importance.high,
            AlertMode.normal => Importance.defaultImportance,
            _ => Importance.low,
          },
          priority: switch (mode) {
            AlertMode.popUp => Priority.high,
            AlertMode.normal => Priority.defaultPriority,
            _ => Priority.low,
          },
          playSound: sound,
          enableVibration: style.vibrationFor(mode),
          silent: mode == AlertMode.silent,
          // The running app and a push can both raise the same notification: alert once.
          onlyAlertOnce: true,
          category: AndroidNotificationCategory.message,
          subText: source,
          groupKey: content.packageName,
          styleInformation: BigTextStyleInformation(body),
          visibility: switch (style.lockScreen) {
            LockScreenAlerts.hide => NotificationVisibility.secret,
            LockScreenAlerts.show => NotificationVisibility.public,
            LockScreenAlerts.hideContent => NotificationVisibility.private,
          },
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
          audio: sound ? null : WindowsNotificationAudio.silent(),
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
          urgency: mode == AlertMode.silent ? LinuxNotificationUrgency.low : LinuxNotificationUrgency.normal,
          suppressSound: !sound,
        ),
        web: const WebNotificationDetails(),
      ),
    );
  }

  /// Tells the person a reply typed into an alert did not go out, and why ([reason], in their language); a tap opens
  /// the notification, to answer it again from the app.
  Future<void> showReplyFailed(AlertReply reply, String reason) {
    final l10n = appL10n();
    final payload = _payload(reply.pairId, reply.notification, canReply: false);
    final title = l10n.alertReplyNotSent(
      reply.notification.content.title.isEmpty ? reply.notification.content.appName : reply.notification.content.title,
    );
    const apple = DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentList: true);
    return _plugin.show(
      id: 'failed/${reply.notification.id}'.hashCode & 0x7fffffff,
      title: title,
      body: reason,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _statusChannelId,
          l10n.alertStatusChannelName,
          channelDescription: l10n.alertStatusChannelDescription,
          color: AppPalette.light.accent,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.error,
          styleInformation: BigTextStyleInformation(reason),
        ),
        iOS: apple,
        macOS: apple,
        windows: const WindowsNotificationDetails(),
        linux: LinuxNotificationDetails(defaultActionName: l10n.alertOpenApp),
        web: const WebNotificationDetails(),
      ),
    );
  }

  /// Takes every alert off the screen and, on Android, every alert channel out of the system's settings: Settings →
  /// Erase everything.
  Future<void> clearAll() async {
    await _plugin.cancelAll();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final id in {...allChannelIds, _statusChannelId}) {
      await android.deleteNotificationChannel(channelId: id);
    }
  }

  /// The system's id for the alert of the mirrored notification [notificationId]: the same in every isolate and on
  /// every start, so the app can take down an alert a push handler raised.
  static int alertId(String notificationId) => notificationId.hashCode & 0x7fffffff;

  /// Takes the alerts of these mirrored notifications out of the system's notification panel: they have been read
  /// (opened, marked, hidden or answered) in AirReply. Alerts no longer showing are ignored.
  Future<void> dismiss(Iterable<String> notificationIds) async {
    for (final id in notificationIds.toSet()) {
      await _plugin.cancel(id: alertId(id));
    }
  }

  /// Takes every mirrored alert out of the panel ("Mark all as read"). On Android only those of the alert channels: the
  /// sharing service's status notification and a "Reply not sent" stay.
  Future<void> dismissAll() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return _plugin.cancelAll();
    for (final active in await android.getActiveNotifications()) {
      final id = active.id;
      if (id != null && (active.channelId?.startsWith('mirrored') ?? false)) {
        await _plugin.cancel(id: id, tag: active.tag);
      }
    }
  }

  /// Creates the Android channel [show] uses for [mode] with [style], before any alert needs it, so its system
  /// settings can be checked and opened. A channel that exists keeps the person's (or the phone's) settings.
  Future<void> ensureChannel(AlertMode mode, AlertStyle style) async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final l10n = appL10n();
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        channelFor(mode, style),
        _channelName(l10n, mode),
        description: l10n.alertChannelDescription,
        importance: switch (mode) {
          AlertMode.popUp => Importance.high,
          AlertMode.normal => Importance.defaultImportance,
          _ => Importance.low,
        },
        playSound: style.soundFor(mode),
        enableVibration: style.vibrationFor(mode),
      ),
    );
  }

  /// The Android channel for alerts of [mode] with [style]'s sound and vibration. A channel's importance, sound and
  /// vibration are fixed once it exists, so each combination is a channel of its own.
  static String channelFor(AlertMode mode, AlertStyle style) => switch (mode) {
    AlertMode.popUp || AlertMode.normal =>
      'mirrored_${mode.name}${style.soundFor(mode) ? '_sound' : ''}${style.vibrationFor(mode) ? '_vibrate' : ''}',
    _ => 'mirrored_silent',
  };

  /// Removes the alert channels [style] no longer uses (and the one channel of earlier versions), so the system's
  /// notification settings list only what this device can still raise. Android only; nothing elsewhere. The channels
  /// are a known set, deleted by id: listing them reads fields some devices leave empty.
  Future<void> tidyChannels(AlertStyle style) async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final keep = {channelFor(style.messages, style), channelFor(style.others, style), _statusChannelId};
    for (final id in allChannelIds) {
      if (!keep.contains(id)) await android.deleteNotificationChannel(channelId: id);
    }
  }

  /// Every alert channel this app has ever created.
  static final allChannelIds = {
    'mirrored',
    'mirrored_silent',
    for (final mode in [AlertMode.popUp, AlertMode.normal])
      for (final sound in [true, false])
        for (final vibration in [true, false]) channelFor(mode, AlertStyle(sound: sound, vibration: vibration)),
  };

  static String _channelName(AppLocalizations l10n, AlertMode mode) => switch (mode) {
    AlertMode.popUp => l10n.alertChannelPopUp,
    AlertMode.normal => l10n.alertChannelName,
    _ => l10n.alertChannelSilent,
  };

  // The icon stays out of the payload: the alert never shows it, and payloads should stay small.
  static String _payload(String pairId, MirroredNotification notification, {required bool canReply}) => jsonEncode({
    'pairId': pairId,
    'id': notification.id,
    'canReply': canReply,
    'c': notification.content.withIcon(null).toJson(),
  });

  /// The reply typed into an alert that started the app (macOS and iOS start it to hand the reply over), so it is sent
  /// rather than lost.
  Future<AlertReply?> launchReply() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    return details?.didNotificationLaunchApp == true && response != null ? replyFrom(response) : null;
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
