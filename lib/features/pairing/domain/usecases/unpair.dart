import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// Ends one pair on this device and tells the other device. The backend then deletes that pair's history. Other
/// pairs of this device are untouched.
final class Unpair {
  const Unpair(this._repository, this._store, this._bridge, {this._eraseHistory});

  final PairingRepository _repository;
  final PairingCredentialsStore _store;
  final NotificationBridge _bridge;

  /// Deletes the pair's history on this device: sealed with the pair's key, it could never be read again.
  final Future<void> Function(String pairId)? _eraseHistory;

  /// [notifyPeer] is false when the other device already ended the pair.
  Future<void> call(String pairId, {bool notifyPeer = true}) async {
    final pairs = await _store.readAll();
    final ended = pairs.where((p) => p.pairId == pairId).firstOrNull;
    if (ended == null) return;

    if (notifyPeer) {
      try {
        await _repository.deactivatePair(pairId);
      } on Object {
        // Offline: the local key is wiped anyway, so this device can no longer read or write the pair.
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
