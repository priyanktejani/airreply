import 'package:air_reply/core/platform/app_platform.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Permission to *post* notifications (Android 13+ `POST_NOTIFICATIONS`, Apple alerts, browser notifications). The
/// sender needs it for the foreground-service status notification, receivers for mirrored alerts. Windows and Linux
/// have no such permission.
abstract interface class NotificationPermission {
  Future<bool> isGranted();

  Future<bool> request();
}

final class LocalNotificationsPermission implements NotificationPermission {
  LocalNotificationsPermission(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  T? _impl<T extends FlutterLocalNotificationsPlatform>() => _plugin.resolvePlatformSpecificImplementation<T>();

  @override
  Future<bool> isGranted() async {
    if (AppPlatform.isWeb) {
      return _impl<WebFlutterLocalNotificationsPlugin>()?.permissionStatus == WebNotificationPermission.granted;
    }
    if (AppPlatform.isAndroid) {
      return await _impl<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
    }
    if (AppPlatform.isIOS) {
      return (await _impl<IOSFlutterLocalNotificationsPlugin>()?.checkPermissions())?.isEnabled ?? false;
    }
    if (AppPlatform.isMacOS) {
      return (await _impl<MacOSFlutterLocalNotificationsPlugin>()?.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<bool> request() async {
    if (AppPlatform.isWeb) {
      return await _impl<WebFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
    }
    if (AppPlatform.isAndroid) {
      return await _impl<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
    }
    if (AppPlatform.isIOS) {
      return await _impl<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (AppPlatform.isMacOS) {
      return await _impl<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }
}
