import 'dart:convert';

import 'package:air_reply/core/storage/secret_store.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';

/// [PendingJoinStore] in the platform keystore: it holds the key agreed with the sender.
final class SecurePendingJoinStore implements PendingJoinStore {
  SecurePendingJoinStore(this._secrets);

  static const _key = 'air_reply.pending_join.v1';

  final SecretStore _secrets;

  @override
  Future<PendingJoin?> read() async {
    final raw = await _secrets.read(_key);
    if (raw == null) return null;
    try {
      return PendingJoin.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(PendingJoin join) => _secrets.write(_key, jsonEncode(join.toJson()));

  @override
  Future<void> clear() => _secrets.delete(_key);
}
