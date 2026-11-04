import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';

/// Everything a device keeps after pairing. The [sharedKey] never leaves the device (Keystore / Keychain).
final class PairingCredentials {
  const PairingCredentials({
    required this.pairId,
    required this.role,
    required this.sharedKey,
    required this.peerName,
    required this.pairedAt,
    this.peerUid,
  });

  factory PairingCredentials.fromJson(Map<String, Object?> json) => PairingCredentials(
    pairId: json['pairId']! as String,
    role: DeviceRole.tryParse(json['role'] as String?) ?? DeviceRole.receiver,
    sharedKey: base64.decode(json['key']! as String),
    peerName: (json['peerName'] as String?) ?? 'Paired device',
    pairedAt: DateTime.fromMillisecondsSinceEpoch((json['pairedAt']! as num).toInt()),
    peerUid: json['peerUid'] as String?,
  );

  final String pairId;
  final DeviceRole role;
  final Uint8List sharedKey;
  final String peerName;
  final DateTime pairedAt;

  /// The other device's sign-in id, the same every time it pairs (until its app data is cleared): how pairing it again
  /// finds the history kept from before. Null for pairs made before it was recorded.
  final String? peerUid;

  Map<String, Object?> toJson() => {
    'pairId': pairId,
    'role': role.name,
    'key': base64.encode(sharedKey),
    'peerName': peerName,
    'pairedAt': pairedAt.millisecondsSinceEpoch,
    'peerUid': ?peerUid,
  };
}
