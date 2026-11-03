import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

enum Tone { neutral, success, warning, error }

extension ToneColor on Tone {
  Color of(BuildContext context) {
    final c = context.palette;
    return switch (this) {
      Tone.neutral => c.muted,
      Tone.success => c.accent,
      Tone.warning => c.warnInk,
      Tone.error => c.danger,
    };
  }
}

/// A state in words with an icon: never colour alone.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.icon, this.tone = Tone.neutral, this.busy = false, super.key});

  final String label;
  final IconData icon;
  final Tone tone;

  /// Shows a small spinner instead of the icon (connecting, sending).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = tone.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 14,
          child: busy ? CircularProgressIndicator(strokeWidth: 1.5, color: color) : Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.supporting.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
