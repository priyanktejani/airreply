import 'dart:convert';

import 'package:air_reply/core/storage/secret_store.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/pairing/domain/repositories/archived_pairs_store.dart';

/// [ArchivedPairsStore] in the platform keystore, beside the active pairs: each one holds its pair's key.
final class SecureArchivedPairsStore implements ArchivedPairsStore {
  SecureArchivedPairsStore(this._secrets);

  static const _key = 'air_reply.archived_pairs.v1';

  final SecretStore _secrets;

  @override
  Future<List<ArchivedPair>> readAll() async {
    final raw = await _secrets.read(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<Object?>)
          ArchivedPair.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } on Object {
      // Unreadable (restored backup without the OS key): the history it kept can no longer be opened either.
      await _secrets.delete(_key);
      return const [];
    }
  }

  @override
  Future<void> save(ArchivedPair pair) async =>
      _write([...(await readAll()).where((p) => p.pairId != pair.pairId), pair]);

  @override
  Future<void> remove(String pairId) async => _write([...(await readAll()).where((p) => p.pairId != pairId)]);

  Future<void> _write(List<ArchivedPair> pairs) =>
      pairs.isEmpty ? _secrets.delete(_key) : _secrets.write(_key, jsonEncode([for (final p in pairs) p.toJson()]));
}
