import 'package:air_reply/core/platform/app_platform.dart';
import 'package:flutter/services.dart';

/// The app's icon on the home screen, as people choose it (Settings → Appearance → App icon).
enum LauncherIcon { light, dark }

/// Switches the app's own icon where the system lets an app do it: Android (a launcher activity-alias per icon,
/// `AppIcons.kt`) and iOS (an alternate app icon, `AppDelegate.swift`; iOS confirms the change itself). Elsewhere
/// there is one icon.
class LauncherIcons {
  LauncherIcons({
    MethodChannel android = const MethodChannel('com.airreply/methods'),
    MethodChannel apple = const MethodChannel('com.airreply/launcher_icon'),
  }) : _channel = AppPlatform.isIOS ? apple : android;

  final MethodChannel _channel;

  static bool get isSupported => AppPlatform.isAndroid || AppPlatform.isIOS;

  /// The icon showing now, as the system has it.
  Future<LauncherIcon> current() async =>
      await _channel.invokeMethod<String>('getLauncherIcon') == 'dark' ? LauncherIcon.dark : LauncherIcon.light;

  Future<void> set(LauncherIcon icon) => _channel.invokeMethod<void>('setLauncherIcon', {'name': icon.name});
}
