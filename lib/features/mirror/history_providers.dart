import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/history_key.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// History on this device, apart from the rest of the mirror wiring so pairing can erase it without depending on sync.

/// One connection per isolate (the app, the sender's background engine, a push handler), closed with its container.
final historyDatabaseProvider = Provider<HistoryDatabase>((ref) {
  final key = HistoryKey(ref.watch(secretStoreProvider));
  final db = HistoryDatabase.open(key.hex);
  ref.onDispose(db.close);
  return db;
});

/// One pair's history on this device: messages live here, not on the server.
final messageHistoryProvider = Provider.family<MessageHistory, String>(
  (ref, pairId) =>
      MessageHistory(ref.watch(historyDatabaseProvider), pairId, legacy: ref.watch(sharedPreferencesProvider)),
);

/// Deletes one pair's history on this device, when the pair ends.
final eraseHistoryProvider = Provider<Future<void> Function(String pairId)>(
  (ref) =>
      (pairId) => ref.read(messageHistoryProvider(pairId)).erase(),
);
