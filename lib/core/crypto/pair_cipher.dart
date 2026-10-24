import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_contracts.dart';

/// What a sealed payload is for. Part of the associated data, so a reply envelope can never be opened as a
/// notification (or the other way round).
enum CipherPurpose { notification, reply }

/// [PayloadCipher] bound to one pair's id and key, so callers never handle raw key bytes.
final class PairCipher {
  PairCipher({required this._cipher, required this.pairId, required this._key});

  final PayloadCipher _cipher;
  final Uint8List _key;
  final String pairId;

  final _indexCache = <String, Future<String>>{};

  Future<String> encrypt(Map<String, Object?> json, CipherPurpose purpose) =>
      _cipher.seal(json, key: _key, context: _context(purpose));

  Future<Map<String, Object?>> decrypt(String envelope, CipherPurpose purpose) =>
      _cipher.open(envelope, key: _key, context: _context(purpose));

  /// Same input, same output, for the lifetime of the pair: used to find every mirrored post of one notification.
  Future<String> blindIndex(String value) => _indexCache.putIfAbsent(value, () => _cipher.blindIndex(value, key: _key));

  String _context(CipherPurpose purpose) => '$pairId/${purpose.name}';
}
