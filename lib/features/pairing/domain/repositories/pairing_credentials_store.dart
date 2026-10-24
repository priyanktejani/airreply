import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';

/// Local, secure persistence of every pair this device belongs to (a phone can share with several devices, and a
/// desktop can show several phones).
abstract interface class PairingCredentialsStore {
  Future<List<PairingCredentials>> readAll();

  /// Adds the pair, or replaces the one with the same pair id.
  Future<void> save(PairingCredentials credentials);

  Future<void> remove(String pairId);
}
