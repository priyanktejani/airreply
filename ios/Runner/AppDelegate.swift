import Flutter
import UIKit
import UserNotifications
// Needed for FlutterLocalNotificationsPlugin.setPluginRegistrantCallback (reply actions on mirrored alerts).
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Mirrored alerts are presented (and their "Reply" text action handled) by flutter_local_notifications.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Lets the background isolate that handles a typed reply use the app's plugins (Firebase, secure storage).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerLauncherIcon(engineBridge.pluginRegistry)
  }

  /// The app icon people choose (Settings → Appearance → App icon): "light" is the primary icon, "dark" the
  /// alternate AppIconDark (ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES). iOS confirms the change itself.
  private func registerLauncherIcon(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "AirReplyLauncherIcon") else { return }
    let channel = FlutterMethodChannel(name: "com.airreply/launcher_icon", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      let app = UIApplication.shared
      switch call.method {
      case "getLauncherIcon":
        result(app.alternateIconName == "AppIconDark" ? "dark" : "light")
      case "setLauncherIcon":
        guard app.supportsAlternateIcons else {
          result(FlutterError(code: "unsupported", message: "Alternate icons are not supported", details: nil))
          return
        }
        let name = (call.arguments as? [String: Any])?["name"] as? String
        let alternate: String? = name == "dark" ? "AppIconDark" : nil
        if app.alternateIconName == alternate {
          result(nil)
          return
        }
        app.setAlternateIconName(alternate) { error in
          if let error = error {
            result(FlutterError(code: "icon_failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
