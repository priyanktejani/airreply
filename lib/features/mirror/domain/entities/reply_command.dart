/// Delivery state of a reply, as the sender reports it back. [wire] is the value stored in Firestore.
enum ReplyStatus {
  pending('PENDING'),
  sent('SENT'),

  /// The notification was dismissed on the sender before the reply arrived.
  expired('FAILED_EXPIRED'),
  failed('FAILED');

  const ReplyStatus(this.wire);

  final String wire;

  bool get isFinal => this != pending;

  static ReplyStatus parse(Object? wire) =>
      ReplyStatus.values.firstWhere((s) => s.wire == wire, orElse: () => ReplyStatus.failed);
}

/// A reply written by the receiver, as its feed shows it.
final class ReplyCommand {
  const ReplyCommand({
    required this.id,
    required this.notificationId,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String notificationId;
  final String text;
  final ReplyStatus status;
  final DateTime createdAt;
}

/// A reply the sender still has to execute, decrypted.
final class PendingReply {
  const PendingReply({
    required this.id,
    required this.notificationId,
    required this.notificationKey,
    required this.text,
  });

  final String id;
  final String notificationId;

  /// `StatusBarNotification` key whose cached `RemoteInput` action to fire.
  final String notificationKey;
  final String text;
}
