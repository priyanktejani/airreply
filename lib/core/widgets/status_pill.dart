import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A small rounded status label (Open, Booked, Paid…), coloured by [tone].
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});
  final String label;
  final PillTone tone;
  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (bg, fg) = switch (tone) {
      PillTone.good => (c.accentSoft, c.accent),
      PillTone.warn => (c.warnSoft, c.warnInk),
      PillTone.bad => (c.dangerSoft, c.danger),
      PillTone.neutral => (c.soft, c.muted),
    };
    // a pill keeps its own size at the start, even in a column that stretches its children
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.fullBorder),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xxs, vertical: AppSpacing.xs),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, letterSpacing: 0)),
        ),
      ),
    );
  }
}

enum PillTone { good, warn, bad, neutral }
