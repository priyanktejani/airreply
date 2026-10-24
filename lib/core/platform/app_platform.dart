import 'package:flutter/foundation.dart';

/// How a platform talks to the backend.
enum BackendTransport {
  /// FlutterFire: realtime listeners, offline cache, push. Android, iOS, macOS and web.
  firebaseSdk,

  /// Firebase REST APIs (Identity Toolkit + Firestore) with incremental polling. Windows and Linux: FlutterFire has no
  /// Linux support, and its Windows support is for development only.
  rest,
}

/// What this build can do, derived once from the target platform. Uses `defaultTargetPlatform` rather than
/// `dart:io`, so the same code compiles for the web.
abstract final class AppPlatform {
  static TargetPlatform get _target => defaultTargetPlatform;

  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && _target == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && _target == TargetPlatform.iOS;
  static bool get isMacOS => !kIsWeb && _target == TargetPlatform.macOS;
  static bool get isWindows => !kIsWeb && _target == TargetPlatform.windows;
  static bool get isLinux => !kIsWeb && _target == TargetPlatform.linux;
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// `--dart-define=AIRREPLY_DEMO=receiver|sender`: the real UI on sample data, no backend (see lib/demo).
  static const demo = String.fromEnvironment('AIRREPLY_DEMO');

  static bool get isDemo => demo.isNotEmpty;

  /// Only Android lets an app read other apps' notifications (NotificationListenerService). iOS, macOS, Windows,
  /// Linux and the web can only be receivers (except in the sender demo).
  static bool get canShareNotifications => isAndroid || demo == 'sender';

  /// Camera QR scanning (mobile_scanner): Android, iOS, macOS and web.
  static bool get canScanQr => isWeb || isAndroid || isIOS || isMacOS;

  /// A hardware keyboard is the main input: Enter sends, Shift+Enter breaks the line.
  static bool get prefersKeyboardShortcuts => isWeb || isDesktop;

  static BackendTransport get backend => isWindows || isLinux ? BackendTransport.rest : BackendTransport.firebaseSdk;

  /// Push (FCM) is used where the app can act on it in the background: waking the Android sender, alerting phones.
  /// Desktop and web raise their own alerts from the live feed while they run.
  static bool get usesPush => !isDemo && (isAndroid || isIOS);

  /// Stored on the pair for the backend, e.g. "android", "macos", "web".
  static String get name => isWeb ? 'web' : _target.name;
}
