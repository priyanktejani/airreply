import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

extension FeedbackContext on BuildContext {
  /// A short confirmation at the bottom of the screen.
  void showMessage(String message, {IconData? icon}) => _snack(message, icon: icon);

  void showError(Object error) => _snack(describeError(error), icon: AppIcons.errorOutline);

  /// A message with an Undo action, for reversible actions (hide, mark all as read).
  void showUndo(String message, VoidCallback onUndo) => _snack(
    message,
    action: SnackBarAction(label: 'Undo', onPressed: onUndo),
    duration: const Duration(seconds: 5),
  );

  void _snack(
    String message, {
    IconData? icon,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ink = palette.deepInk;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          action: action,
          content: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: ink), const SizedBox(width: AppSpacing.md)],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
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
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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
