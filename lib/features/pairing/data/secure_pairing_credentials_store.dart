import 'dart:convert';

import 'package:air_reply/core/storage/secret_store.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';

/// Keeps every pair's credentials, as one JSON list, in the OS secret store. On the Android sender the headless sync
/// isolate reads the same entry, since it runs in the same process.
final class SecurePairingCredentialsStore implements PairingCredentialsStore {
  SecurePairingCredentialsStore(this._secrets);

  static const _key = 'air_reply.pairs.v2';

  final SecretStore _secrets;

  @override
  Future<List<PairingCredentials>> readAll() async {
    final raw = await _secrets.read(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<Object?>)
          PairingCredentials.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } on Object {
      // Unreadable (restored backup without the OS key): treat as unpaired rather than crash.
      await _secrets.delete(_key);
      return const [];
    }
  }

  @override
  Future<void> save(PairingCredentials credentials) async =>
      _write([...(await readAll()).where((c) => c.pairId != credentials.pairId), credentials]);

  @override
  Future<void> remove(String pairId) async => _write([...(await readAll()).where((c) => c.pairId != pairId)]);

  Future<void> _write(List<PairingCredentials> pairs) =>
      pairs.isEmpty ? _secrets.delete(_key) : _secrets.write(_key, jsonEncode([for (final c in pairs) c.toJson()]));
}
