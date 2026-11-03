import 'dart:async';

import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/utils/app_dimen.dart';
import 'package:air_reply/core/widgets/app_logo.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:air_reply/core/widgets/window_class_layout.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The four tabs: a bottom bar on phones, a rail on tablets, phones on their side and desktops. Back on another tab returns to Home before it
/// leaves the app; choosing the open tab again returns it to its first screen.
///
/// Permissions can change in the system settings at any time, so they are read again whenever the app returns to
/// the front.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// The window height the rail needs to show the logo above its four tabs.
  static const _railLogoMinHeight = 480.0;

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

    void select(int index) {
      if (index != shell.currentIndex) ref.tick();
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    }

    final items = [
      const FloatingNavItem(icon: AppIcons.home, selectedIcon: AppIcons.homeSelected, label: 'Home'),
      FloatingNavItem(
        icon: AppIcons.notificationsNone,
        selectedIcon: AppIcons.notificationsSelected,
        label: 'Notifications',
        semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
        badge: unread,
      ),
      const FloatingNavItem(icon: AppIcons.devices, selectedIcon: AppIcons.devicesSelected, label: 'Devices'),
      const FloatingNavItem(icon: AppIcons.settings, selectedIcon: AppIcons.settingsSelected, label: 'Settings'),
    ];
    final body = PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: shell,
    );

    Widget rail(BuildContext context) {
      Widget icon(FloatingNavItem item, {required bool selected}) {
        final glyph = Icon(selected ? item.selectedIcon : item.icon);
        return item.badge > 0 ? Badge(label: Text(item.badge > 99 ? '99+' : '${item.badge}'), child: glyph) : glyph;
      }

      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GlassContainer(
                  floating: true,
                  borderRadius: AppRadius.xxlBorder,
                  child: NavigationRail(
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.9,
                    // a window too short for the logo and all four tabs (a phone on its side) keeps the tabs
                    leading: AppDimen.of(context).screenHeight < _railLogoMinHeight
                        ? null
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.base),
                            child: AppLogo(height: 32, wordmark: false),
                          ),
                    destinations: [
                      for (final (i, item) in items.indexed)
                        NavigationRailDestination(
                          icon: Semantics(label: item.semanticLabel, child: icon(item, selected: false)),
                          selectedIcon: icon(item, selected: true),
                          label: Text(item.label),
                          padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.xs),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // phones: the floating bottom bar; tablets, phones turned sideways and desktops: the rail, which leaves the
    // window's height to the content
    return WindowClassLayout(
      mobile: (context) => Scaffold(
        extendBody: true,
        body: body,
        bottomNavigationBar: FloatingNavBar(items: items, selectedIndex: shell.currentIndex, onSelected: select),
      ),
      tablet: rail,
    );
  }
}
