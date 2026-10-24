import 'dart:async';

/// Web build of [SyncWakePort]: there is no sender sync isolate to wake.
abstract final class SyncWakePort {
  static StreamSubscription<Object?> register(void Function() onWake) => const Stream<Object?>.empty().listen(null);

  static bool wake() => false;
}
