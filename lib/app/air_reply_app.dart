import 'dart:async';

import 'package:air_reply/app/router/app_router.dart';
import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/theme/theme_mode.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/push/push_registration.dart';
import 'package:air_reply/features/session/session_providers.dart';
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
      title: 'AirReply',
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

  @override
  void initState() {
    super.initState();
    unawaited(_openLaunchAlert());
    if (AppPlatform.usesPush && Firebase.apps.isNotEmpty) {
      // A push the system showed itself (Apple's alert text) opens its notification too, like the app's own alerts.
      _pushTaps = FirebaseMessaging.onMessageOpenedApp.listen(_openPush);
      unawaited(FirebaseMessaging.instance.getInitialMessage().then((m) => m == null ? null : _openPush(m)));
    }
  }

  @override
  void dispose() {
    unawaited(_pushTaps?.cancel());
    super.dispose();
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

/// Receivers raise system alerts themselves while the app is running, for every notification that arrives while
/// the window is not in front, except for apps muted in Settings. That is the only alert path on desktop and web,
/// and the fallback on phones when push is not deployed or late; alerts share the push's id, so one notification
/// never alerts twice. Listening here also keeps each pair's feed syncing whatever screen is open.
class _InAppAlerts extends ConsumerStatefulWidget {
  const _InAppAlerts({required this.child});

  final Widget child;

  @override
  ConsumerState<_InAppAlerts> createState() => _InAppAlertsState();
}

class _InAppAlertsState extends ConsumerState<_InAppAlerts> {
  /// Per pair, the notification ids already known. Null until that pair's first load, which never alerts.
  final _seen = <String, Set<String>>{};

  bool get _inFront => WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  Widget build(BuildContext context) {
    final pairs = ref.watch(pairedDevicesProvider);
    // Keeps app icons harvested from every pair's feed, whatever the role.
    ref.watch(appIconsProvider);
    final isReceiver = pairs.isNotEmpty && pairs.first.role == DeviceRole.receiver;
    if (isReceiver) {
      for (final pair in pairs) {
        ref.listen(mirroredNotificationsProvider(pair.pairId), (_, next) {
          if (next.value case final items?) _onFeed(pair.pairId, pair.peerName, items, pairs.length > 1);
        });
      }
    }
    return widget.child;
  }

  void _onFeed(String pairId, String deviceName, List<MirroredNotification> items, bool manyDevices) {
    final known = _seen[pairId];
    _seen[pairId] = {for (final n in items) n.id};
    if (known == null || _inFront) return;

    final alerts = ref.read(mirroredAlertsProvider);
    final preferences = ref.read(appPreferencesProvider).value;
    for (final n in items.where((n) => !known.contains(n.id) && !n.dismissedOnSender)) {
      if (!(preferences?.alertsFor(n.content.packageName) ?? true)) continue;
      unawaited(
        alerts
            .show(
              n,
              pairId: pairId,
              deviceName: manyDevices ? deviceName : null,
              showContent: preferences?.alertShowsContent ?? true,
            )
            .catchError((Object _) {}),
      );
    }
  }
}
