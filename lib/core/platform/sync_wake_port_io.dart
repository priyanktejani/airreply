import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

/// Lets another isolate in the same process (the push handler) nudge the running sync isolate, via
/// [IsolateNameServer], without needing the app's own platform channels.
abstract final class SyncWakePort {
  static const _name = 'air_reply.sync_wake';

  /// Called by the sync isolate; [onWake] runs whenever another isolate calls [wake].
  static StreamSubscription<Object?> register(void Function() onWake) {
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_name);
    IsolateNameServer.registerPortWithName(port.sendPort, _name);
    return port.listen((_) => onWake());
  }

  /// Returns false when no sync isolate is running in this process.
  static bool wake() {
    final port = IsolateNameServer.lookupPortByName(_name);
    port?.send(null);
    return port != null;
  }
}
