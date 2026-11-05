import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/usecases/continue_history.dart';

/// Run as the app starts. Pairs made before devices recorded each other's sign-in id get it from the server (one read
/// each, once), so removing and pairing them again later is recognised; then every paired device takes back history
/// kept from an earlier pairing with it, including one made again before this ran.
final class RestoreKeptHistory {
  const RestoreKeptHistory(
    this._repository,
    this._store,
    this._continue, {
    this.serverTimeout = const Duration(seconds: 10),
  });

  final PairingRepository _repository;
  final PairingCredentialsStore _store;
  final ContinueHistory _continue;
  final Duration serverTimeout;

  /// Returns the ids of the notifications that came back, by pair.
  Future<Map<String, List<String>>> call() async {
    final pairs = <PairingCredentials>[];
    for (final pair in await _store.readAll()) {
      pairs.add(pair.peerUid == null ? await _recordPeer(pair) : pair);
    }
    final moved = <String, List<String>>{};
    for (final pair in pairs) {
      final ids = await _continue(pair);
      if (ids.isNotEmpty) moved[pair.pairId] = ids;
    }
    return moved;
  }

  Future<PairingCredentials> _recordPeer(PairingCredentials pair) async {
    try {
      final uid = await _repository.peerUidOf(pair.pairId).timeout(serverTimeout);
      if (uid == null) return pair;
      final known = pair.withPeerUid(uid);
      await _store.save(known);
      return known;
    } on Object catch (e) {
      // offline: tried again next start
      appLog('Peer of ${pair.pairId} not recorded yet: $e', name: 'air_reply.pairing');
      return pair;
    }
  }
}
