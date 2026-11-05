import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/cleanup_providers.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/data/firestore_pairing_repository.dart';
import 'package:air_reply/features/pairing/data/rest_pairing_repository.dart';
import 'package:air_reply/features/pairing/data/secure_archived_pairs_store.dart';
import 'package:air_reply/features/pairing/data/secure_pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/data/secure_pending_join_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/archived_pairs_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/usecases/continue_history.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/restore_kept_history.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:air_reply/features/pairing/domain/usecases/unpair.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pairingRepositoryProvider = Provider<PairingRepository>(
  (ref) => switch (ref.watch(backendTransportProvider)) {
    BackendTransport.firebaseSdk => FirestorePairingRepository(
      ref.watch(firestoreProvider),
      ref.watch(authGatewayProvider),
    ),
    BackendTransport.rest => RestPairingRepository(
      ref.watch(firestoreRestClientProvider),
      ref.watch(authGatewayProvider),
      pairPolls: ref.watch(documentPollsProvider),
    ),
  },
);

/// How long pairing waits for the other device's acknowledgement, and how often it asks the server again beside the
/// live updates (shorter in tests).
final pairingTimingsProvider = Provider<({Duration ackTimeout, Duration poll})>(
  (ref) => (ackTimeout: const Duration(seconds: 45), poll: const Duration(seconds: 4)),
);

final pairingCredentialsStoreProvider = Provider<PairingCredentialsStore>(
  (ref) => SecurePairingCredentialsStore(ref.watch(secretStoreProvider)),
);

/// Removed devices whose history is kept on this device.
final archivedPairsStoreProvider = Provider<ArchivedPairsStore>(
  (ref) => SecureArchivedPairsStore(ref.watch(secretStoreProvider)),
);

final continueHistoryProvider = Provider(
  (ref) => ContinueHistory(ref.watch(archivedPairsStoreProvider), moveHistory: ref.watch(moveHistoryProvider)),
);

final restoreKeptHistoryProvider = Provider(
  (ref) => RestoreKeptHistory(
    ref.watch(pairingRepositoryProvider),
    ref.watch(pairingCredentialsStoreProvider),
    ref.watch(continueHistoryProvider),
  ),
);

final startPairingSessionProvider = Provider(
  (ref) => StartPairingSession(
    ref.watch(pairingRepositoryProvider),
    ref.watch(keyAgreementProvider),
    ref.watch(deviceIdentityProvider),
  ),
);

final deriveSenderSecretsProvider = Provider((ref) => DeriveSenderSecrets(ref.watch(keyAgreementProvider)));

final confirmSenderPairingProvider = Provider(
  (ref) => ConfirmSenderPairing(ref.watch(pairingRepositoryProvider), ref.watch(pairingCredentialsStoreProvider)),
);

final joinPairingSessionProvider = Provider(
  (ref) => JoinPairingSession(
    ref.watch(pairingRepositoryProvider),
    ref.watch(keyAgreementProvider),
    ref.watch(deviceIdentityProvider),
  ),
);

final finishReceiverPairingProvider = Provider(
  (ref) => FinishReceiverPairing(ref.watch(pairingCredentialsStoreProvider), ref.watch(pairingRepositoryProvider)),
);

final pendingJoinStoreProvider = Provider<PendingJoinStore>(
  (ref) => SecurePendingJoinStore(ref.watch(secretStoreProvider)),
);

final resumeReceiverPairingProvider = Provider(
  (ref) => ResumeReceiverPairing(
    ref.watch(pendingJoinStoreProvider),
    ref.watch(pairingRepositoryProvider),
    ref.watch(finishReceiverPairingProvider),
  ),
);

final unpairProvider = Provider(
  (ref) => Unpair(
    ref.watch(pairingRepositoryProvider),
    ref.watch(pairingCredentialsStoreProvider),
    ref.watch(notificationBridgeProvider),
    eraseHistory: ref.watch(eraseHistoryProvider),
    removeDoorbell: ref.watch(removeDoorbellProvider),
    archive: ref.watch(archivedPairsStoreProvider),
    historySize: ref.watch(historySizeProvider),
  ),
);
