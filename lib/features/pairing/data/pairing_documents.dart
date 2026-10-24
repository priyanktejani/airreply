import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/firebase/server_time.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';

/// The pairing documents as plain maps, shared by the FlutterFire and REST repositories so both write exactly what
/// `firestore.rules` expects.
abstract final class PairingDocuments {
  static Map<String, Object?> waitingSession({
    required String senderUid,
    required String senderName,
    required Uint8List senderPublicKey,
    required DateTime expiresAt,
  }) => {
    'status': PairingStatus.waiting.name,
    'senderUid': senderUid,
    'senderName': senderName,
    'senderPublicKey': base64.encode(senderPublicKey),
    'createdAt': ServerTime.value,
    'expiresAt': expiresAt,
  };

  static Map<String, Object?> joined({
    required String receiverUid,
    required String receiverName,
    required Uint8List receiverPublicKey,
  }) => {
    'status': PairingStatus.joined.name,
    'receiverUid': receiverUid,
    'receiverName': receiverName,
    'receiverPublicKey': base64.encode(receiverPublicKey),
  };

  static Map<String, Object?> confirmed(String pairId) => {'status': PairingStatus.confirmed.name, 'pairId': pairId};

  static Map<String, Object?> pair(PairingSession session) => {
    'senderUid': session.senderUid,
    'receiverUid': session.receiverUid,
    'members': [session.senderUid, session.receiverUid],
    'senderName': session.senderName,
    'receiverName': session.receiverName,
    'sessionCode': session.code,
    'active': true,
    'createdAt': ServerTime.value,
  };

  static Map<String, Object?> deactivated() => {'active': false, 'deactivatedAt': ServerTime.value};

  static Map<String, Object?> pushToken(DeviceRole role, String token, String platform) => {
    '${role.name}Token': token,
    '${role.name}Platform': platform,
  };

  static bool isActive(Map<String, Object?>? pair) => pair != null && pair['active'] != false;

  /// [data] uses DateTime for timestamps. Null when the document does not exist.
  static PairingSession? session(String code, Map<String, Object?>? data) {
    if (data == null) return null;
    final receiverKey = data['receiverPublicKey'] as String?;
    return PairingSession(
      code: code,
      status: PairingStatus.parse(data['status']),
      senderUid: data['senderUid']! as String,
      senderName: (data['senderName'] as String?) ?? 'Phone',
      senderPublicKey: base64.decode(data['senderPublicKey']! as String),
      expiresAt: data['expiresAt']! as DateTime,
      receiverUid: data['receiverUid'] as String?,
      receiverName: data['receiverName'] as String?,
      receiverPublicKey: receiverKey == null ? null : base64.decode(receiverKey),
      pairId: data['pairId'] as String?,
    );
  }

  /// [session] after [joined] was applied to it.
  static PairingSession withReceiver(
    PairingSession session, {
    required String receiverUid,
    required String receiverName,
    required Uint8List receiverPublicKey,
  }) => PairingSession(
    code: session.code,
    status: PairingStatus.joined,
    senderUid: session.senderUid,
    senderName: session.senderName,
    senderPublicKey: session.senderPublicKey,
    expiresAt: session.expiresAt,
    receiverUid: receiverUid,
    receiverName: receiverName,
    receiverPublicKey: receiverPublicKey,
  );
}
