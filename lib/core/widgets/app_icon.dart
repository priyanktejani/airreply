import 'dart:typed_data';

import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// An app's icon, or its initial in the accent colour on the soft accent tile when the icon is not known (yet).
class AppIconView extends StatelessWidget {
  const AppIconView({required this.appName, this.png, this.size = 40, super.key});

  final String appName;
  final Uint8List? png;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final radius = BorderRadius.circular(size * 0.3);
    final icon = png;
    if (icon != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(
          icon,
          width: size,
          height: size,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => _monogram(c, radius),
        ),
      );
    }
    return _monogram(c, radius);
  }

  Widget _monogram(AppPalette c, BorderRadius radius) {
    final name = appName.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: radius),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AppType.title.copyWith(color: c.accent, fontSize: size * 0.42, height: 1, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// An icon for a paired device, guessed from its name ("MacBook Pro", "iPad Air", "Chrome on Windows"...).
IconData deviceIcon(String name, {required bool isPhone}) {
  final n = name.toLowerCase();
  if (n.contains('ipad') || n.contains('tab')) return AppIcons.tabletMac;
  if (n.contains('iphone')) return AppIcons.phoneIphone;
  if (n.contains('mac') || n.contains('book')) return AppIcons.laptopMac;
  if (n.contains('windows') || n.contains('pc') || n.contains('desktop')) return AppIcons.desktopWindows;
  if (n.contains('chrome') || n.contains('browser') || n.contains('firefox') || n.contains('safari')) {
    return AppIcons.language;
  }
  if (n.contains('linux') || n.contains('ubuntu')) return AppIcons.computer;
  return isPhone ? AppIcons.smartphone : AppIcons.devices;
}
