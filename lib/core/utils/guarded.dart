import 'dart:async';

import 'package:air_reply/core/widgets/feedback.dart';
import 'package:flutter/widgets.dart';

/// Runs [action] and shows any failure; for callbacks of plain buttons and switches.
Future<void> runGuarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (e) {
    if (context.mounted) context.showError(e);
  }
}

/// Fires [action] without awaiting it, reporting failures (for `onPressed`).
VoidCallback guarded(BuildContext context, Future<void> Function() action) =>
    () => unawaited(runGuarded(context, action));
