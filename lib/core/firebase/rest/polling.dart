import 'dart:async';
import 'dart:math';

import 'package:air_reply/core/logging/app_log.dart';

/// A stream that calls [fetch] every [every] while it has a listener, and emits each non-null result.
///
/// [fetch] returns null for "nothing changed", so incremental pollers emit only real changes. Errors before the
/// first value are reported (the screen can show them); later ones are logged and retried with exponential backoff,
/// keeping the last good value on screen.
Stream<T> pollingStream<T>(
  Future<T?> Function() fetch, {
  required Duration every,
  Duration maxBackoff = const Duration(minutes: 1),
}) {
  late final StreamController<T> controller;
  Timer? timer;
  var active = false;
  var emitted = false;
  var failures = 0;

  Future<void> tick() async {
    if (!active) return;
    try {
      final value = await fetch();
      failures = 0;
      if (active && value != null) {
        emitted = true;
        controller.add(value);
      }
    } on Object catch (e, st) {
      failures++;
      if (active && !emitted && failures == 1) controller.addError(e, st);
      appLog('Poll failed ($failures)', error: e, name: 'air_reply.poll');
    }
    if (!active) return;
    final backoff = every * pow(2, min(failures, 6)).toInt();
    timer = Timer(failures == 0 ? every : (backoff > maxBackoff ? maxBackoff : backoff), tick);
  }

  controller = StreamController<T>(
    onListen: () {
      active = true;
      unawaited(tick());
    },
    onCancel: () {
      active = false;
      timer?.cancel();
    },
  );
  return controller.stream;
}
