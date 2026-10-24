/// Every failure the app expects and knows how to explain to the person using it.
///
/// Layers below the UI throw these (never raw Firebase / platform errors), so screens can show [message] as is.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

/// The pairing code or QR is wrong, expired, already used, or the two devices disagree on the keys.
final class PairingException extends AppException {
  const PairingException(super.message, {super.cause});
}

/// A payload could not be encrypted or decrypted (wrong key, tampered data, unknown format).
final class CryptoException extends AppException {
  const CryptoException(super.message, {super.cause});
}

/// The Android side (notification listener, foreground service) refused or is missing.
final class NativeBridgeException extends AppException {
  const NativeBridgeException(super.message, {super.cause});
}

/// The device has no paired partner, so there is nothing to sync with.
final class NotPairedException extends AppException {
  const NotPairedException() : super('This device is not paired yet.');
}

/// Network or backend failure (Firestore, Auth, Messaging).
final class SyncException extends AppException {
  const SyncException(super.message, {super.cause});
}

/// Input the person typed that cannot be used (an empty reply, a short code).
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Turns anything thrown into a sentence fit for a snackbar.
String describeError(Object error) => switch (error) {
  AppException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};
