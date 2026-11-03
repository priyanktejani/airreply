import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:flutter/material.dart';

/// The top of a step-by-step page (pairing, setup): the small green label, a large title and a line of explanation.
class PageIntro extends StatelessWidget {
  const PageIntro({required this.title, this.eyebrow, this.subtitle, super.key});

  final String title;
  final String? eyebrow;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.base, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: AppSpacing.xs)],
          Semantics(
            header: true,
            child: Text(title, style: AppType.pageTitle.copyWith(color: c.ink)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: AppType.bodyLarge.copyWith(color: c.muted)),
          ],
        ],
      ),
    );
  }
}
