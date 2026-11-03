import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The time, updated as each minute turns: watch it so relative times ("5m"), "Last synced" and today's counts stay
/// current while a screen stays open. Its timer runs only while something watches it.
final clockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final ticks = StreamController<DateTime>();
  Timer? timer;
  void next() {
    final now = DateTime.now();
    timer = Timer(Duration(seconds: 60 - now.second, milliseconds: -now.millisecond), () {
      ticks.add(DateTime.now());
      next();
    });
  }

  ticks.add(DateTime.now());
  next();
  ref.onDispose(() {
    timer?.cancel();
    unawaited(ticks.close());
  });
  return ticks.stream;
});
