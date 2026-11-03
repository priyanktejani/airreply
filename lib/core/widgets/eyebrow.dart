import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The small green mono label above headings, as on the website. [color] for dark banners, where the theme's green
/// would not read; [maxLines] to keep it to one line in tight spaces.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.maxLines});
  final String text;
  final Color? color;
  final int? maxLines;
  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      fontFamily: mono,
      fontWeight: FontWeight.w500,
      color: color ?? context.palette.accent,
      letterSpacing: .3,
    ),
  );
}
