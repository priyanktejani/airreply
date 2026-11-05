import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';

/// How one kind of mirrored notification alerts this device.
enum AlertMode {
  /// On screen over what is open, with sound: for what needs an answer now.
  popUp,

  /// In the notification list with sound, without covering the screen.
  normal,

  /// In the notification list only: no sound, no vibration, no pop-up.
  silent,

  /// No alert: it still arrives in the inbox.
  off;

  static AlertMode parse(Object? name, AlertMode fallback) =>
      values.where((m) => m.name == name).firstOrNull ?? fallback;
}

/// What a locked screen shows of an alert (Android; elsewhere the system's own setting decides).
enum LockScreenAlerts {
  /// The whole alert.
  show,

  /// The app and the device, not the message.
  hideContent,

  /// Nothing until the phone is unlocked.
  hide;

  static LockScreenAlerts parse(Object? name) => values.where((v) => v.name == name).firstOrNull ?? hideContent;
}

/// The person's choices for this device's alerts, for messages (chats that can be answered) and other notifications
/// apart: a message from a friend can pop up while a delivery update arrives quietly.
final class AlertStyle {
  const AlertStyle({
    this.messages = AlertMode.popUp,
    this.others = AlertMode.normal,
    this.sound = true,
    this.vibration = true,
    this.lockScreen = LockScreenAlerts.hideContent,
  });

  factory AlertStyle.fromJson(Map<String, Object?> json) => AlertStyle(
    messages: AlertMode.parse(json['messages'], AlertMode.popUp),
    others: AlertMode.parse(json['others'], AlertMode.normal),
    sound: json['sound'] != false,
    vibration: json['vibration'] != false,
    lockScreen: LockScreenAlerts.parse(json['lockScreen']),
  );

  final AlertMode messages;
  final AlertMode others;
  final bool sound;
  final bool vibration;
  final LockScreenAlerts lockScreen;

  /// The mode for [content]: a message when the phone said so, or, from phones that did not say, when it names a
  /// conversation or a sender.
  AlertMode modeFor(NotificationContent content) {
    final message =
        content.isMessage ?? (content.conversationId != null || content.sender != null || content.isGroupConversation);
    return message ? messages : others;
  }

  /// Whether alerts of [mode] make a sound / vibrate.
  bool soundFor(AlertMode mode) => sound && (mode == AlertMode.popUp || mode == AlertMode.normal);
  bool vibrationFor(AlertMode mode) => vibration && (mode == AlertMode.popUp || mode == AlertMode.normal);

  AlertStyle copyWith({
    AlertMode? messages,
    AlertMode? others,
    bool? sound,
    bool? vibration,
    LockScreenAlerts? lockScreen,
  }) => AlertStyle(
    messages: messages ?? this.messages,
    others: others ?? this.others,
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
    lockScreen: lockScreen ?? this.lockScreen,
  );

  Map<String, Object?> toJson() => {
    'messages': messages.name,
    'others': others.name,
    'sound': sound,
    'vibration': vibration,
    'lockScreen': lockScreen.name,
  };

  @override
  bool operator ==(Object other) => other is AlertStyle && _key == other._key;

  @override
  int get hashCode => _key.hashCode;

  String get _key => '$messages|$others|$sound|$vibration|$lockScreen';
}
