import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/session/domain/device_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';

  /// Sender only: the notification-access disclosure, then the permission checklist.
  static const setup = '/setup';

  /// Pair a device: shows a code on senders, scans or types one on receivers.
  static const pair = '/pair';

  // The four tabs.
  static const home = '/home';
  static const notifications = '/notifications';
  static const devices = '/devices';
  static const settings = '/settings';

  static const tabs = [home, notifications, devices, settings];

  static const apps = '/settings/apps';
  static const diagnostics = '/settings/diagnostics';

  /// Every notification of one app. [source] is the pair id, or `*` for a sender's groups.
  static String appGroup(String source, String packageName) =>
      '$notifications/app/${Uri.encodeComponent(source)}/${Uri.encodeComponent(packageName)}';

  /// One conversation within an app, as a chat; [at] is a notification to scroll to and point out.
  static String thread(String source, String packageName, String key, {String? at}) =>
      '$notifications/thread/${Uri.encodeComponent(source)}/${Uri.encodeComponent(packageName)}/'
      '${Uri.encodeComponent(key)}${at == null ? '' : '?at=${Uri.encodeQueryComponent(at)}'}';

  static String notification(String pairId, String id) =>
      '$notifications/${Uri.encodeComponent(pairId)}/${Uri.encodeComponent(id)}';
}

/// Pure navigation policy: given the device session, which locations are reachable and where to land otherwise.
/// Kept free of widgets and of GoRouter so it can be unit tested.
String? resolveRedirect(AsyncValue<DeviceSession> session, String location) {
  final value = session.value;
  if (value == null) return location == AppRoutes.splash ? null : AppRoutes.splash;
  return isAllowed(value, location) ? null : landingFor(value);
}

/// Where a device in this state starts.
String landingFor(DeviceSession session) => switch ((session.role, session.isPaired)) {
  (null, _) => AppRoutes.welcome,
  (DeviceRole.sender, false) when !session.disclosureAccepted => AppRoutes.setup,
  (_, false) => AppRoutes.pair,
  (_, true) => AppRoutes.home,
};

bool isAllowed(DeviceSession session, String location) {
  if (location == landingFor(session)) return true;
  return switch ((session.role, session.isPaired)) {
    (null, _) => false,
    // An unpaired sender can go back to the checklist from pairing.
    (DeviceRole.sender, false) => location == AppRoutes.setup,
    (DeviceRole.receiver, false) => false,
    // Paired devices use the tabs, and can pair more devices.
    (final role, true) =>
      location == AppRoutes.pair || (role == DeviceRole.sender && location == AppRoutes.setup) || _inTabs(location),
  };
}

bool _inTabs(String location) => AppRoutes.tabs.any((tab) => location == tab || location.startsWith('$tab/'));
