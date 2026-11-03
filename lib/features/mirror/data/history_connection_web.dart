import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// The browser's own storage for this site, not encrypted: a key could only be kept in that same storage, so it would
/// protect nothing. [hexKey] is not used.
QueryExecutor openHistory(Future<String> Function() hexKey) => driftDatabase(
  name: 'air_reply_history',
  web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
);
