import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/app/shell/app_shell.dart';
import 'package:air_reply/app/splash_screen.dart';
import 'package:air_reply/core/animations/page_transitions.dart';
import 'package:air_reply/features/app_management/presentation/app_management_screen.dart';
import 'package:air_reply/features/devices/presentation/devices_screen.dart';
import 'package:air_reply/features/home/presentation/home_screen.dart';
import 'package:air_reply/features/notifications/presentation/app_conversations_screen.dart';
import 'package:air_reply/features/notifications/presentation/conversation_screen.dart';
import 'package:air_reply/features/notifications/presentation/inbox_screen.dart';
import 'package:air_reply/features/notifications/presentation/notification_detail_screen.dart';
import 'package:air_reply/features/onboarding/presentation/welcome_screen.dart';
import 'package:air_reply/features/pairing/presentation/pairing_screen.dart';
import 'package:air_reply/features/permissions/presentation/setup_screen.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/presentation/diagnostics_screen.dart';
import 'package:air_reply/features/settings/presentation/settings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever the device session changes (role chosen, paired, unpaired...).
  final sessionChanged = ValueNotifier(0);
  ref
    ..listen(deviceSessionProvider, (_, _) => sessionChanged.value++)
    ..onDispose(sessionChanged.dispose);

  final root = GlobalKey<NavigatorState>(debugLabel: 'root');

  // Screens opened from a tab cover the tab bar: they are steps of one task, with a back button.
  // pushed screens slide in a little from the right while fading in; flow screens fade through
  GoRoute overTabs(String path, Widget Function(GoRouterState state) build) => GoRoute(
    path: path,
    parentNavigatorKey: root,
    pageBuilder: (_, state) => AppTransitions.push(state, build(state)),
  );

  final router = GoRouter(
    navigatorKey: root,
    initialLocation: AppRoutes.splash,
    refreshListenable: sessionChanged,
    redirect: (context, state) => resolveRedirect(ref.read(deviceSessionProvider), state.uri.path),
    routes: [
      GoRoute(path: AppRoutes.splash, pageBuilder: (_, state) => AppTransitions.fade(state, const SplashScreen())),
      GoRoute(path: AppRoutes.welcome, pageBuilder: (_, state) => AppTransitions.fade(state, const WelcomeScreen())),
      GoRoute(path: AppRoutes.setup, pageBuilder: (_, state) => AppTransitions.fade(state, const SetupScreen())),
      GoRoute(path: AppRoutes.pair, pageBuilder: (_, state) => AppTransitions.push(state, const PairingScreen())),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (_, _) => const InboxScreen(),
                routes: [
                  overTabs(
                    'app/:source/:package',
                    (state) => AppConversationsScreen(
                      source: state.pathParameters['source']!,
                      packageName: state.pathParameters['package']!,
                    ),
                  ),
                  overTabs(
                    'thread/:source/:package/:thread',
                    (state) => ConversationScreen(
                      source: state.pathParameters['source']!,
                      packageName: state.pathParameters['package']!,
                      threadKey: state.pathParameters['thread']!,
                      at: state.uri.queryParameters['at'],
                    ),
                  ),
                  overTabs(
                    ':pairId/:id',
                    (state) => NotificationDetailScreen(
                      pairId: state.pathParameters['pairId']!,
                      notificationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.devices, builder: (_, _) => const DevicesScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  overTabs('apps', (_) => const AppManagementScreen()),
                  overTabs('diagnostics', (_) => const DiagnosticsScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
