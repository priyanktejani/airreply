import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

/// A small tile with an icon on the soft accent ground. Sizes: [AppDimensions.iconTileSm], [AppDimensions.iconTile]
/// (the default) and [AppDimensions.iconTileLg]. [danger] uses the soft red ground, for deleting and removing.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = AppDimensions.iconTile, this.danger = false, this.enabled = true});

  final IconData icon;
  final double size;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (ground, ink) = switch ((enabled, danger)) {
      (false, _) => (c.soft, c.disabled),
      (true, true) => (c.dangerSoft, c.danger),
      (true, false) => (c.accentSoft, c.accent),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: size >= AppDimensions.iconTileLg ? AppRadius.mdBorder : AppRadius.smBorder,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, color: ink, size: size * .5),
        ),
      ),
    );
  }
}
