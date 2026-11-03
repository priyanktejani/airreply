import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/icon_tile.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A phone's two sharing shortcuts as cards side by side: the apps it shares, and pairing another device. Each has
/// what it is along the top and its action in the accent colour along the bottom.
class SharingShortcuts extends ConsumerWidget {
  const SharingShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(appFilterProvider).value;
    final apps = switch (filter) {
      null => 'Loading…',
      AppFilter(mode: AppFilterMode.all) => 'Every app is shared',
      AppFilter(:final packages) when packages.isEmpty => 'No apps selected: nothing is shared',
      AppFilter(:final packages) => '${packages.length} selected ${packages.length == 1 ? 'app' : 'apps'}',
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Shortcut(
              icon: AppIcons.apps,
              who: 'Apps to share',
              title: apps,
              action: 'Choose apps →',
              onTap: () => context.push(AppRoutes.apps),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _Shortcut(
              icon: AppIcons.addLink,
              who: 'Add a device',
              title: 'iPhone, iPad, Mac, PC, browser or Android',
              action: 'Pair →',
              onTap: () => context.push(AppRoutes.pair),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.who,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String who, title, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon, size: AppDimensions.iconTileSm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.supporting.copyWith(color: c.muted),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleSmall.copyWith(color: c.ink),
                ),
              ),
            ),
          ),
          Text(action, style: AppType.link.copyWith(color: c.accent)),
        ],
      ),
    );
  }
}
