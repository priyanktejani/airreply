import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/app_logo.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/icon_tile.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:air_reply/core/widgets/underlined_headline.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// First launch: does this device share its notifications, or show and answer another phone's?
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final l10n = context.l10n;
    final canShare = AppPlatform.canShareNotifications;

    void choose(DeviceRole role) {
      ref.tick();
      runGuarded(context, () => ref.read(deviceSessionProvider.notifier).chooseRole(role));
    }

    final sender = _RoleOption(
      icon: AppIcons.smartphone,
      title: l10n.roleShareTitle,
      description: canShare ? l10n.roleShareDescription : l10n.roleShareUnavailable,
      onTap: canShare ? () => choose(DeviceRole.sender) : null,
    );
    final receiver = _RoleOption(
      icon: AppIcons.devices,
      title: l10n.roleReceiveTitle,
      description: l10n.roleReceiveDescription,
      onTap: () => choose(DeviceRole.receiver),
    );
    // the option this platform can use goes first
    final options = canShare ? [sender, receiver] : [receiver, sender];
    // devices removed before left their history here: it stays reachable while nothing is paired
    final previous = ref.watch(archivedPairsProvider).value?.length ?? 0;

    final sections = <Widget>[
      UnderlinedHeadline(first: l10n.welcomeHeadlineFirst, second: l10n.welcomeHeadlineSecond, playOnce: 'welcome'),
      Text(l10n.welcomeIntro, style: AppType.bodyLarge.copyWith(color: c.muted)),
      SectionHeader(eyebrow: l10n.welcomeEyebrow, title: l10n.welcomeQuestion, padding: EdgeInsets.zero),
      for (final option in options) option,
      DecoratedBox(
        decoration: BoxDecoration(color: c.soft, borderRadius: AppRadius.lgBorder),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.lock, size: AppDimensions.iconMd, color: c.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(context.l10n.welcomeEncryption, style: AppType.supporting.copyWith(color: c.muted)),
              ),
            ],
          ),
        ),
      ),
      if (previous > 0)
        Center(
          child: TextButton.icon(
            icon: const Icon(AppIcons.history, size: AppDimensions.iconSm),
            label: Text(l10n.previousDevicesSubtitle(previous)),
            onPressed: () => unawaited(context.push(AppRoutes.previousDevices)),
          ),
        ),
    ];

    return Scaffold(
      body: GlassScrollPage(
        maxWidth: 560,
        centerTitle: true,
        title: const AppLogo(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                for (final (i, w) in sections.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      top: i == 0
                          ? 0
                          : w is SectionHeader
                          ? AppSpacing.section
                          : AppSpacing.md,
                    ),
                    child: i == 0 ? w : FadeSlideIn.staggered(index: i, child: w),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One way to use this device, on a card: its icon on a tile, what it does, and an arrow. A way this device cannot
/// use is shown faded, with the reason.
class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.icon, required this.title, required this.description, required this.onTap});

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : .6,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon, size: AppDimensions.iconTileLg, enabled: enabled),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.title.copyWith(color: enabled ? c.ink : c.disabled)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description, style: AppType.body.copyWith(color: c.muted)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                enabled ? AppIcons.arrowForward : AppIcons.block,
                size: AppDimensions.iconMd,
                color: enabled ? c.accent : c.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
