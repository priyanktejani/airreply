/// Why something the person asked for did not work. Screens turn it into a sentence in their language
/// (`context.describeError`); logs show its name.
enum AppError {
  // connection and backend
  offline,
  serverUnreachable,
  signInRefused,
  signInFailed,
  syncFailed,
  devicesUnreachable,

  // pairing
  pairingCodeNotCreated,
  sessionNotConfirmable,
  codeUnavailable,
  cannotPairWithItself,
  codeAlreadyUsed,
  noDeviceJoined,
  codeFormat,
  notAPairingCode,
  codeNotFound,
  codeExpired,
  qrMismatch,
  notConfirmedYet,
  pairingCancelledOnPhone,
  pairingCancelled,
  pairingNotAvailable,
  pairingServerFailed,
  pairingOffInDemo,
  notPaired,

  // encryption
  invalidPeerKey,
  unsafePeerKey,
  encryptFailed,
  decryptFailed,
  payloadUnknown,
  payloadForeign,

  // the Android side
  sharingAndroidOnly,
  nativeServiceFailed,
  nativeServiceUnavailable,

  // replies
  replyEmpty,
  replyTooLong,
  replyNotPossible,
  replyDismissed,
}

/// Every failure the app expects and knows how to explain to the person using it.
///
/// Layers below the UI throw these (never raw Firebase / platform errors), with the [reason] and, where it helps, a
/// technical [detail] (a server status) or counts; screens say it in the person's language.
sealed class AppException implements Exception {
  const AppException(this.reason, {this.detail, this.count, this.total, this.cause});

  final AppError reason;

  /// A technical code shown in brackets after the sentence (a server status), when there is one.
  final String? detail;

  /// How many of [total] (devices that could not be reached).
  final int? count;
  final int? total;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: ${reason.name}${detail == null ? '' : ' ($detail)'}${cause == null ? '' : ' ($cause)'}';
}

/// The pairing code or QR is wrong, expired, already used, or the two devices disagree on the keys.
final class PairingException extends AppException {
  const PairingException(super.reason, {super.detail, super.cause});
}

/// A payload could not be encrypted or decrypted (wrong key, tampered data, unknown format).
final class CryptoException extends AppException {
  const CryptoException(super.reason, {super.cause});
}

/// The Android side (notification listener, foreground service) refused or is missing.
final class NativeBridgeException extends AppException {
  const NativeBridgeException(super.reason, {super.detail, super.cause});
}

/// The device has no paired partner, so there is nothing to sync with.
final class NotPairedException extends AppException {
  const NotPairedException() : super(AppError.notPaired);
}

/// Network or backend failure (Firestore, Auth, Messaging).
final class SyncException extends AppException {
  const SyncException(super.reason, {super.detail, super.count, super.total, super.cause});
}

/// Input the person typed that cannot be used (an empty reply, a short code).
final class ValidationException extends AppException {
  const ValidationException(super.reason);
}
