import 'dart:async';

import 'package:air_reply/app/router/app_router.dart';
import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/notifications/background/arrival_alerts.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/push/push_registration.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/domain/app_preferences.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AirReplyApp extends ConsumerWidget {
  const AirReplyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      // the app's strings and Material's own (dialog buttons, tooltips, dates) in the language chosen in Settings, or
      // the device's
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: AppMotion.slow,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => _SystemBars(
        child: _PairEffects(child: _InAppAlerts(child: child!)),
      ),
    );
  }
}

/// Status and navigation bars on paper, with icons that match the theme.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}

/// App-wide side effects of being paired: keep push tokens registered, follow the other device when it ends a pair,
/// and open the notification whose alert launched the app.
class _PairEffects extends ConsumerStatefulWidget {
  const _PairEffects({required this.child});

  final Widget child;

  @override
  ConsumerState<_PairEffects> createState() => _PairEffectsState();
}

class _PairEffectsState extends ConsumerState<_PairEffects> {
  StreamSubscription<RemoteMessage>? _pushTaps;

  /// Back in front: a pairing joined here may have been confirmed by the phone meanwhile.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => unawaited(ref.read(deviceSessionProvider.notifier).resumePairing()),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    unawaited(_openLaunchAlert());
    unawaited(_restoreKeptHistory());
    if (AppPlatform.usesPush && Firebase.apps.isNotEmpty) {
      // A push the system showed itself (Apple's alert text) opens its notification too, like the app's own alerts.
      _pushTaps = FirebaseMessaging.onMessageOpenedApp.listen(_openPush);
      unawaited(FirebaseMessaging.instance.getInitialMessage().then((m) => m == null ? null : _openPush(m)));
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_pushTaps?.cancel());
    super.dispose();
  }

  /// A device paired again before its kept history could be recognised gets it back now (see RestoreKeptHistory).
  Future<void> _restoreKeptHistory() async {
    await ref.read(deviceSessionProvider.future);
    if (mounted) await ref.read(deviceSessionProvider.notifier).resumePairing();
    if (mounted) await ref.read(deviceSessionProvider.notifier).ensureBackgroundReceiving();
    if (mounted) await ref.read(deviceSessionProvider.notifier).restoreKeptHistory();
  }

  Future<void> _openLaunchAlert() async {
    try {
      final target = await ref.read(mirroredAlertsProvider).launchTarget();
      if (target == null) return;
      await _open(target.pairId, target.notificationId);
    } on Object {
      // No launch details on this platform.
    }
  }

  Future<void> _openPush(RemoteMessage message) async {
    final data = message.data;
    if (data['type'] != 'notification') return;
    if ((data['pairId'], data['id']) case (final String pairId, final String id)) await _open(pairId, id);
  }

  /// Opens a notification of a phone this device is still paired with.
  Future<void> _open(String pairId, String notificationId) async {
    final session = await ref.read(deviceSessionProvider.future);
    if (!mounted || session.pair(pairId) == null) return;
    ref.read(appRouterProvider).go(AppRoutes.notification(pairId, notificationId));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushRegistrationProvider);
    for (final pair in ref.watch(pairedDevicesProvider)) {
      ref.listen(pairActiveProvider(pair.pairId), (_, next) {
        if (next.value == false) {
          unawaited(ref.read(deviceSessionProvider.notifier).unpair(pair.pairId, notifyPeer: false));
        }
      });
    }
    return widget.child;
  }
}

/// Receivers raise system alerts themselves while the app is running, for every notification that arrives, except
/// for apps muted in Settings and for the conversation already on screen: like WhatsApp, a message pops up and sounds
/// while the app is open too. While the window is not in front, an Android device that receives in the background
/// leaves alerts to that service (see `runSenderSync`); elsewhere the app raises them as long as it runs. Alerts
/// share the notification's id, so one never alerts twice. Listening here also keeps each pair's feed syncing
/// whatever screen is open.
class _InAppAlerts extends ConsumerStatefulWidget {
  const _InAppAlerts({required this.child});

  final Widget child;

  @override
  ConsumerState<_InAppAlerts> createState() => _InAppAlertsState();
}

class _InAppAlertsState extends ConsumerState<_InAppAlerts> {
  late final _arrivals = ArrivalAlerts(ref.read(mirroredAlertsProvider));

  bool get _inFront => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  Widget build(BuildContext context) {
    final pairs = ref.watch(pairedDevicesProvider);
    // Keeps app icons harvested from every pair's feed, whatever the role.
    ref.watch(appIconsProvider);
    final isReceiver = pairs.isNotEmpty && pairs.first.role == DeviceRole.receiver;
    if (isReceiver) {
      // receiving in the background (Android): that service alerts while the app is away
      final backgroundReceives = AppPlatform.isAndroid && (ref.watch(syncStatusProvider).value?.enabled ?? false);
      for (final pair in pairs) {
        ref.listen(mirroredNotificationsProvider(pair.pairId), (_, next) {
          if (next.value case final items?) {
            _onFeed(pair.pairId, pair.peerName, items, many: pairs.length > 1, backgroundReceives: backgroundReceives);
          }
        });
      }
    }
    return widget.child;
  }

  void _onFeed(
    String pairId,
    String deviceName,
    List<MirroredNotification> items, {
    required bool many,
    required bool backgroundReceives,
  }) {
    final fresh = _arrivals.arrived(pairId, items);
    // In front, new notifications simply appear in the app, with no popup or sound. Away, a push alerts on phones
    // (and the background service, when on); elsewhere the app does while it is still running.
    if (fresh.isEmpty || _inFront || backgroundReceives || AppPlatform.usesPush) return;
    final preferences = ref.read(appPreferencesProvider).value ?? const AppPreferences();
    for (final n in fresh) {
      if (!ArrivalAlerts.alertable(n, preferences)) continue;
      unawaited(
        _arrivals
            .show(n, pairId: pairId, preferences: preferences, deviceName: many ? deviceName : null)
            .catchError((Object _) {}),
      );
    }
  }
}
