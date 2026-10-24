import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';

/// Where this install stands: which role it plays, whether the sender disclosure was accepted, and the devices it
/// is paired with. The router derives every screen from this one value.
final class DeviceSession {
  const DeviceSession({this.role, this.disclosureAccepted = false, this.pairs = const []});

  static const fresh = DeviceSession();

  final DeviceRole? role;

  /// The sender accepted the Play "prominent disclosure" for notification access.
  final bool disclosureAccepted;

  /// Every pair of this device; all share its [role]. A phone can share with several devices, and a desktop can
  /// show several phones.
  final List<PairingCredentials> pairs;

  bool get isPaired => pairs.isNotEmpty;

  PairingCredentials? pair(String pairId) => pairs.where((p) => p.pairId == pairId).firstOrNull;

  DeviceSession withRole(DeviceRole? role) =>
      DeviceSession(role: role, disclosureAccepted: disclosureAccepted, pairs: pairs);

  DeviceSession withDisclosureAccepted() => DeviceSession(role: role, disclosureAccepted: true, pairs: pairs);

  /// Adds the pair, or replaces the one with the same id.
  DeviceSession withPair(PairingCredentials credentials) => DeviceSession(
    role: credentials.role,
    disclosureAccepted: disclosureAccepted,
    pairs: [...pairs.where((p) => p.pairId != credentials.pairId), credentials],
  );

  DeviceSession withoutPair(String pairId) => DeviceSession(
    role: role,
    disclosureAccepted: disclosureAccepted,
    pairs: [...pairs.where((p) => p.pairId != pairId)],
  );
}
