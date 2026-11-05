import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/crypto/crypto_contracts.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
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

/// Confirmed on this phone: waiting for the receiver to acknowledge that it kept the pair too.
final class SenderPairingFinishing extends SenderPairingState {
  const SenderPairingFinishing(this.receiverName);
  final String receiverName;
}

/// The receiver did not acknowledge in time: the person waits longer, says it is paired there, or cancels.
final class SenderPairingUnconfirmed extends SenderPairingState {
  const SenderPairingUnconfirmed(this.receiverName);
  final String receiverName;
}

/// Paired: the screen returns to the sender home.
final class SenderPairingDone extends SenderPairingState {
  const SenderPairingDone(this.peerName);
  final String peerName;
}

final senderPairingProvider = NotifierProvider.autoDispose<SenderPairingController, SenderPairingState>(
  SenderPairingController.new,
);

/// Drives the sender through: new session -> receiver joins -> codes compared -> pair confirmed -> the receiver
/// acknowledges. Both devices show paired only once both kept the pair.
final class SenderPairingController extends Notifier<SenderPairingState> {
  late PairingRepository _repository;
  PendingPairing? _pending;
  StreamSubscription<PairingSession?>? _sessionUpdates;

  /// Asks the server again from time to time, beside the live updates: a stalled listener never strands pairing.
  Timer? _poll;
  bool _completed = false;
  bool _deriving = false;

  /// The pair confirmed here, until the receiver acknowledged it.
  PairingCredentials? _confirmed;

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
      _poll = Timer.periodic(ref.read(pairingTimingsProvider).poll, (_) async {
        try {
          await _onSession(await _repository.fetchSession(pending.session.code));
        } on Object {
          // offline for a moment: the live updates and the next check carry on
        }
      });
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
      _confirmed = credentials;
      await _stopWatching();
      // Paired here from now on, whatever happens to this screen: sharing starts and the pair is in the session, so
      // leaving while the receiver finishes never leaves a key that shares nothing. The wait below only tells the
      // person whether the receiver got there too.
      await _startSharing(credentials);
      await _awaitReceiver();
    } on Object catch (e) {
      _fail(e);
    }
  }

  /// Waits for the receiver's acknowledgement; after a while (see [pairingTimingsProvider]), asks the person.
  Future<void> _awaitReceiver() async {
    final credentials = _confirmed;
    if (credentials == null || !ref.mounted) return;
    state = SenderPairingFinishing(credentials.peerName);
    try {
      await _repository
          .watchReady(credentials.pairId, DeviceRole.receiver)
          .firstWhere((ready) => ready)
          .timeout(ref.read(pairingTimingsProvider).ackTimeout);
    } on Object {
      if (ref.mounted && _confirmed == credentials) state = SenderPairingUnconfirmed(credentials.peerName);
      return;
    }
    await _finish();
  }

  /// The receiver did not acknowledge yet: give it more time.
  Future<void> keepWaiting() => _awaitReceiver();

  /// The person sees the receiver paired (an older AirReply there does not acknowledge): carry on.
  Future<void> finishAnyway() => _finish();

  /// Gives up on this pair: ends it on the server (the receiver, if it finishes later, sees it ended) and here, then
  /// shows a new code.
  Future<void> cancelUnconfirmed() async {
    final credentials = _confirmed;
    if (credentials == null) return;
    _confirmed = null;
    _completed = false;
    state = const SenderPairingStarting();
    try {
      await ref.read(deviceSessionProvider.notifier).unpair(credentials.pairId);
    } on Object {
      // nothing is left to undo, or the server's part is done once it can
    }
    await newCode();
  }

  Future<void> _startSharing(PairingCredentials credentials) async {
    try {
      // Starts sharing, or restarts it so the running engine also serves the new device.
      await ref.read(notificationBridgeProvider).startSync();
    } on NativeBridgeException {
      // Sharing can still be switched on from the home screen.
    }
    await ref.read(deviceSessionProvider.notifier).paired(credentials);
  }

  Future<void> _finish() async {
    final credentials = _confirmed;
    if (credentials == null) return;
    _confirmed = null;
    if (ref.mounted) state = SenderPairingDone(credentials.peerName);
  }

  /// The codes differ: someone else may have joined. Throw the session away.
  Future<void> reject() => newCode();

  Future<void> _onSession(PairingSession? session) async {
    final pending = _pending;
    if (pending == null || _completed || !ref.mounted) return;
    if (session == null || session.status == PairingStatus.cancelled) {
      await _stopWatching();
      return _fail(const PairingException(AppError.pairingCancelled));
    }
    // once only, whether the live update or the check got there first
    if (session.status == PairingStatus.joined && state is SenderPairingWaiting && !_deriving) {
      _deriving = true;
      try {
        final secrets = await ref.read(deriveSenderSecretsProvider).call(pending, session);
        if (ref.mounted && state is SenderPairingWaiting) {
          state = SenderPairingVerifying(joined: session, secrets: secrets);
        }
      } on Object catch (e) {
        _fail(e);
      } finally {
        _deriving = false;
      }
    }
  }

  Future<void> _stopWatching() async {
    _poll?.cancel();
    _poll = null;
    await _sessionUpdates?.cancel();
    _sessionUpdates = null;
  }

  Future<void> _abandon() async {
    await _stopWatching();
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
