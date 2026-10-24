import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

extension FeedbackContext on BuildContext {
  /// A short confirmation at the bottom of the screen.
  void showMessage(String message, {IconData? icon}) => _snack(message, icon: icon);

  void showError(Object error) => _snack(describeError(error), icon: Icons.error_outline);

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
    final paper = colors.paper;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          action: action,
          content: Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: paper), const SizedBox(width: Space.x3)],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  /// Asks before an action that cannot be undone. [destructive] marks the confirm button in the error colour.
  Future<bool> confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) {
        final c = context.colors;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actionsPadding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x5),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: destructive ? FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.paper) : null,
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
