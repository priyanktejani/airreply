import 'package:air_reply/background/sender_sync_entrypoint.dart';
import 'package:air_reply/bootstrap.dart';

Future<void> main() => bootstrap();

/// Entry point of the sender's headless sync engine, started natively by `BackgroundSyncEngine.kt` while the
/// foreground service runs. Must stay a top-level function in main.dart, annotated so release builds keep it.
@pragma('vm:entry-point')
Future<void> backgroundMain() => runSenderSync();
