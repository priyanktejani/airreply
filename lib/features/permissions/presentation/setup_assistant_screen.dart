import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/page_intro.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/permissions/domain/setup_tasks.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/permissions/presentation/setup_tasks_provider.dart';
import 'package:air_reply/features/permissions/presentation/widgets/checklist_row.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Everything this device needs to share or show notifications reliably, even in the background: what is done, what
/// is not, why it matters and the button that fixes it, with the steps for this phone's maker where they differ. It
/// reads the state again whenever the person comes back from the system settings.
class SetupAssistantScreen extends ConsumerStatefulWidget {
  const SetupAssistantScreen({super.key});

  @override
  ConsumerState<SetupAssistantScreen> createState() => _SetupAssistantScreenState();
}

class _SetupAssistantScreenState extends ConsumerState<SetupAssistantScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Back from the system settings: read every grant again.
  void _refresh() {
    if (ref.read(deviceRoleProvider) == DeviceRole.sender) {
      unawaited(ref.read(senderPermissionsProvider.notifier).refresh());
      ref.invalidate(syncStatusProvider);
    } else {
      unawaited(ref.read(alertPermissionProvider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tasks = ref.watch(setupTasksProvider);
    final needed = [
      for (final t in tasks)
        if (t.importance == SetupImportance.required) t,
    ];
    final recommended = [
      for (final t in tasks)
        if (t.importance == SetupImportance.recommended) t,
    ];
    return Scaffold(
      body: GlassScrollPage(
        title: Text(l10n.setupAssistantTitle),
        onRefresh: () async => _refresh(),
        slivers: [
          SliverList.list(
            children: [
              PageIntro(
                eyebrow: l10n.setupAssistantProgress(tasks.doneCount, tasks.length),
                title: l10n.setupAssistantIntroTitle,
                subtitle: l10n.setupAssistantIntro,
              ),
              LinearProgressIndicator(value: tasks.isEmpty ? null : tasks.doneCount / tasks.length),
              const SizedBox(height: AppSpacing.section),
              if (tasks.isNotEmpty && tasks.allDone)
                EmptyState(
                  icon: AppIcons.taskDone,
                  tone: Tone.success,
                  title: l10n.setupAllDone,
                  description: l10n.setupAllDoneHint,
                ),
              if (needed.isNotEmpty)
                CardGroup(title: l10n.setupNeeded, children: [for (final t in needed) _TaskRow(t)]),
              if (recommended.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                CardGroup(title: l10n.setupRecommended, children: [for (final t in recommended) _TaskRow(t)]),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow(this.task);

  final SetupTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final permissions = ref.read(senderPermissionsProvider.notifier);
    final vendor = ref.watch(senderPermissionsProvider.select((p) => p.value?.restrictions.vendor)) ?? '';
    final isSender = ref.watch(deviceRoleProvider) == DeviceRole.sender;
    Widget open(String label, Future<void> Function() action) =>
        OutlinedButton(onPressed: guarded(context, action), child: Text(label));

    final (title, subtitle, actions) = switch (task.id) {
      SetupTaskId.notificationAccess => (
        l10n.permissionAccessTitle,
        l10n.taskAccessText,
        [open(l10n.actionOpenSettings, permissions.openNotificationAccess)],
      ),
      SetupTaskId.sharingOn => (
        l10n.shareNotificationsTitle,
        l10n.taskSharingText,
        [open(l10n.actionTurnOn, () => ref.read(syncStatusProvider.notifier).setEnabled(true))],
      ),
      SetupTaskId.listener => (
        l10n.listenerTitle,
        l10n.taskListenerText,
        [open(l10n.actionReconnect, () => ref.read(syncStatusProvider.notifier).reconnectListener())],
      ),
      SetupTaskId.statusNotification => (
        l10n.permissionStatusTitle,
        l10n.setupStatusSubtitle,
        [open(l10n.actionAllow, permissions.requestPostNotifications)],
      ),
      SetupTaskId.backgroundActivity => (
        l10n.taskBackgroundTitle,
        l10n.taskBackgroundText,
        [open(l10n.actionOpenSettings, permissions.openAppSettings)],
      ),
      SetupTaskId.battery => (
        l10n.permissionBatteryTitle,
        vendor == 'samsung' ? '${l10n.setupBatterySubtitle} ${l10n.taskBatterySamsung}' : l10n.setupBatterySubtitle,
        [open(l10n.actionBatterySettings, permissions.openBatterySettings)],
      ),
      SetupTaskId.autostart => (
        l10n.permissionAutostartTitle,
        autostartSteps(l10n, vendor),
        [
          open(l10n.actionOpenSettings, permissions.openAutostartSettings),
          TextButton(
            onPressed: () => unawaited(ref.read(appPreferencesProvider.notifier).setAutostartConfirmed(true)),
            child: Text(l10n.actionAutostartDone),
          ),
        ],
      ),
      SetupTaskId.alerts => (
        l10n.permissionAlertsTitle,
        AppPlatform.isWeb ? l10n.permissionAlertsBrowser : l10n.taskAlertsText,
        [open(l10n.actionAllow, ref.read(alertPermissionProvider.notifier).request)],
      ),
      SetupTaskId.pairDevice => (
        isSender ? l10n.pairADevice : l10n.pairWithYourPhone,
        isSender ? l10n.taskPairSender : l10n.taskPairReceiver,
        [OutlinedButton(onPressed: () => context.push(AppRoutes.pair), child: Text(l10n.pairTitle))],
      ),
    };
    return ChecklistRow(title: title, subtitle: subtitle, done: task.isDone, actions: actions);
  }
}

/// Where this phone's maker hides its autostart switch.
String autostartSteps(AppLocalizations l10n, String vendor) => switch (vendor) {
  'xiaomi' || 'redmi' || 'poco' => l10n.taskAutostartXiaomi,
  'oppo' || 'realme' || 'oneplus' => l10n.taskAutostartOppo,
  'vivo' || 'iqoo' => l10n.taskAutostartVivo,
  'huawei' || 'honor' => l10n.taskAutostartHuawei,
  _ => l10n.setupAutostartSubtitle(vendor.isEmpty ? l10n.thisPhone : vendor[0].toUpperCase() + vendor.substring(1)),
};

/// Home's reminder while setup is unfinished: how far it is and the next step; opens the assistant. With only
/// recommended steps left, it can be put away.
class SetupCard extends ConsumerWidget {
  const SetupCard({this.bottom = AppSpacing.section, super.key});

  final double bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.palette;
    final tasks = ref.watch(setupTasksProvider);
    final hidden = ref.watch(appPreferencesProvider.select((p) => p.value?.setupCardHidden ?? false));
    if (tasks.isEmpty || tasks.allDone || (hidden && !tasks.requiredOpen)) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: CardGroup(
        children: [
          Semantics(
            button: true,
            child: InkWell(
              onTap: () => context.push(AppRoutes.setupAssistant),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.card, AppSpacing.base, AppSpacing.sm, AppSpacing.base),
                child: Row(
                  children: [
                    Icon(AppIcons.checklist, color: c.accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.setupCardTitle, style: AppType.subtitle.copyWith(color: c.ink)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n.setupAssistantProgress(tasks.doneCount, tasks.length),
                            style: AppType.supporting.copyWith(color: c.muted),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(value: tasks.doneCount / tasks.length),
                        ],
                      ),
                    ),
                    if (!tasks.requiredOpen)
                      IconButton(
                        tooltip: l10n.actionNotNow,
                        icon: const Icon(AppIcons.close),
                        onPressed: () => unawaited(ref.read(appPreferencesProvider.notifier).setSetupCardHidden(true)),
                      )
                    else
                      Icon(AppIcons.chevronRight, color: c.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
