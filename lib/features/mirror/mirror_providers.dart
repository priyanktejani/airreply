import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/data/firestore_mailbox.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/mirror_sync_repository.dart';
import 'package:air_reply/features/mirror/data/rest_mailbox.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Everything here is per pair (family keyed by pair id): each pair has its own key and its own documents.

final pairCipherProvider = Provider.family<PairCipher, String>((ref, pairId) {
  final credentials = ref.watch(pairCredentialsProvider(pairId));
  return PairCipher(cipher: ref.watch(payloadCipherProvider), pairId: pairId, key: credentials.sharedKey);
});

/// The pair's sync: history on this device, and the backend (FlutterFire or REST, depending on the platform) as a
/// mailbox that the receiver empties.
final mirrorRepositoryProvider = Provider.family<MirrorRepository, String>((ref, pairId) {
  final mailbox = switch (ref.watch(backendTransportProvider)) {
    BackendTransport.firebaseSdk => FirestoreMailbox(ref.watch(firestoreProvider), pairId),
    BackendTransport.rest => RestMailbox(
      ref.watch(firestoreRestClientProvider),
      pairId,
      pairPolls: ref.watch(documentPollsProvider),
    ),
  };
  final repository = MirrorSyncRepository(
    mailbox,
    MirrorDocuments(ref.watch(pairCipherProvider(pairId))),
    ref.watch(messageHistoryProvider(pairId)),
    collects: ref.watch(pairCredentialsProvider(pairId).select((p) => p.role)) == DeviceRole.receiver,
  );
  ref.onDispose(repository.dispose);
  return repository;
});

// The same repository, exposed per role so each consumer depends only on the slice it needs.

final notificationPublisherProvider = Provider.family<NotificationPublisher, String>(
  (ref, pairId) => ref.watch(mirrorRepositoryProvider(pairId)),
);

final replyInboxProvider = Provider.family<ReplyInbox, String>(
  (ref, pairId) => ref.watch(mirrorRepositoryProvider(pairId)),
);

final notificationFeedProvider = Provider.family<NotificationFeed, String>(
  (ref, pairId) => ref.watch(mirrorRepositoryProvider(pairId)),
);

final replyOutboxProvider = Provider.family<ReplyOutbox, String>(
  (ref, pairId) => ref.watch(mirrorRepositoryProvider(pairId)),
);
