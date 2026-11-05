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
/// The app and the sender's background engine (a separate Flutter engine, with its own connection) use the file at
/// the same time, so a connection first waits up to [busyTimeoutMs] for the other's write, and only SQLite saying the
/// file is not a database, without the key and with it, counts as "the key is gone". A busy or locked file is never
/// taken for an unreadable one: emptying it then wiped the history the other engine was writing (and left it failing
/// with "file is not a database" until it restarted). Then write-ahead logging, so both read and write at once.
DriftNativeOptions historyOptions(String hexKey, {int busyTimeoutMs = 5000}) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey)) throw ArgumentError('Not a history key');
  return DriftNativeOptions(
    setup: (db) {
      // before anything reads the file: the other engine's write is waited for, not mistaken for damage
      db.execute('PRAGMA busy_timeout = $busyTimeoutMs');

      /// Null when the file can be read; else SQLite's primary result code.
      int? failure() {
        try {
          db.select('SELECT count(*) FROM sqlite_master');
          return null;
        } on SqliteException catch (e) {
          return e.resultCode;
        }
      }

      final unkeyed = failure();
      final plain = unkeyed == null && db.select('PRAGMA page_count').first.columnAt(0) as int > 0;
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
        final keyed = failure();
        if (unkeyed == _notADatabase && keyed == _notADatabase) {
          _empty(db.select('PRAGMA database_list').first['file'] as String);
          db.execute("PRAGMA hexkey = '$hexKey'");
          appLog("History could not be opened with this device's key: started afresh", name: 'air_reply.history');
        } else if (keyed != null) {
          // busy, locked, out of memory...: left as it is; the open fails now and is tried again later
          appLog('History not opened yet (SQLite $keyed)', name: 'air_reply.history');
        }
      }
      db.execute('PRAGMA journal_mode = WAL');
    },
  );
}

/// SQLITE_NOTADB: the file is not a database, as an encrypted one reads with no key or the wrong one.
const _notADatabase = 26;

/// Empties the history file at [path] in place (the connection keeps it open), and drops its logs.
void _empty(String path) {
  if (path.isEmpty) return;
  for (final log in ['$path-wal', '$path-shm', '$path-journal']) {
    if (File(log).existsSync()) File(log).deleteSync();
  }
  File(path).openSync(mode: FileMode.write).closeSync();
}
