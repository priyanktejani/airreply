import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';

/// A device that was removed, whose history this device kept. Its [credentials] keep the pair's key, here only, so the
/// history (still sealed with it) can be read, moved into a new pair with the same device, or deleted.
final class ArchivedPair {
  const ArchivedPair(this.credentials, {required this.unpairedAt});

  factory ArchivedPair.fromJson(Map<String, Object?> json) => ArchivedPair(
    PairingCredentials.fromJson((json['pair']! as Map).cast<String, Object?>()),
    unpairedAt: DateTime.fromMillisecondsSinceEpoch((json['unpairedAt']! as num).toInt()),
  );

  final PairingCredentials credentials;
  final DateTime unpairedAt;

  String get pairId => credentials.pairId;
  String get peerName => credentials.peerName;

  /// Whether [pair] is the same device in the same role, paired again.
  bool continuesIn(PairingCredentials pair) =>
      credentials.peerUid != null && credentials.peerUid == pair.peerUid && credentials.role == pair.role;

  Map<String, Object?> toJson() => {'pair': credentials.toJson(), 'unpairedAt': unpairedAt.millisecondsSinceEpoch};
}
