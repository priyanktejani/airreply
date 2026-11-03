import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

/// Starts Firebase with this app's options, or takes the default app the platform already started.
///
/// On iOS and macOS the native side may set up the default app first, from the bundled `GoogleService-Info.plist`.
/// When that copy differs from `firebase_options.dart` (a build made before `flutterfire configure` last ran, or a
/// hot restart), Firebase refuses a second default app; the one already running serves just as well, so the app
/// starts with it instead of stopping at the setup screen.
Future<void> startFirebase({Future<FirebaseApp> Function()? initialize}) async {
  try {
    await (initialize ?? () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform))();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    appLog(
      'Using the Firebase app the platform started: its config file differs from firebase_options.dart '
      '(rebuild to bring them in line)',
      name: 'air_reply',
    );
  }
}
