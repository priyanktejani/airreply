import 'dart:async';

import 'package:air_reply/app/air_reply_app.dart';
import 'package:air_reply/app/firebase_setup_required_app.dart';
import 'package:air_reply/app/router/app_router.dart';
import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/background/push_entrypoints.dart';
import 'package:air_reply/core/firebase/firebase_start.dart';
import 'package:air_reply/core/haptics/haptics.dart';
import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/sync_wake_port.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/notifications/background/alert_handlers.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/settings/erase_everything.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
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

  // Independent, so started together: the backend, and the theme and language (read before the first frame so the
  // app opens straight into them).
  final backend = AppPlatform.isDemo ? Future<void>.value() : _startBackend();
  final theme = ThemeModeStore(SharedPreferencesAsync()).read().catchError((Object _) => ThemeMode.system);
  final language = AppLanguageStore(SharedPreferencesAsync()).read().catchError((Object _) => null);
  try {
    await backend;
  } on Object catch (e) {
    runApp(FirebaseSetupRequiredApp(error: e));
    return;
  }
  final themeMode = await theme;
  final locale = await language;
  final container = ProviderContainer(
    overrides: [
      // Settings → Haptic feedback, read by every haptic through this one provider
      hapticsEnabledProvider.overrideWith((ref) => ref.watch(appPreferencesProvider).value?.haptics ?? true),
      initialThemeModeProvider.overrideWithValue(themeMode),
      initialAppLocaleProvider.overrideWithValue(locale),
      if (AppPlatform.isDemo) ...demoOverrides(AppPlatform.demo),
    ],
  );

  // before anything reads a key: a reinstall must not find the earlier install's keychain
  if (!AppPlatform.isDemo) await forgetEarlierInstall(container);

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
          // Android hands a reply typed into an alert to a background isolate, even while the app is open; iOS does when
          // it is suspended. Push or not: without this the reply is dropped.
          onBackgroundResponse: AppPlatform.isAndroid || AppPlatform.isIOS ? onAlertActionInBackground : null,
        );
    // Android: only the two channels alerts use now ("Messages", "Other notifications") stay in the system's
    // settings; the per-choice ones of earlier versions go (each person's settings on these two are kept).
    if (AppPlatform.isAndroid) {
      unawaited(container.read(mirroredAlertsProvider).tidyChannels(AlertStyle.standard).catchError((Object _) {}));
    }
    // a reply typed into an alert that started the app: sent now, not lost as a plain tap
    if (await container.read(mirroredAlertsProvider).launchReply() case final reply?) {
      unawaited(sendAlertReply(container, reply));
    }
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
