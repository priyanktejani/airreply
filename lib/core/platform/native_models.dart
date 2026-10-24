import 'dart:typed_data';

/// A status-bar notification as the Android listener captured it.
final class CapturedNotification {
  const CapturedNotification({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
    required this.canReply,
    this.conversationTitle,
    this.isGroupConversation = false,
  });

  factory CapturedNotification.fromMap(Map<Object?, Object?> map) => CapturedNotification(
    key: map['key']! as String,
    packageName: map['packageName']! as String,
    appName: (map['appName'] as String?) ?? map['packageName']! as String,
    title: (map['title'] as String?) ?? '',
    text: (map['text'] as String?) ?? '',
    postedAt: DateTime.fromMillisecondsSinceEpoch((map['postedAt']! as num).toInt()),
    canReply: map['canReply'] == true,
    conversationTitle: map['conversationTitle'] as String?,
    isGroupConversation: map['isGroupConversation'] == true,
  );

  /// `StatusBarNotification.getKey()`: stable for one notification of one app, reused when the app updates it.
  final String key;
  final String packageName;
  final String appName;
  final String title;

  /// The most useful body text: the latest message of a conversation, else big text, else text.
  final String text;
  final DateTime postedAt;

  /// The notification carries a `RemoteInput` action, so it can be answered remotely.
  final bool canReply;
  final String? conversationTitle;
  final bool isGroupConversation;
}

/// A launchable app on the sender, for the "which apps to mirror" list.
final class InstalledApp {
  const InstalledApp({required this.packageName, required this.label, this.icon});

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    packageName: map['packageName']! as String,
    label: map['label']! as String,
    icon: map['icon'] as Uint8List?,
  );

  final String packageName;
  final String label;

  /// PNG bytes.
  final Uint8List? icon;
}

enum AppFilterMode { all, selected }

/// Which apps the listener mirrors. Stored natively so it applies while the Flutter UI is closed.
final class AppFilter {
  const AppFilter({required this.mode, this.packages = const {}});

  factory AppFilter.fromMap(Map<Object?, Object?> map) => AppFilter(
    mode: map['mode'] == AppFilterMode.selected.name ? AppFilterMode.selected : AppFilterMode.all,
    packages: {...?(map['packages'] as List<Object?>?)?.whereType<String>()},
  );

  static const everything = AppFilter(mode: AppFilterMode.all);

  final AppFilterMode mode;
  final Set<String> packages;

  bool allows(String packageName) => mode == AppFilterMode.all || packages.contains(packageName);

  AppFilter copyWith({AppFilterMode? mode, Set<String>? packages}) =>
      AppFilter(mode: mode ?? this.mode, packages: packages ?? this.packages);

  Map<String, Object?> toMap() => {'mode': mode.name, 'packages': packages.toList()};
}

/// Whether the sender's sync pipeline is switched on and actually running.
final class SyncStatus {
  const SyncStatus({required this.enabled, required this.running, required this.listenerConnected});

  factory SyncStatus.fromMap(Map<Object?, Object?> map) => SyncStatus(
    enabled: map['enabled'] == true,
    running: map['running'] == true,
    listenerConnected: map['listenerConnected'] == true,
  );

  static const off = SyncStatus(enabled: false, running: false, listenerConnected: false);

  final bool enabled;
  final bool running;
  final bool listenerConnected;
}

/// What can stop the sender from running in the background: phone makers' "Autostart" switches and Android's
/// battery optimisation.
final class BackgroundRestrictions {
  const BackgroundRestrictions({
    required this.vendor,
    required this.hasAutostartScreen,
    required this.ignoringBatteryOptimizations,
  });

  factory BackgroundRestrictions.fromMap(Map<Object?, Object?> map) => BackgroundRestrictions(
    vendor: (map['vendor'] as String?) ?? '',
    hasAutostartScreen: map['hasAutostartScreen'] == true,
    ignoringBatteryOptimizations: map['ignoringBatteryOptimizations'] == true,
  );

  static const none = BackgroundRestrictions(vendor: '', hasAutostartScreen: false, ignoringBatteryOptimizations: true);

  /// `Build.MANUFACTURER`, lower case: "xiaomi", "oppo", "samsung"...
  final String vendor;

  /// The phone has an OEM "Autostart" screen (Xiaomi, Oppo, Vivo, Huawei...). While autostart is off there, the
  /// system refuses to restart the notification listener.
  final bool hasAutostartScreen;
  final bool ignoringBatteryOptimizations;

  /// "Xiaomi", "Oppo"... for messages.
  String get vendorName => vendor.isEmpty ? 'this phone' : vendor[0].toUpperCase() + vendor.substring(1);
}

/// What happened when the sender tried to fire a cached `RemoteInput` action.
enum ReplyDispatchResult {
  sent,

  /// The notification is gone (dismissed, answered elsewhere, app killed it), so its action no longer exists.
  expired,
  failed;

  static ReplyDispatchResult parse(Object? value) =>
      ReplyDispatchResult.values.firstWhere((r) => r.name == value, orElse: () => ReplyDispatchResult.failed);
}

/// Live events the listener pushes to the Flutter UI while it is open.
sealed class NativeEvent {
  const NativeEvent();

  static NativeEvent? fromMap(Map<Object?, Object?> map) => switch (map['type']) {
    'posted' => NotificationPostedEvent(CapturedNotification.fromMap(map['notification']! as Map<Object?, Object?>)),
    'removed' => NotificationRemovedEvent(map['key']! as String),
    'syncState' => SyncStateEvent(SyncStatus.fromMap(map['status']! as Map<Object?, Object?>)),
    _ => null,
  };
}

final class NotificationPostedEvent extends NativeEvent {
  const NotificationPostedEvent(this.notification);
  final CapturedNotification notification;
}

final class NotificationRemovedEvent extends NativeEvent {
  const NotificationRemovedEvent(this.key);
  final String key;
}

final class SyncStateEvent extends NativeEvent {
  const SyncStateEvent(this.status);
  final SyncStatus status;
}
