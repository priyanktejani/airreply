// Isolates exist on the Dart VM only; the web gets a no-op.
export 'sync_wake_port_stub.dart' if (dart.library.isolate) 'sync_wake_port_io.dart';
