import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/firebase/server_time.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';

/// Builds and reads the documents of one pair's `notifications`, `replies` and `dismissals`, sealing and opening the
/// encrypted payloads. Shared by every transport, so they all write exactly what `firestore.rules` expects.
///
/// Maps use DateTime for timestamps and [ServerTime] for server-set ones; each transport converts. Every document
/// carries `expireAt`, when the server's TTL policy deletes it if it was never delivered.
final class MirrorDocuments {
  MirrorDocuments(this._cipher, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// How long the server keeps a message the other device never picked up (WhatsApp keeps them 30 days too).
  static const mailboxRetention = Duration(days: 30);

  final PairCipher _cipher;
  final DateTime Function() _clock;

  // Mirrored content never changes after it is written, so each document is decrypted once per session.
  final _contents = <String, NotificationContent?>{};
  final _replies = <String, ({String key, String text})?>{};

  // ------------------------------------------------------------------ writing

  Future<Map<String, Object?>> notification(NotificationContent content, {required bool canReply}) async => {
    'payload': await _cipher.encrypt(content.toJson(), CipherPurpose.notification),
    'keyHash': await keyHash(content.key),
    'canReply': canReply,
    'dismissedOnSender': false,
    'postedAt': content.postedAt,
    'createdAt': ServerTime.value,
    'updatedAt': ServerTime.value,
    'expireAt': _expiry(),
  };

  /// The sender's notification [keyHash] left its status bar [at]: every message of it up to then can no longer be
  /// answered.
  Map<String, Object?> dismissal(String keyHash, DateTime at) => {
    'keyHash': keyHash,
    'at': at,
    'createdAt': ServerTime.value,
    'expireAt': _expiry(),
  };

  /// Finds every mirrored post of one source notification without revealing its key.
  Future<String> keyHash(String notificationKey) => _cipher.blindIndex(notificationKey);

  Future<Map<String, Object?>> reply({
    required String notificationId,
    required String notificationKey,
    required String text,
  }) async => {
    'notificationId': notificationId,
    'payload': await _cipher.encrypt({'k': notificationKey, 't': text}, CipherPurpose.reply),
    'status': ReplyStatus.pending.wire,
    'createdAt': _clock(),
    'updatedAt': ServerTime.value,
    'expireAt': _expiry(),
  };

  static Map<String, Object?> resolved(ReplyStatus status) => {'status': status.wire, 'updatedAt': ServerTime.value};

  DateTime _expiry() => _clock().add(mailboxRetention);

  // ------------------------------------------------------------------ reading

  /// Null when the document cannot be opened with this pair's key.
  Future<MirroredNotification?> readNotification(String id, Map<String, Object?> data) async {
    final content = await _open(id, data['payload'] as String?);
    if (content == null) return null;
    return MirroredNotification(
      id: id,
      content: content,
      canReply: data['canReply'] == true,
      dismissedOnSender: data['dismissedOnSender'] == true,
    );
  }

  /// The copy of a notification carried inside a push.
  Future<MirroredNotification?> readPushed({required String id, required String payload, required bool canReply}) =>
      readNotification(id, {'payload': payload, 'canReply': canReply});

  Future<ReplyCommand?> readReply(String id, Map<String, Object?> data) async {
    final body = await _openReply(id, data['payload'] as String?);
    if (body == null) return null;
    return ReplyCommand(
      id: id,
      notificationId: data['notificationId'] as String? ?? '',
      text: body.text,
      status: ReplyStatus.parse(data['status']),
      createdAt: data['createdAt'] as DateTime? ?? _clock(),
    );
  }

  /// Null when the reply was not made with this pair's key: it can never be executed.
  Future<PendingReply?> readPending(String id, Map<String, Object?> data) async {
    final body = await _openReply(id, data['payload'] as String?);
    if (body == null) return null;
    return PendingReply(
      id: id,
      notificationId: data['notificationId'] as String? ?? '',
      notificationKey: body.key,
      text: body.text,
    );
  }

  Future<NotificationContent?> _open(String id, String? payload) async {
    if (_contents.containsKey(id)) return _contents[id];
    NotificationContent? content;
    try {
      if (payload != null) {
        content = NotificationContent.fromJson(await _cipher.decrypt(payload, CipherPurpose.notification));
      }
    } on Object catch (e) {
      appLog('Skipping notification $id: $e', name: 'air_reply.sync');
    }
    return _contents[id] = content;
  }

  Future<({String key, String text})?> _openReply(String id, String? payload) async {
    if (_replies.containsKey(id)) return _replies[id];
    ({String key, String text})? body;
    try {
      if (payload != null) {
        final json = await _cipher.decrypt(payload, CipherPurpose.reply);
        body = (key: json['k']! as String, text: json['t']! as String);
      }
    } on Object catch (e) {
      appLog('Skipping reply $id: $e', name: 'air_reply.sync');
    }
    return _replies[id] = body;
  }
}
