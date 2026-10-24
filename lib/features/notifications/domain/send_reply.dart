import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';

/// Queues a reply to a mirrored notification on the pair it came from; that phone executes it and reports the status.
final class SendReply {
  const SendReply(this._outbox);

  static const maxLength = 2000;

  final ReplyOutbox _outbox;

  Future<void> call(MirroredNotification notification, String text) {
    final reply = text.trim();
    if (reply.isEmpty) throw const ValidationException('Type a reply first.');
    if (reply.length > maxLength) throw const ValidationException('That reply is too long.');
    if (!notification.canReply) throw const ValidationException('This notification cannot be answered.');
    if (notification.dismissedOnSender) {
      throw const ValidationException(
        'This notification was dismissed on your phone, so it can no longer be answered.',
      );
    }
    return _outbox.send(notificationId: notification.id, notificationKey: notification.content.key, text: reply);
  }
}
