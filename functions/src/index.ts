/**
 * AirReply push relay.
 *
 * The apps cannot push to each other directly (FCM sends need server credentials), so these triggers turn
 * Firestore writes into pushes. They never decrypt anything: payloads are AES-GCM ciphertext made with a key only
 * the two devices hold, and are forwarded as-is.
 *
 *   pairs/{pairId}/notifications/{id} created -> receiver: `type: notification` (+ the ciphertext when it fits)
 *   pairs/{pairId}/replies/{id} created       -> sender:   `type: reply` (high priority: wakes it from Doze)
 *   pairs/{pairId} active -> false            -> delete the pair and its history
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging, type Message } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';

initializeApp();
const db = getFirestore();

/** FCM data messages are capped at 4 KB in total; keep room for the other keys. */
const MAX_INLINE_PAYLOAD = 3000;

type Role = 'sender' | 'receiver';

interface Alert {
  title: string;
  body: string;
}

const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/**
 * Sends a data push to one member of an active pair.
 *
 * Android gets data only, so the app decrypts and shows the real content itself. iOS cannot run code reliably for
 * data-only pushes, so an [alert] (generic text: the server cannot read the content) is shown there instead.
 */
async function pushTo(pairId: string, role: Role, data: Record<string, string>, alert?: Alert): Promise<void> {
  const pairRef = db.doc(`pairs/${pairId}`);
  const pair = (await pairRef.get()).data();
  if (!pair || pair.active !== true) return;

  const tokenField = `${role}Token`;
  const token = pair[tokenField] as string | undefined;
  if (!token) return;

  const message: Message = {
    token,
    data,
    android: { priority: 'high', ttl: 60 * 60 * 1000 },
    apns: alert
      ? {
          headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
          payload: { aps: { alert, sound: 'default', threadId: pairId } },
        }
      : {
          headers: { 'apns-push-type': 'background', 'apns-priority': '5' },
          payload: { aps: { contentAvailable: true } },
        },
  };

  try {
    await getMessaging().send(message);
  } catch (error) {
    const code = (error as { code?: string }).code ?? '';
    if (STALE_TOKEN_CODES.has(code)) {
      await pairRef.update({ [tokenField]: FieldValue.delete() });
      logger.info('Removed stale push token', { pairId, role });
    } else {
      logger.warn('Push failed', { pairId, role, code });
    }
  }
}

export const onNotificationMirrored = onDocumentCreated('pairs/{pairId}/notifications/{notificationId}', async (event) => {
  const doc = event.data?.data();
  if (!doc) return;
  const { pairId, notificationId } = event.params;
  const payload = typeof doc.payload === 'string' ? doc.payload : '';

  await pushTo(
    pairId,
    'receiver',
    {
      type: 'notification',
      pairId,
      id: notificationId,
      canReply: String(doc.canReply === true),
      // Too large to inline: the app reads the document instead.
      ...(payload.length <= MAX_INLINE_PAYLOAD ? { payload } : {}),
    },
    { title: 'AirReply', body: 'New notification from your paired phone' },
  );
});

export const onReplyQueued = onDocumentCreated('pairs/{pairId}/replies/{replyId}', async (event) => {
  const { pairId, replyId } = event.params;
  await pushTo(pairId, 'sender', { type: 'reply', pairId, replyId });
});

export const onPairEnded = onDocumentUpdated('pairs/{pairId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after;
  if (!after || before?.active !== true || after.data()?.active !== false) return;

  await db.recursiveDelete(after.ref);
  logger.info('Deleted ended pair', { pairId: event.params.pairId });
});
