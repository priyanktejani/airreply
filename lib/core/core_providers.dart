import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/core/device/device_identity.dart';
import 'package:air_reply/core/firebase/auth_gateway.dart';
import 'package:air_reply/core/firebase/rest/firebase_rest_config.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/rest_auth_gateway.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/core/platform/notification_permission.dart';
import 'package:air_reply/core/storage/secret_store.dart';
import 'package:air_reply/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Composition root for the shared infrastructure. Features depend on the abstract types these providers expose
// (KeyAgreement, PayloadCipher, NotificationBridge, AuthGateway...), and tests override them with fakes.

/// FlutterFire or REST, decided by the platform; override in tests to exercise either.
final backendTransportProvider = Provider<BackendTransport>((ref) => AppPlatform.backend);

// ------------------------------------------------------------------ FlutterFire (Android, iOS, macOS, web)

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);

// ------------------------------------------------------------------ REST (Windows, Linux)

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The web app's config: Windows and Linux use the same public API key and project as the browser build.
final firebaseRestConfigProvider = Provider<FirebaseRestConfig>(
  (ref) => FirebaseRestConfig.fromOptions(DefaultFirebaseOptions.web),
);

final restAuthGatewayProvider = Provider<RestAuthGateway>(
  (ref) => RestAuthGateway(
    ref.watch(firebaseRestConfigProvider),
    ref.watch(httpClientProvider),
    ref.watch(secretStoreProvider),
  ),
);

final firestoreRestClientProvider = Provider<FirestoreRestClient>(
  (ref) => FirestoreRestClient(
    ref.watch(firebaseRestConfigProvider),
    ref.watch(httpClientProvider),
    ref.watch(restAuthGatewayProvider),
  ),
);

// ------------------------------------------------------------------ shared

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => switch (ref.watch(backendTransportProvider)) {
    BackendTransport.firebaseSdk => FirebaseAuthGateway(FirebaseAuth.instance),
    BackendTransport.rest => ref.watch(restAuthGatewayProvider),
  },
);

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());

final keyAgreementProvider = Provider<KeyAgreement>((ref) => ref.watch(cryptoServiceProvider));

final payloadCipherProvider = Provider<PayloadCipher>((ref) => ref.watch(cryptoServiceProvider));

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    // The legacy keychain needs no provisioning profile, so the Mac app runs when signed to run locally.
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  ),
);

final secretStoreProvider = Provider<SecretStore>((ref) => SecureStorageSecretStore(ref.watch(secureStorageProvider)));

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) => SharedPreferencesAsync());

final notificationBridgeProvider = Provider<NotificationBridge>((ref) => MethodChannelNotificationBridge());

final notificationPermissionProvider = Provider<NotificationPermission>(
  (ref) => LocalNotificationsPermission(FlutterLocalNotificationsPlugin()),
);

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) => DeviceInfoIdentity(DeviceInfoPlugin()));
