import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/data/history_key.dart';
import 'package:air_reply/features/mirror/data/message_history.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
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

/// How much history one pair (active or removed) left on this device.
final historySizeProvider = Provider<Future<({int notifications, int replies})> Function(String pairId)>(
  (ref) =>
      (pairId) => ref.read(messageHistoryProvider(pairId)).size(),
);

/// Moves the history of a removed pair [from] into the new pair [to] with the same device, re-sealed with the new
/// pair's key. Returns the ids of the notifications moved.
final moveHistoryProvider = Provider<Future<List<String>> Function(PairingCredentials from, PairingCredentials to)>(
  (ref) => (from, to) {
    final cipher = ref.read(payloadCipherProvider);
    final old = PairCipher(cipher: cipher, pairId: from.pairId, key: from.sharedKey);
    final next = PairCipher(cipher: cipher, pairId: to.pairId, key: to.sharedKey);
    return ref
        .read(messageHistoryProvider(from.pairId))
        .moveTo(
          to.pairId,
          reseal: (payload, {required reply}) async {
            final purpose = reply ? CipherPurpose.reply : CipherPurpose.notification;
            try {
              return await next.encrypt(await old.decrypt(payload, purpose), purpose);
            } on Object catch (e) {
              appLog('Dropping a history entry that cannot be opened: $e', name: 'air_reply.history');
              return null;
            }
          },
        );
  },
);

/// Deletes every pair's history on this device.
final eraseAllHistoryProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(historyDatabaseProvider).eraseAll(),
);

/// Deletes one pair's history on this device.
final eraseHistoryProvider = Provider<Future<void> Function(String pairId)>(
  (ref) =>
      (pairId) => ref.read(messageHistoryProvider(pairId)).erase(),
);
