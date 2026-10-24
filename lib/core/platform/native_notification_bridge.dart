import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:flutter/services.dart';

/// Everything the app asks of the Android notification layer. Features depend on this interface only, so the
/// screens and use cases run (and are tested) without a device.
abstract interface class NotificationBridge {
  /// Android only: the receiver role (and iOS) never touches the native layer.
  bool get isSupported;

  Future<bool> isNotificationAccessGranted();

  /// Opens the system "Notification access" screen (`Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`).
  Future<void> openNotificationAccessSettings();

  Future<void> openBatteryOptimizationSettings();

  /// OEM "Autostart" screen (or the app's settings page on phones without one).
  Future<void> openAutostartSettings();

  Future<BackgroundRestrictions> backgroundRestrictions();

  /// Asks Android to bind the notification listener again when access is granted but nothing is listening (what
  /// happens on Xiaomi and similar phones after the app's process was killed without Autostart).
  Future<void> requestListenerRebind();

  Future<List<InstalledApp>> installedApps();

  /// [packageName]'s launcher icon as a small PNG, or null when the app is not visible to AirReply.
  Future<Uint8List?> appIcon(String packageName);

  Future<AppFilter> appFilter();

  Future<void> setAppFilter(AppFilter filter);

  /// Starts the foreground service and the headless sync engine, and keeps them running across reboots.
  Future<void> startSync();

  Future<void> stopSync();

  /// Restarts the sync engine if sharing is on, so it picks up added or removed pairs.
  Future<void> reloadSync();

  Future<SyncStatus> syncStatus();

  /// Fires the cached `RemoteInput` action of the notification [notificationKey] with [text].
  Future<ReplyDispatchResult> sendReply({required String notificationKey, required String text});

  /// Live listener events, only while a Flutter UI is attached.
  Stream<NativeEvent> events();
}

/// [NotificationBridge] over `com.airreply/methods` and `com.airreply/events`.
final class MethodChannelNotificationBridge implements NotificationBridge {
  MethodChannelNotificationBridge({
    this._methods = const MethodChannel(methodsChannel),
    this._events = const EventChannel(eventsChannel),
  });

  static const methodsChannel = 'com.airreply/methods';
  static const eventsChannel = 'com.airreply/events';

  final MethodChannel _methods;
  final EventChannel _events;

  Stream<NativeEvent>? _eventStream;

  @override
  bool get isSupported => AppPlatform.isAndroid;

  @override
  Future<bool> isNotificationAccessGranted() async =>
      isSupported && (await _invoke<bool>('isNotificationAccessGranted') ?? false);

  @override
  Future<void> openNotificationAccessSettings() => _invoke<void>('openNotificationAccessSettings');

  @override
  Future<void> openBatteryOptimizationSettings() => _invoke<void>('openBatteryOptimizationSettings');

  @override
  Future<void> openAutostartSettings() => _invoke<void>('openAutostartSettings');

  @override
  Future<BackgroundRestrictions> backgroundRestrictions() async {
    if (!isSupported) return BackgroundRestrictions.none;
    final map = await _invoke<Map<Object?, Object?>>('getBackgroundRestrictions');
    return map == null ? BackgroundRestrictions.none : BackgroundRestrictions.fromMap(map);
  }

  @override
  Future<void> requestListenerRebind() => _invoke<void>('requestListenerRebind');

  @override
  Future<List<InstalledApp>> installedApps() async {
    final apps = await _invoke<List<Object?>>('getInstalledApps') ?? const [];
    return [for (final app in apps.whereType<Map<Object?, Object?>>()) InstalledApp.fromMap(app)];
  }

  @override
  Future<Uint8List?> appIcon(String packageName) => _invoke<Uint8List>('getAppIcon', {'packageName': packageName});

  @override
  Future<AppFilter> appFilter() async {
    final map = await _invoke<Map<Object?, Object?>>('getAppFilter');
    return map == null ? AppFilter.everything : AppFilter.fromMap(map);
  }

  @override
  Future<void> setAppFilter(AppFilter filter) => _invoke<void>('setAppFilter', filter.toMap());

  @override
  Future<void> startSync() => _invoke<void>('startSync');

  @override
  Future<void> stopSync() => _invoke<void>('stopSync');

  @override
  Future<void> reloadSync() => _invoke<void>('reloadSync');

  @override
  Future<SyncStatus> syncStatus() async {
    if (!isSupported) return SyncStatus.off;
    final map = await _invoke<Map<Object?, Object?>>('getSyncStatus');
    return map == null ? SyncStatus.off : SyncStatus.fromMap(map);
  }

  @override
  Future<ReplyDispatchResult> sendReply({required String notificationKey, required String text}) async =>
      ReplyDispatchResult.parse(await _invoke<String>('sendReply', {'key': notificationKey, 'text': text}));

  @override
  Stream<NativeEvent> events() {
    if (!isSupported) return const Stream.empty();
    return _eventStream ??= _events
        .receiveBroadcastStream()
        .map((e) => NativeEvent.fromMap(e as Map<Object?, Object?>))
        .where((e) => e != null)
        .cast<NativeEvent>();
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!isSupported) throw const NativeBridgeException('Sharing notifications is only available on Android.');
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw NativeBridgeException(e.message ?? 'The Android notification service failed.', cause: e);
    } on MissingPluginException catch (e) {
      throw NativeBridgeException('The Android notification service is not available.', cause: e);
    }
  }
}
