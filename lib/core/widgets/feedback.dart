import 'package:air_reply/core/l10n/describe_error.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

/// Every message at the bottom of the screen, built one way so they all look alike and are as wide as each other: the
/// screen's width less the theme's margins on a phone, and [maxSnackBarWidth] centred on a tablet or a desktop.
/// Built from [context] (for its size and colours) and shown with any [ScaffoldMessenger], even after that context
/// has gone (a deleted row, a closed sheet).
SnackBar appSnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  bool? persist,
}) {
  final ink = context.palette.deepInk;
  final width = MediaQuery.sizeOf(context).width;
  final side = width > maxSnackBarWidth + 2 * AppSpacing.base ? (width - maxSnackBarWidth) / 2 : AppSpacing.base;
  return SnackBar(
    duration: duration,
    persist: persist,
    action: action,
    margin: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.md),
    content: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: ink), const SizedBox(width: AppSpacing.md)],
        Expanded(child: Text(message)),
      ],
    ),
  );
}

/// How wide a bottom message grows on a big screen.
const double maxSnackBarWidth = 560;

extension FeedbackContext on BuildContext {
  /// A short confirmation at the bottom of the screen.
  void showMessage(String message, {IconData? icon}) => _snack(message, icon: icon);

  void showError(Object error) => _snack(describeError(error), icon: AppIcons.errorOutline);

  /// A message with an Undo action, for reversible actions (delete, mark all as read).
  void showUndo(String message, VoidCallback onUndo) => _snack(
    message,
    action: SnackBarAction(label: l10n.actionUndo, onPressed: onUndo),
    duration: const Duration(seconds: 5),
    // gone after its five seconds: with an action, Flutter would otherwise keep it until dismissed
    persist: false,
  );

  void _snack(
    String message, {
    IconData? icon,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    bool? persist,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(this, message, icon: icon, action: action, duration: duration, persist: persist));
  }

  /// Asks before an action that cannot be undone, over a frosted page. [destructive] marks the confirm button in the
  /// danger colour.
  Future<bool> confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showAppDialog<bool>(
      context: this,
      builder: (context) {
        final c = context.palette;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.actionCancel)),
            FilledButton(
              style: destructive ? FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: c.surface) : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
