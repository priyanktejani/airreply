import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/archived_pairs_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';

/// Ends one pair, and removes what it kept on the server: its waiting messages, the pair itself and its doorbell. On
/// this device the pair stops syncing, and its history is kept (with the key that opens it) as a previous device,
/// until it is deleted or the same device pairs again (see `ContinueHistory`). The other device notices and does the
/// same. Other pairs of this device are untouched.
final class Unpair {
  const Unpair(
    this._repository,
    this._store,
    this._bridge, {
    this._eraseHistory,
    this._removeDoorbell,
    this._archive,
    this._historySize,
    this.serverTimeout = const Duration(seconds: 10),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The server's part never holds unpairing up: offline, its writes wait for the connection (Firestore keeps them),
  /// and what cannot be removed is sealed with a key no device holds any more.
  final Duration serverTimeout;

  final PairingRepository _repository;
  final PairingCredentialsStore _store;
  final NotificationBridge _bridge;

  /// Deletes the pair's history on this device: used when there is none worth keeping.
  final Future<void> Function(String pairId)? _eraseHistory;

  /// Where a removed device's history is kept, with the key that opens it (see [ArchivedPair]).
  final ArchivedPairsStore? _archive;

  /// How much history the pair left on this device.
  final Future<({int notifications, int replies})> Function(String pairId)? _historySize;

  final DateTime Function() _clock;

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
    // The history stays on this device, as in WhatsApp: kept with its key (before the key leaves the active pairs), to
    // be read under Previous devices, continued if the same device pairs again, or deleted.
    var kept = false;
    try {
      final size = await _historySize?.call(pairId);
      if (_archive != null && size != null && size.notifications + size.replies > 0) {
        await _archive.save(ArchivedPair(ended, unpairedAt: _clock()));
        kept = true;
      }
    } on Object catch (e) {
      appLog('Could not keep the history of $pairId: $e', name: 'air_reply.pairing');
    }
    await _store.remove(pairId);
    if (!kept) {
      try {
        await _eraseHistory?.call(pairId);
      } on Object catch (e) {
        // The key is gone, so what is left can never be read: unpairing still succeeds.
        appLog('Could not erase the history of $pairId: $e', name: 'air_reply.pairing');
      }
    }

    // Last: when this runs inside the background engine (a phone sharing, or an Android receiver receiving while
    // the app is closed), both calls replace that engine.
    if (_bridge.isSupported) {
      pairs.length == 1 ? await _bridge.stopSync() : await _bridge.reloadSync();
    }
  }
}
