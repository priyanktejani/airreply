import 'dart:typed_data';

import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// An app's icon, or its initial on a quiet tile when the icon is not known (yet).
class AppIconView extends StatelessWidget {
  const AppIconView({required this.appName, this.png, this.size = 40, super.key});

  final String appName;
  final Uint8List? png;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(size * 0.24);
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

  Widget _monogram(AppColors c, BorderRadius radius) {
    final name = appName.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.subtle,
        borderRadius: radius,
        border: Border.all(color: c.border),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AppType.subtitle.copyWith(color: c.ink, fontSize: size * 0.42, height: 1, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// An icon for a paired device, guessed from its name ("MacBook Pro", "iPad Air", "Chrome on Windows"...).
IconData deviceIcon(String name, {required bool isPhone}) {
  final n = name.toLowerCase();
  if (n.contains('ipad') || n.contains('tab')) return Icons.tablet_mac_outlined;
  if (n.contains('iphone')) return Icons.phone_iphone_outlined;
  if (n.contains('mac') || n.contains('book')) return Icons.laptop_mac_outlined;
  if (n.contains('windows') || n.contains('pc') || n.contains('desktop')) return Icons.desktop_windows_outlined;
  if (n.contains('chrome') || n.contains('browser') || n.contains('firefox') || n.contains('safari')) {
    return Icons.language_outlined;
  }
  if (n.contains('linux') || n.contains('ubuntu')) return Icons.computer_outlined;
  return isPhone ? Icons.smartphone_outlined : Icons.devices_outlined;
}
