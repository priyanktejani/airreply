import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether this platform has a notification settings page the app can open: Android, iPhone and iPad, Mac and
/// Windows. Linux desktops and browsers each keep theirs differently.
bool get canOpenSystemNotificationSettings =>
    AppPlatform.isAndroid ||
    (!AppPlatform.isDemo && (AppPlatform.isIOS || AppPlatform.isMacOS || AppPlatform.isWindows));

/// This app's notification settings in the system: where pop-up, sound, vibration and lock screen are chosen.
Future<void> openSystemNotificationSettings(NotificationBridge bridge) async {
  if (AppPlatform.isAndroid) return bridge.openAppNotificationSettings();
  final uri = switch (AppPlatform.isIOS) {
    // the app's page in Settings, which lists its Notifications
    true => Uri.parse('app-settings:'),
    false when AppPlatform.isMacOS => Uri.parse('x-apple.systempreferences:com.apple.Notifications-Settings.extension'),
    false when AppPlatform.isWindows => Uri.parse('ms-settings:notifications'),
    _ => null,
  };
  if (uri == null) return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  // macOS 12 and older name the pane differently
  if (!opened && AppPlatform.isMacOS) {
    await launchUrl(
      Uri.parse('x-apple.systempreferences:com.apple.preference.notifications'),
      mode: LaunchMode.externalApplication,
    );
  }
}
