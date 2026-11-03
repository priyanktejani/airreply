import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/info_row.dart';
import 'package:air_reply/core/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Rows on one card, divided by hairlines that start under the row text; with a [title] (and [eyebrow]) it opens with
/// a section heading. The settings-like list of the app.
class CardGroup extends StatelessWidget {
  const CardGroup({required this.children, this.title, this.eyebrow, this.inset = InfoRow.textInset, super.key});

  final List<Widget> children;
  final String? title;
  final String? eyebrow;

  /// Where the hairlines start; 0 for rows without an icon.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final card = AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in children.indexed) ...[if (i > 0) Divider(height: 1, indent: inset), row],
        ],
      ),
    );
    if (title == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title!,
          eyebrow: eyebrow,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        const SizedBox(height: AppSpacing.md),
        card,
      ],
    );
  }
}
