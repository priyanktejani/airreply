import 'dart:convert';
import 'dart:typed_data';

/// The private part of a mirrored notification: everything here travels encrypted end to end.
final class NotificationContent {
  const NotificationContent({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.conversationTitle,
    this.isGroupConversation = false,
    this.iconPng,
  });

  factory NotificationContent.fromJson(Map<String, Object?> json) => NotificationContent(
    key: json['k']! as String,
    packageName: json['p']! as String,
    appName: (json['a'] as String?) ?? json['p']! as String,
    title: (json['t'] as String?) ?? '',
    text: (json['x'] as String?) ?? '',
    postedAt: DateTime.fromMillisecondsSinceEpoch((json['at']! as num).toInt()),
    conversationTitle: json['ct'] as String?,
    isGroupConversation: json['g'] == true,
    iconPng: switch (json['ic']) {
      final String b64 => _decodeIcon(b64),
      _ => null,
    },
  );

  /// The sender's `StatusBarNotification` key; only the sender can act on it.
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final DateTime postedAt;
  final String? conversationTitle;
  final bool isGroupConversation;

  /// The source app's icon (small PNG). Sent with the first notification of an app to each device, then about once
  /// a week, so receivers can show real icons; absent otherwise.
  final Uint8List? iconPng;

  NotificationContent withIcon(Uint8List? icon) => NotificationContent(
    key: key,
    packageName: packageName,
    appName: appName,
    title: title,
    text: text,
    postedAt: postedAt,
    conversationTitle: conversationTitle,
    isGroupConversation: isGroupConversation,
    iconPng: icon,
  );

  static Uint8List? _decodeIcon(String b64) {
    try {
      return base64.decode(b64);
    } on FormatException {
      return null;
    }
  }

  /// Short keys keep the envelope (and the push payload that carries it) small.
  Map<String, Object?> toJson() => {
    'k': key,
    'p': packageName,
    'a': appName,
    't': title,
    'x': text,
    'at': postedAt.millisecondsSinceEpoch,
    if (conversationTitle != null) 'ct': conversationTitle,
    if (isGroupConversation) 'g': true,
    if (iconPng != null) 'ic': base64.encode(iconPng!),
  };
}
