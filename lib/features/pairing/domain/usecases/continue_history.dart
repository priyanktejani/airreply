import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/archived_pairs_store.dart';

/// A device paired again picks up where it left off: the history kept when it was removed (see `Unpair`) moves into
/// the new pair, so the inbox, its chats and search show it as before.
final class ContinueHistory {
  const ContinueHistory(this._archive, {required this._moveHistory});

  final ArchivedPairsStore _archive;

  /// Moves one removed pair's history into the new pair; returns the ids of the notifications moved.
  final Future<List<String>> Function(PairingCredentials from, PairingCredentials to) _moveHistory;

  /// Returns the ids of the notifications that joined [pair].
  Future<List<String>> call(PairingCredentials pair) async {
    final moved = <String>[];
    for (final old in await _archive.readAll()) {
      if (!old.continuesIn(pair)) continue;
      try {
        moved.addAll(await _moveHistory(old.credentials, pair));
        await _archive.remove(old.pairId);
      } on Object catch (e) {
        // still kept under Previous devices; what moved already stays moved
        appLog('Could not continue the history of ${old.pairId}: $e', name: 'air_reply.pairing');
      }
    }
    return moved;
  }
}
