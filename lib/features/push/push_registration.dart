import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Publishes this device's FCM token on each of its pairs, so the backend can wake the sender for a reply and alert
/// a phone receiver about a new notification.
final class PushRegistrar {
  PushRegistrar(this._messaging, this._repository);

  final FirebaseMessaging _messaging;
  final PairingRepository _repository;
  StreamSubscription<String>? _refresh;

  Future<void> register(List<PairingCredentials> pairs) async {
    Future<void> publish(String token) async {
      for (final pair in pairs) {
        await _repository.registerPushToken(pairId: pair.pairId, role: pair.role, token: token);
      }
    }

    await _messaging.requestPermission();
    // Registration tokens (not the newer FID direct-send) because the Cloud Functions send with the Admin SDK's
    // `token` target. Move both sides to register()/onRegistered together.
    // ignore: deprecated_member_use
    if (await _messaging.getToken() case final String token) await publish(token);
    // ignore: deprecated_member_use
    _refresh = _messaging.onTokenRefresh.listen((token) => unawaited(publish(token)));
  }

  Future<void> dispose() async => _refresh?.cancel();
}

/// Kept alive by the app shell while paired; re-registers whenever the set of pairs changes. Phones only: desktop and
/// web receivers raise their own alerts while they run.
final pushRegistrationProvider = FutureProvider<void>((ref) async {
  final pairs = ref.watch(pairedDevicesProvider);
  if (!AppPlatform.usesPush || pairs.isEmpty) return;

  final registrar = PushRegistrar(ref.watch(firebaseMessagingProvider), ref.watch(pairingRepositoryProvider));
  ref.onDispose(registrar.dispose);
  try {
    await registrar.register(pairs);
  } on Object catch (e) {
    // No push (simulator without APNs, Play services missing): realtime sync still works while the app runs.
    appLog('Push registration failed: $e', name: 'air_reply.push');
  }
});
