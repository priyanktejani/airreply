import 'dart:async';
import 'dart:math';

import 'package:air_reply/core/logging/app_log.dart';

/// A stream that calls [fetch] every [every] while it has a listener, and emits each non-null result.
///
/// [fetch] returns null for "nothing changed", so incremental pollers emit only real changes. Errors before the
/// first value are reported (the screen can show them); later ones are logged and retried with exponential backoff,
/// keeping the last good value on screen.
///
/// Each event of [wake] fetches at once (a doorbell rang); [slower] may stretch the wait between fetches meanwhile
/// (a live doorbell makes frequent fetches pointless).
Stream<T> pollingStream<T>(
  Future<T?> Function() fetch, {
  required Duration every,
  Duration maxBackoff = const Duration(minutes: 1),
  Stream<void>? wake,
  Duration? Function()? slower,
}) {
  late final StreamController<T> controller;
  StreamSubscription<void>? wakes;
  Timer? timer;
  var active = false;
  var running = false;
  var again = false;
  var emitted = false;
  var failures = 0;

  Future<void> tick() async {
    if (!active) return;
    timer?.cancel();
    running = true;
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
    } finally {
      running = false;
    }
    if (!active) return;
    if (again) {
      // woken while fetching: what woke it may have come after that fetch read
      again = false;
      unawaited(tick());
      return;
    }
    final backoff = every * pow(2, min(failures, 6)).toInt();
    timer = Timer(failures == 0 ? (slower?.call() ?? every) : (backoff > maxBackoff ? maxBackoff : backoff), tick);
  }

  controller = StreamController<T>(
    onListen: () {
      active = true;
      wakes = wake?.listen((_) => running ? again = true : unawaited(tick()));
      unawaited(tick());
    },
    onCancel: () {
      active = false;
      timer?.cancel();
      unawaited(wakes?.cancel());
    },
  );
  return controller.stream;
}
