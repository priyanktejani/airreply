import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:flutter/material.dart';

/// One step of a checklist, on a card like every other row: its number (or nothing) on a tile-sized circle that turns
/// into a tick once done, what to do and why, and the buttons that do it; "Done" once it is.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    required this.title,
    required this.subtitle,
    required this.done,
    this.index,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final bool done;

  /// The step's number, for an ordered list; a plain circle without.
  final int? index;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card, vertical: AppSpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppMotion.medium,
              width: InfoRow.tile,
              height: InfoRow.tile,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.accent : null,
                border: done ? null : Border.all(color: c.line),
              ),
              child: done
                  ? Icon(AppIcons.check, size: 16, color: c.bg, semanticLabel: context.l10n.stepDone)
                  : index == null
                  ? null
                  : Text(
                      '$index',
                      style: AppType.supporting.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: AppType.supporting.copyWith(color: c.muted)),
                  const SizedBox(height: AppSpacing.sm),
                  if (done)
                    Text(
                      context.l10n.stepDone,
                      style: AppType.supporting.copyWith(color: c.accent, fontWeight: FontWeight.w600),
                    )
                  else if (actions.isNotEmpty)
                    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
