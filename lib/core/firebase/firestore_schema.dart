/// Collection and field names shared by the app, `firestore.rules` and the Cloud Functions. Keep the three in step.
///
/// ```
/// pairingSessions/{code}                 short-lived handshake (TTL on expiresAt)
/// pairs/{pairId}                         members, names, push tokens, active
///   notifications/{id}                   { payload: <AES-GCM envelope>, keyHash, canReply, dismissedOnSender, postedAt }
///   replies/{id}                         { notificationId, payload: <AES-GCM envelope>, status, createdAt, updatedAt }
/// ```
abstract final class FirestoreSchema {
  static const pairingSessions = 'pairingSessions';
  static const pairs = 'pairs';
  static const notifications = 'notifications';
  static const replies = 'replies';
}
