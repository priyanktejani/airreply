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

  /// Whether [pair] is the same device in the same role, paired again: the same sign-in id when both pairs know it;
  /// for a pair made before devices recorded each other's id, the same name. Two different ids are never the same
  /// device, so one person's history never joins another's on a shared computer.
  bool continuesIn(PairingCredentials pair) {
    if (credentials.role != pair.role) return false;
    final (before, now) = (credentials.peerUid, pair.peerUid);
    if (before != null && now != null) return before == now;
    return credentials.peerName.trim().toLowerCase() == pair.peerName.trim().toLowerCase();
  }

  Map<String, Object?> toJson() => {'pair': credentials.toJson(), 'unpairedAt': unpairedAt.millisecondsSinceEpoch};
}
