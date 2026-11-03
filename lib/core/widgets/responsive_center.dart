import 'dart:math' as math;

import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Shows [child] no wider than [maxContentWidth], centred when there is more room, with [padding] around it (the page
/// margin): on a phone the child takes the whole width less the padding; on a wider window it is [maxContentWidth]
/// wide in the middle. It is as tall as its child, so it also centres a bar floating at the bottom of a screen.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxContentWidth = AppDimensions.maxContentWidth,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final double maxContentWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Center loosens the constraints; the SizedBox then asks for the full width, which the window caps when narrower
    return Center(
      heightFactor: 1,
      child: SizedBox(
        width: maxContentWidth + padding.horizontal,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// [ResponsiveCenter] for a sliver: pads [sliver] at the sides so its content is no wider than [maxContentWidth] and
/// centred, with [padding] around it.
class ResponsiveSliverCenter extends StatelessWidget {
  const ResponsiveSliverCenter({
    required this.sliver,
    this.maxContentWidth = AppDimensions.maxContentWidth,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget sliver;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final extra = math.max(0.0, (constraints.crossAxisExtent - maxContentWidth - padding.horizontal) / 2);
      return SliverPadding(
        padding: padding.add(EdgeInsets.symmetric(horizontal: extra)),
        sliver: sliver,
      );
    },
  );
}
