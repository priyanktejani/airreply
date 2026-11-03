import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/icon_tile.dart';
import 'package:flutter/material.dart';

/// One row of a [CardGroup]: an icon on its tile, a title with an optional hint, and a trailing control or arrow.
/// [destructive] is for removing and deleting.
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  /// The icon tile's size.
  static const tile = 36.0;

  /// Where the row's text starts: the card padding, the tile and the gap (for the hairlines between rows).
  static const textInset = AppSpacing.card + tile + AppSpacing.md;

  /// An arrow, for rows that open another screen.
  static const chevron = Icon(AppIcons.chevronRight, size: AppDimensions.iconMd);

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final lead = leading ?? (icon == null ? null : IconTile(icon!, size: tile, danger: destructive, enabled: enabled));
    final titleColor = !enabled ? c.disabled : (destructive ? c.danger : c.ink);
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.card, vertical: AppSpacing.xxs),
      horizontalTitleGap: AppSpacing.md,
      shape: const RoundedRectangleBorder(),
      leading: lead,
      title: Text(title, style: AppType.subtitle.copyWith(color: titleColor)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppType.supporting.copyWith(color: enabled ? c.muted : c.disabled)),
      trailing: trailing == null
          ? null
          : IconTheme.merge(
              data: IconThemeData(color: c.muted),
              child: trailing!,
            ),
      onTap: enabled ? onTap : null,
    );
  }
}

/// A switch row; the whole row toggles.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InfoRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    ),
  );
}
