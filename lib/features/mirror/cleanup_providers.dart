import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/features/mirror/data/doorbell.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// What a pair leaves outside this device's history, removed when it ends. Apart from the rest of the mirror wiring so
// pairing can use it without depending on sync.

/// Takes a pair's doorbell out of the Realtime Database (see [Doorbell]); nothing to do without one.
final removeDoorbellProvider = Provider<Future<void> Function(PairingCredentials pair)>(
  (ref) => (pair) async {
    final config = ref.read(firebaseRestConfigProvider);
    if (!config.hasDatabase) return;
    final cipher = PairCipher(cipher: ref.read(payloadCipherProvider), pairId: pair.pairId, key: pair.sharedKey);
    await Doorbell(
      config: config,
      client: ref.read(httpClientProvider),
      idToken: ref.read(authGatewayProvider).idToken,
      name: () => Doorbell.nameFor(cipher),
    ).remove();
  },
);
