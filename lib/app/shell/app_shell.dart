import 'dart:async';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The four tabs: a bottom bar on phones, a rail on wide windows. Back on another tab returns to Home before it
/// leaves the app; choosing the open tab again returns it to its first screen.
///
/// Permissions can change in the system settings at any time, so they are read again whenever the app returns to
/// the front.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const railBreakpoint = 840.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  StatefulNavigationShell get shell => widget.shell;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recheck);
    // Receivers alert for new notifications while in the background: ask once, up front.
    if (ref.read(deviceRoleProvider) == DeviceRole.receiver) {
      unawaited(ref.read(alertPermissionProvider.notifier).request().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _recheck() {
    ref
      ..invalidate(alertPermissionProvider)
      ..invalidate(senderPermissionsProvider)
      ..invalidate(syncStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider);
    final c = context.colors;

    void select(int index) {
      if (index != shell.currentIndex) ref.tick();
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    }

    Widget inboxIcon(IconData icon) =>
        Badge(isLabelVisible: unread > 0, label: Text(unread > 99 ? '99+' : '$unread'), child: Icon(icon));

    final inboxLabel = unread > 0 ? 'Notifications, $unread unread' : 'Notifications';
    final wide = MediaQuery.sizeOf(context).width >= AppShell.railBreakpoint;

    final body = PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: shell,
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.9,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.x4),
                  child: Text('A', style: Theme.of(context).textTheme.headlineMedium),
                ),
                destinations: [
                  const NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Semantics(label: inboxLabel, child: inboxIcon(Icons.notifications_none)),
                    selectedIcon: inboxIcon(Icons.notifications),
                    label: const Text('Notifications'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.devices_outlined),
                    selectedIcon: Icon(Icons.devices),
                    label: Text('Devices'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: c.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: select,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: inboxIcon(Icons.notifications_none),
                selectedIcon: inboxIcon(Icons.notifications),
                label: 'Notifications',
                tooltip: inboxLabel,
              ),
              const NavigationDestination(
                icon: Icon(Icons.devices_outlined),
                selectedIcon: Icon(Icons.devices),
                label: 'Devices',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
