import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A placeholder block with a soft moving sheen, shown where content is loading.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = AppRadius.sm});

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2.5 * _c.value - 1, 0),
            end: Alignment(1 + 2.5 * _c.value - 1, 0),
            colors: [c.soft, c.line, c.soft],
          ),
        ),
        child: SizedBox(height: widget.height, width: widget.width ?? double.infinity),
      ),
    );
  }
}

/// A few card-shaped placeholders: the default "loading" look for lists and pages. It does not scroll or pad: put it
/// where the loaded list will be, so nothing jumps when it arrives.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 4, this.itemHeight = 92});

  final int rows;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          SkeletonBox(height: itemHeight, radius: AppRadius.lg),
        ],
      ],
    ),
  );
}
