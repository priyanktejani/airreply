import 'dart:math';

import 'package:air_reply/core/storage/secret_store.dart';

/// The key the history database is encrypted with: 256 random bits, made on first use and kept by the system
/// keystore ([SecretStore]), never in the app's files. Every isolate (the app, the sender's background engine, a push
/// handler) reads the same one.
final class HistoryKey {
  HistoryKey(this._store, {Random? random}) : _random = random ?? Random.secure();

  static const _name = 'air_reply.history_key.v1';

  final SecretStore _store;
  final Random _random;

  /// The key as 64 hex digits.
  Future<String> hex() async {
    final kept = await _store.read(_name);
    if (kept != null) return kept;
    final made = [for (var i = 0; i < 32; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
    await _store.write(_name, made);
    // two isolates starting together could both make one: whichever was written last is the key for both
    return await _store.read(_name) ?? made;
  }
}
