import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
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

/// First launch: does this device share its notifications, or show and answer another phone's?
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.palette;
    final canShare = AppPlatform.canShareNotifications;

    void choose(DeviceRole role) {
      ref.tick();
      runGuarded(context, () => ref.read(deviceSessionProvider.notifier).chooseRole(role));
    }

    final sender = _RoleOption(
      icon: Icons.smartphone_rounded,
      title: 'Share my notifications',
      description: canShare
          ? 'This phone sends its notifications to your other devices, and sends the replies you write there.'
          : 'Only Android lets apps read notifications. Use an Android phone to share.',
      onTap: canShare ? () => choose(DeviceRole.sender) : null,
    );
    final receiver = _RoleOption(
      icon: Icons.devices_rounded,
      title: 'View and reply here',
      description: 'See your phone\'s notifications on this device and answer messages without picking it up.',
      onTap: () => choose(DeviceRole.receiver),
    );
    // the option this platform can use goes first
    final options = canShare ? [sender, receiver] : [receiver, sender];

    final sections = <Widget>[
      const UnderlinedHeadline(first: 'Your phone,', second: 'Everywhere.'),
      Text(
        'Read your phone\'s notifications on your iPhone, iPad, Mac, PC or browser, and reply to messages from there.',
        style: AppType.bodyLarge.copyWith(color: c.muted),
      ),
      const SectionHeader(eyebrow: 'Get started', title: 'How will you use this device?', padding: EdgeInsets.zero),
      for (final option in options) option,
      DecoratedBox(
        decoration: BoxDecoration(color: c.soft, borderRadius: AppRadius.lgBorder),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_rounded, size: AppDimensions.iconMd, color: c.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'End-to-end encrypted with a key only your devices hold. The server relays ciphertext it '
                  'cannot read.',
                  style: AppType.supporting.copyWith(color: c.muted),
                ),
              ),
            ],
          ),
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
                enabled ? Icons.arrow_forward_rounded : Icons.block_rounded,
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
