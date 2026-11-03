import 'dart:io';

import 'package:air_reply/core/logging/app_log.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:drift_flutter/drift_flutter.dart';

/// The history database file, encrypted with [hexKey] (SQLite3MultipleCiphers, selected in pubspec.yaml): notification
/// payloads, replies and the search index are unreadable without the key the system keystore holds.
QueryExecutor openHistory(Future<String> Function() hexKey) =>
    LazyDatabase(() async => driftDatabase(name: 'air_reply_history', native: historyOptions(await hexKey())));

/// How each connection to the history file starts, before drift reads anything from it:
///
/// * a new file: given the key, so it is created encrypted;
/// * plain SQLite (history kept before encryption): encrypted in place, nothing lost;
/// * encrypted with a key that is gone (the keystore was reset): it can never be read again, so it is emptied and
///   history starts afresh, rather than the app failing to open it.
///
/// Then write-ahead logging, so the app and the sender's background engine (a separate Flutter engine, with its own
/// connection) read and write at the same time, and a busy timeout so one waits for the other's write.
DriftNativeOptions historyOptions(String hexKey) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey)) throw ArgumentError('Not a history key');
  return DriftNativeOptions(
    setup: (db) {
      bool readable() {
        try {
          db.select('SELECT count(*) FROM sqlite_master');
          return true;
        } on SqliteException {
          return false;
        }
      }

      final plain = readable() && db.select('PRAGMA page_count').first.columnAt(0) as int > 0;
      if (plain) {
        try {
          // re-keying needs a rollback journal: the write-ahead log is folded in first
          db
            ..execute('PRAGMA journal_mode = DELETE')
            ..execute("PRAGMA hexrekey = '$hexKey'");
          appLog('History encrypted in place', name: 'air_reply.history');
        } on SqliteException catch (e) {
          // e.g. the other engine holds it mid-write: used as it is, and encrypted on a later start
          appLog('History not encrypted yet: $e', name: 'air_reply.history');
        }
      } else {
        db.execute("PRAGMA hexkey = '$hexKey'");
        if (!readable()) {
          _empty(db.select('PRAGMA database_list').first['file'] as String);
          db.execute("PRAGMA hexkey = '$hexKey'");
          appLog("History could not be opened with this device's key: started afresh", name: 'air_reply.history');
        }
      }
      db
        ..execute('PRAGMA journal_mode = WAL')
        ..execute('PRAGMA busy_timeout = 5000');
    },
  );
}

/// Empties the history file at [path] in place (the connection keeps it open), and drops its logs.
void _empty(String path) {
  if (path.isEmpty) return;
  for (final log in ['$path-wal', '$path-shm', '$path-journal']) {
    if (File(log).existsSync()) File(log).deleteSync();
  }
  File(path).openSync(mode: FileMode.write).closeSync();
}
