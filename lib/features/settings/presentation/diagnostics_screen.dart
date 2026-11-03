import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/card_group.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/features/devices/devices_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/permissions/presentation/permission_notices.dart';
import 'package:air_reply/features/permissions/presentation/sender_permissions_controller.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/domain/diagnostics.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this device knows about its own state, for checking a problem or sending it to someone who helps. Contains
/// no notification content and no keys.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(deviceRoleProvider);
    final isSender = role == DeviceRole.sender;
    final pairs = ref.watch(pairedDevicesProvider);
    final now = DateTime.now();
    String at(DateTime? t) => t == null ? 'never' : '${formatTimestamp(t, now: now)} (${formatAgo(t, now: now)})';

    final sections = [
      DiagnosticsSection('This device', [
        ('Platform', AppPlatform.name),
        ('Role', role?.name ?? 'not chosen'),
        ('Backend', ref.watch(backendTransportProvider).name),
        ('Push', AppPlatform.usesPush ? 'used' : 'not used (alerts while running)'),
        if (AppPlatform.isDemo) ('Demo mode', AppPlatform.demo),
      ]),
      if (isSender) _senderSection(ref) else _receiverSection(ref),
      for (final (i, pair) in pairs.indexed)
        DiagnosticsSection('Device ${i + 1}', [
          ('Name', pair.peerName),
          ('Pair', '${pair.pairId.substring(0, pair.pairId.length.clamp(0, 6))}…'),
          ('State', ref.watch(deviceStatusProvider(pair.pairId)).label),
          ('Last synced', at(ref.watch(deviceStatusProvider(pair.pairId)).lastSyncedAt)),
          ('Last notification', at(ref.watch(lastActivityProvider(pair.pairId)))),
          ('Notifications loaded', '${ref.watch(mirroredNotificationsProvider(pair.pairId)).value?.length ?? '–'}'),
          ('Paired', formatLongDate(pair.pairedAt, now: now)),
        ]),
      DiagnosticsSection('Inbox', [
        ('Unread', '${ref.watch(unreadCountProvider)}'),
        ('Hidden', '${ref.watch(hiddenCountProvider)}'),
        ('App icons cached', '${ref.watch(appIconsProvider).length}'),
      ]),
    ];

    return Scaffold(
      body: GlassScrollPage(
        title: const Text('Diagnostics'),
        slivers: [
          SliverList.list(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nothing here includes notification text or encryption keys.',
                style: AppType.body.copyWith(color: context.palette.muted),
              ),
              for (final (i, section) in sections.indexed)
                FadeSlideIn.staggered(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.section),
                    child: CardGroup(
                      title: section.title,
                      inset: AppSpacing.card,
                      children: [for (final (label, value) in section.rows) _Line(label, value)],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: diagnosticsText(sections, generatedAt: now)));
                  if (context.mounted) context.showMessage('Report copied');
                },
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('Copy report'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  for (final pair in pairs) {
                    refreshPair(ref, pair.pairId);
                  }
                  ref
                    ..invalidate(alertPermissionProvider)
                    ..invalidate(senderPermissionsProvider)
                    ..invalidate(syncStatusProvider);
                  context.showMessage('Checking again…');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check again'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DiagnosticsSection _senderSection(WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value;
    final permissions = ref.watch(senderPermissionsProvider).value;
    final restrictions = permissions?.restrictions;
    return DiagnosticsSection('Sharing', [
      ('Sharing', status?.label ?? 'unknown'),
      ('Service running', onOff(status?.running)),
      ('Listener connected', onOff(status?.listenerConnected)),
      ('Notification access', onOff(permissions?.notificationAccess)),
      ('Status notification', onOff(permissions?.postNotifications)),
      ('Battery unrestricted', onOff(restrictions?.ignoringBatteryOptimizations)),
      ('Maker', restrictions?.vendorName ?? 'unknown'),
      ('Autostart screen', restrictions == null ? 'unknown' : (restrictions.hasAutostartScreen ? 'yes' : 'no')),
    ]);
  }

  DiagnosticsSection _receiverSection(WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider).value;
    return DiagnosticsSection('Alerts', [
      ('Alerts allowed', onOff(ref.watch(alertPermissionProvider).value)),
      ('Message text in alerts', onOff(preferences?.alertShowsContent)),
      ('Muted apps', '${preferences?.mutedApps.length ?? 0}'),
    ]);
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: AppType.body.copyWith(color: c.muted)),
          ),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: AppType.body.copyWith(color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}
