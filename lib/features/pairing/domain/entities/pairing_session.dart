import 'dart:typed_data';

/// Lifecycle of a pairing session document.
enum PairingStatus {
  /// Sender is showing the code / QR.
  waiting,

  /// A receiver joined with its public key; both screens now show the verification code.
  joined,

  /// The sender confirmed the codes match and created the pair.
  confirmed,

  cancelled;

  static PairingStatus parse(Object? value) =>
      PairingStatus.values.firstWhere((s) => s.name == value, orElse: () => PairingStatus.cancelled);
}

/// The short-lived handshake between a sender and a receiver, identified by its 6-digit [code].
final class PairingSession {
  const PairingSession({
    required this.code,
    required this.status,
    required this.senderUid,
    required this.senderName,
    required this.senderPublicKey,
    required this.expiresAt,
    this.receiverUid,
    this.receiverName,
    this.receiverPublicKey,
    this.pairId,
  });

  static const lifetime = Duration(minutes: 10);

  final String code;
  final PairingStatus status;
  final String senderUid;
  final String senderName;
  final Uint8List senderPublicKey;
  final DateTime expiresAt;
  final String? receiverUid;
  final String? receiverName;
  final Uint8List? receiverPublicKey;
  final String? pairId;

  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);
}
