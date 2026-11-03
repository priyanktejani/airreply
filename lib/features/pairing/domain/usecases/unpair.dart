import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// Ends one pair, and removes what it kept: on the server its waiting messages, the pair itself and its doorbell; on
/// this device its key and its history. The other device notices and removes its own copy. Other pairs of this device
/// are untouched.
final class Unpair {
  const Unpair(
    this._repository,
    this._store,
    this._bridge, {
    this._eraseHistory,
    this._removeDoorbell,
    this.serverTimeout = const Duration(seconds: 10),
  });

  /// The server's part never holds unpairing up: offline, its writes wait for the connection (Firestore keeps them),
  /// and what cannot be removed is sealed with a key no device holds any more.
  final Duration serverTimeout;

  final PairingRepository _repository;
  final PairingCredentialsStore _store;
  final NotificationBridge _bridge;

  /// Deletes the pair's history on this device: sealed with the pair's key, it could never be read again.
  final Future<void> Function(String pairId)? _eraseHistory;

  /// Takes the pair's doorbell away (see Doorbell).
  final Future<void> Function(PairingCredentials pair)? _removeDoorbell;

  /// [notifyPeer] is false when the other device already ended the pair.
  Future<void> call(String pairId, {bool notifyPeer = true}) async {
    final pairs = await _store.readAll();
    final ended = pairs.where((p) => p.pairId == pairId).firstOrNull;
    if (ended == null) return;

    if (notifyPeer) {
      try {
        await _repository.endPair(pairId).timeout(serverTimeout);
      } on Object catch (e) {
        // Offline: the local key is wiped anyway, so this device can no longer read or write the pair.
        appLog('Pair $pairId not ended on the server yet: $e', name: 'air_reply.pairing');
      }
      try {
        await _removeDoorbell?.call(ended).timeout(serverTimeout);
      } on Object catch (e) {
        appLog('Doorbell of $pairId not removed: $e', name: 'air_reply.pairing');
      }
    }
    await _store.remove(pairId);
    try {
      await _eraseHistory?.call(pairId);
    } on Object catch (e) {
      // The key is gone, so what is left can never be read: unpairing still succeeds.
      appLog('Could not erase the history of $pairId: $e', name: 'air_reply.pairing');
    }

    // Last: when this runs inside the sender's sync engine, both calls replace that engine.
    if (ended.role == DeviceRole.sender && _bridge.isSupported) {
      pairs.length == 1 ? await _bridge.stopSync() : await _bridge.reloadSync();
    }
  }
}
