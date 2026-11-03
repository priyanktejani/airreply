/// Collection and field names shared by the app, `firestore.rules` and the Cloud Functions. Keep the three in step.
///
/// ```
/// pairingSessions/{code}                 short-lived handshake (TTL on expiresAt)
/// pairs/{pairId}                         members, names, push tokens, active
///   notifications/{id}                   { payload: <AES-GCM envelope>, keyHash, canReply, postedAt, expireAt }
///   replies/{id}                         { notificationId, payload: <AES-GCM envelope>, status, createdAt, expireAt }
///   dismissals/{id}                      { keyHash, at, expireAt }
/// ```
///
/// The collections under a pair are mailboxes: the receiving device keeps each document on the device, then deletes
/// it (a reply once the sender has reported how it went). `expireAt` lets a TTL policy remove what is never picked up.
abstract final class FirestoreSchema {
  static const pairingSessions = 'pairingSessions';
  static const pairs = 'pairs';
  static const notifications = 'notifications';
  static const replies = 'replies';
  static const dismissals = 'dismissals';
}
