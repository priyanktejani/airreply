import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/pair_cipher.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/data/firestore_sync_repository.dart';
import 'package:air_reply/features/mirror/data/mirror_documents.dart';
import 'package:air_reply/features/mirror/data/rest_sync_repository.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Everything here is per pair (family keyed by pair id): each pair has its own key and its own documents.

final pairCipherProvider = Provider.family<PairCipher, String>((ref, pairId) {
  final credentials = ref.watch(pairCredentialsProvider(pairId));
  return PairCipher(cipher: ref.watch(payloadCipherProvider), pairId: pairId, key: credentials.sharedKey);
});

/// The pair's backend, through FlutterFire or REST depending on the platform.
final mirrorRepositoryProvider = Provider.family<MirrorRepository, String>((ref, pairId) {
  final documents = MirrorDocuments(ref.watch(pairCipherProvider(pairId)));
  return switch (ref.watch(backendTransportProvider)) {
    BackendTransport.firebaseSdk => FirestoreSyncRepository(ref.watch(firestoreProvider), pairId, documents),
    BackendTransport.rest => RestSyncRepository(ref.watch(firestoreRestClientProvider), pairId, documents),
  };
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
