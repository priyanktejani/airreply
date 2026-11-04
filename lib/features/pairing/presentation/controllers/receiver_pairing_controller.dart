import 'dart:async';
import 'dart:typed_data';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_invite.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:air_reply/features/pairing/domain/usecases/receiver_pairing_usecases.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class ReceiverPairingState {
  const ReceiverPairingState();
}

/// Scanning or typing a code. [error] is the reason the last attempt failed.
final class ReceiverPairingIdle extends ReceiverPairingState {
  const ReceiverPairingIdle({this.error});

  /// Shown in the person's language by the screen (`context.describeError`).
  final Object? error;
}

final class ReceiverPairingJoining extends ReceiverPairingState {
  const ReceiverPairingJoining();
}

/// Joined: showing the verification code until the sender confirms it matches.
final class ReceiverPairingAwaitingConfirmation extends ReceiverPairingState {
  const ReceiverPairingAwaitingConfirmation(this.joined);
  final JoinedPairing joined;
}

/// Paired: the screen returns to the feed.
final class ReceiverPairingDone extends ReceiverPairingState {
  const ReceiverPairingDone(this.peerName);
  final String peerName;
}

final receiverPairingProvider = NotifierProvider.autoDispose<ReceiverPairingController, ReceiverPairingState>(
  ReceiverPairingController.new,
);

/// Drives the receiver through: scan / type code -> join -> show code -> sender confirms -> paired.
final class ReceiverPairingController extends Notifier<ReceiverPairingState> {
  late PairingRepository _repository;
  StreamSubscription<PairingSession?>? _sessionUpdates;

  @override
  ReceiverPairingState build() {
    _repository = ref.watch(pairingRepositoryProvider);
    ref.onDispose(() => unawaited(_sessionUpdates?.cancel()));
    return const ReceiverPairingIdle();
  }

  /// A QR code was scanned. Ignored while an attempt is already running.
  Future<void> joinFromQr(String raw) async {
    if (state is! ReceiverPairingIdle) return;
    final invite = PairingInvite.tryParse(raw);
    if (invite == null) {
      state = const ReceiverPairingIdle(error: PairingException(AppError.notAPairingCode));
      return;
    }
    await _join(invite.code, expectedSenderKey: invite.senderPublicKey);
  }

  Future<void> joinWithCode(String code) => _join(code.replaceAll(RegExp(r'\s'), ''));

  /// Back to scanning; the sender sees the session cancelled.
  Future<void> cancel() async {
    final current = state;
    await _sessionUpdates?.cancel();
    _sessionUpdates = null;
    if (current is ReceiverPairingAwaitingConfirmation) {
      try {
        await _repository.cancelSession(current.joined.session.code);
      } on Object {
        // Expires on its own.
      }
    }
    if (ref.mounted) state = const ReceiverPairingIdle();
  }

  Future<void> _join(String code, {Uint8List? expectedSenderKey}) async {
    if (state is! ReceiverPairingIdle) return;
    state = const ReceiverPairingJoining();
    try {
      final joined = await ref.read(joinPairingSessionProvider).call(code: code, expectedSenderKey: expectedSenderKey);
      if (!ref.mounted) return;
      state = ReceiverPairingAwaitingConfirmation(joined);
      _sessionUpdates = _repository.watchSession(code).listen((s) => _onSession(joined, s), onError: _fail);
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _onSession(JoinedPairing joined, PairingSession? session) async {
    if (session == null || session.status == PairingStatus.cancelled) {
      await _sessionUpdates?.cancel();
      return _fail(const PairingException(AppError.pairingCancelledOnPhone));
    }
    if (session.status != PairingStatus.confirmed) return;

    await _sessionUpdates?.cancel();
    try {
      final credentials = await ref.read(finishReceiverPairingProvider).call(joined, session);
      // The handshake is done; remove it rather than waiting for the TTL.
      unawaited(_repository.cancelSession(session.code).catchError((Object _) {}));
      await ref.read(deviceSessionProvider.notifier).paired(credentials);
      if (ref.mounted) state = ReceiverPairingDone(credentials.peerName);
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error) {
    if (ref.mounted) state = ReceiverPairingIdle(error: error);
  }
}
