import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';

/// One notification as the receiver's feed knows it: the decrypted [content] plus the plain sync flags.
final class MirroredNotification {
  const MirroredNotification({
    required this.id,
    required this.content,
    required this.canReply,
    required this.dismissedOnSender,
  });

  final String id;
  final NotificationContent content;

  /// The source notification has a `RemoteInput` action.
  final bool canReply;

  /// The source notification is gone from the sender's status bar, so its reply action is gone too. The receiver
  /// keeps it in history.
  final bool dismissedOnSender;

  DateTime get postedAt => content.postedAt;

  bool get acceptsReplies => canReply && !dismissedOnSender;
}
