import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/eyebrow.dart';
import 'package:flutter/material.dart';

/// A section heading as on the website: the small green mono label ([eyebrow]) above the title, and an optional action
/// on the right ("See all"). Pads to the page margins by default; pass [padding] zero inside cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onActionPressed,
    this.trailing,
    this.large = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.page),
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Widget? trailing;

  /// A bigger title for the first section of a page.
  final bool large;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: AppSpacing.xs)],
                Text(title, style: large ? t.headlineSmall : t.titleLarge),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onActionPressed != null)
            TextButton(onPressed: onActionPressed, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
