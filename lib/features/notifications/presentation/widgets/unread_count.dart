import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// How many notifications are unread: an accent count when there are some, nothing otherwise. It pops in.
class UnreadCount extends StatelessWidget {
  const UnreadCount(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AnimatedSwitcher(
      duration: context.motion(AppMotion.medium),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: child,
      ),
      child: count == 0
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(count),
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.fullBorder),
              child: Semantics(
                label: context.l10n.unreadCount(count),
                excludeSemantics: true,
                child: Text(count > 99 ? '99+' : '$count', style: AppType.caption.copyWith(color: c.accentInk)),
              ),
            ),
    );
  }
}
