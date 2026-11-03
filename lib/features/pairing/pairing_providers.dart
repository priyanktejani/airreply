import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/cleanup_providers.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/data/firestore_pairing_repository.dart';
import 'package:air_reply/features/pairing/data/rest_pairing_repository.dart';
import 'package:air_reply/features/pairing/data/secure_pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_credentials_store.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
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

final pairingCredentialsStoreProvider = Provider<PairingCredentialsStore>(
  (ref) => SecurePairingCredentialsStore(ref.watch(secretStoreProvider)),
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
  (ref) => FinishReceiverPairing(ref.watch(pairingCredentialsStoreProvider)),
);

final unpairProvider = Provider(
  (ref) => Unpair(
    ref.watch(pairingRepositoryProvider),
    ref.watch(pairingCredentialsStoreProvider),
    ref.watch(notificationBridgeProvider),
    eraseHistory: ref.watch(eraseHistoryProvider),
    removeDoorbell: ref.watch(removeDoorbellProvider),
  ),
);
