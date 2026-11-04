import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/usecases/sender_pairing_usecases.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class SenderPairingState {
  const SenderPairingState();
}

final class SenderPairingStarting extends SenderPairingState {
  const SenderPairingStarting();
}

/// Showing the QR / code, waiting for a receiver.
final class SenderPairingWaiting extends SenderPairingState {
  const SenderPairingWaiting(this.pending);
  final PendingPairing pending;
}

/// A receiver joined: both screens show [secrets]' verification code; the person confirms they match.
final class SenderPairingVerifying extends SenderPairingState {
  const SenderPairingVerifying({required this.joined, required this.secrets, this.confirming = false});

  final PairingSession joined;
  final PairingSecrets secrets;
  final bool confirming;

  /// The receiver's name, when it sent one.
  String? get receiverName => joined.receiverName;
}

final class SenderPairingFailed extends SenderPairingState {
  const SenderPairingFailed(this.error);

  /// Shown in the person's language by the screen (`context.describeError`).
  final Object error;
}

/// Paired: the screen returns to the sender home.
final class SenderPairingDone extends SenderPairingState {
  const SenderPairingDone(this.peerName);
  final String peerName;
}

final senderPairingProvider = NotifierProvider.autoDispose<SenderPairingController, SenderPairingState>(
  SenderPairingController.new,
);

/// Drives the sender through: new session -> receiver joins -> codes compared -> pair confirmed.
final class SenderPairingController extends Notifier<SenderPairingState> {
  late PairingRepository _repository;
  PendingPairing? _pending;
  StreamSubscription<PairingSession?>? _sessionUpdates;
  bool _completed = false;

  @override
  SenderPairingState build() {
    // Kept as a field: the dispose callback below runs after `ref` is no longer usable.
    _repository = ref.watch(pairingRepositoryProvider);
    ref.onDispose(() => unawaited(_abandon()));
    unawaited(Future.microtask(newCode));
    return const SenderPairingStarting();
  }

  /// Drops the current session (if any) and shows a fresh code.
  Future<void> newCode() async {
    await _abandon();
    if (!ref.mounted) return;
    state = const SenderPairingStarting();
    try {
      final pending = await ref.read(startPairingSessionProvider).call();
      if (!ref.mounted) return;
      _pending = pending;
      state = SenderPairingWaiting(pending);
      _sessionUpdates = _repository.watchSession(pending.session.code).listen(_onSession, onError: _fail);
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// The person confirmed both devices show the same code.
  Future<void> confirm() async {
    final current = state;
    if (current is! SenderPairingVerifying || current.confirming) return;
    state = SenderPairingVerifying(joined: current.joined, secrets: current.secrets, confirming: true);
    try {
      final credentials = await ref.read(confirmSenderPairingProvider).call(current.joined, current.secrets);
      _completed = true;
      await _sessionUpdates?.cancel();
      try {
        // Starts sharing, or restarts it so the running engine also serves the new device.
        await ref.read(notificationBridgeProvider).startSync();
      } on NativeBridgeException {
        // Sharing can still be switched on from the home screen.
      }
      await ref.read(deviceSessionProvider.notifier).paired(credentials);
      if (ref.mounted) state = SenderPairingDone(credentials.peerName);
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// The codes differ: someone else may have joined. Throw the session away.
  Future<void> reject() => newCode();

  Future<void> _onSession(PairingSession? session) async {
    final pending = _pending;
    if (pending == null || _completed) return;
    if (session == null || session.status == PairingStatus.cancelled) {
      return _fail(const PairingException(AppError.pairingCancelled));
    }
    if (session.status == PairingStatus.joined && state is SenderPairingWaiting) {
      try {
        final secrets = await ref.read(deriveSenderSecretsProvider).call(pending, session);
        if (ref.mounted) state = SenderPairingVerifying(joined: session, secrets: secrets);
      } on Object catch (e) {
        _fail(e);
      }
    }
  }

  Future<void> _abandon() async {
    await _sessionUpdates?.cancel();
    _sessionUpdates = null;
    final pending = _pending;
    _pending = null;
    if (pending != null && !_completed) {
      try {
        await _repository.cancelSession(pending.session.code);
      } on Object {
        // Expires on its own.
      }
    }
  }

  void _fail(Object error) {
    if (ref.mounted) state = SenderPairingFailed(error);
  }
}
