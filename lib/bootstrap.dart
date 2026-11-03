import 'dart:async';

import 'package:air_reply/app/air_reply_app.dart';
import 'package:air_reply/app/firebase_setup_required_app.dart';
import 'package:air_reply/app/router/app_router.dart';
import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/background/push_entrypoints.dart';
import 'package:air_reply/core/firebase/firebase_start.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/sync_wake_port.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/notifications/background/alert_handlers.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI isolate start-up on every platform: backend, push and alert handlers, then the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorLogging();
  _registerFontLicenses();

  // Independent, so started together: the backend, and the theme (read before the first frame so the app opens
  // straight into it).
  final backend = AppPlatform.isDemo ? Future<void>.value() : _startBackend();
  final theme = ThemeModeStore(SharedPreferencesAsync()).read().catchError((Object _) => ThemeMode.system);
  try {
    await backend;
  } on Object catch (e) {
    runApp(FirebaseSetupRequiredApp(error: e));
    return;
  }
  final themeMode = await theme;
  final container = ProviderContainer(
    overrides: [
      initialThemeModeProvider.overrideWithValue(themeMode),
      if (AppPlatform.isDemo) ...demoOverrides(AppPlatform.demo),
    ],
  );

  if (AppPlatform.usesPush) {
    FirebaseMessaging.onBackgroundMessage(onBackgroundPush);
    // While the app is open the receiver's feed updates live, so only the sender cares about foreground pushes.
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'reply') SyncWakePort.wake();
    });
  }

  try {
    await container
        .read(mirroredAlertsProvider)
        .initialize(
          onResponse: (response) {
            final reply = MirroredAlerts.replyFrom(response);
            if (reply != null) return unawaited(sendAlertReply(container, reply));
            // A tap on the alert opens that notification.
            if (MirroredAlerts.targetFrom(response) case final target?) {
              container.read(appRouterProvider).go(AppRoutes.notification(target.pairId, target.notificationId));
            }
          },
          onBackgroundResponse: AppPlatform.usesPush ? onAlertActionInBackground : null,
        );
  } on Object catch (e) {
    // e.g. Linux without a notification daemon: the feed still works, just without system alerts.
    appLog('Alerts unavailable: $e', name: 'air_reply');
  }

  runApp(UncontrolledProviderScope(container: container, child: const AirReplyApp()));
}

/// FlutterFire where it is supported for production; elsewhere only check that the REST config exists.
Future<void> _startBackend() async {
  switch (AppPlatform.backend) {
    case BackendTransport.firebaseSdk:
      await startFirebase();
    case BackendTransport.rest:
      // Throws until `flutterfire configure` (with web) has been run.
      if (DefaultFirebaseOptions.web.projectId.isEmpty) throw StateError('The Firebase web config has no project id.');
  }
}

/// The bundled fonts' licences ship with them and show in Settings → licences: the SIL Open Font License of the Geist
/// typefaces and the MIT licence of the Phosphor icons.
void _registerFontLicenses() => LicenseRegistry.addLicense(() async* {
  for (final (family, file) in const [('Geist', 'OFL-Geist.txt'), ('Phosphor Icons', 'MIT-Phosphor.txt')]) {
    yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/fonts/$file'));
  }
});

void _installErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appLog('Flutter error', error: details.exception, stackTrace: details.stack, name: 'air_reply');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    appLog('Uncaught error', error: error, stackTrace: stack, name: 'air_reply');
    return true;
  };
}
