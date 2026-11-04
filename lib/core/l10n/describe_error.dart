import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// Anything thrown, as a sentence in the person's language for a snackbar or an empty state.
extension DescribeError on AppLocalizations {
  String describe(Object error) {
    if (error is! AppException) return errorUnknown;
    final sentence = switch (error.reason) {
      AppError.offline => errorOffline,
      AppError.serverUnreachable => errorServerUnreachable,
      AppError.signInRefused => errorSignInRefused,
      AppError.signInFailed => errorSignInFailed,
      AppError.syncFailed => errorSyncFailed,
      AppError.devicesUnreachable => errorDevicesUnreachable(error.count ?? 1, error.total ?? 1),
      AppError.pairingCodeNotCreated => errorPairingCodeNotCreated,
      AppError.sessionNotConfirmable => errorSessionNotConfirmable,
      AppError.codeUnavailable => errorCodeUnavailable,
      AppError.cannotPairWithItself => errorCannotPairWithItself,
      AppError.codeAlreadyUsed => errorCodeAlreadyUsed,
      AppError.noDeviceJoined => errorNoDeviceJoined,
      AppError.codeFormat => errorCodeFormat,
      AppError.notAPairingCode => errorNotAPairingCode,
      AppError.codeNotFound => errorCodeNotFound,
      AppError.codeExpired => errorCodeExpired,
      AppError.qrMismatch => errorQrMismatch,
      AppError.notConfirmedYet => errorNotConfirmedYet,
      AppError.pairingCancelledOnPhone => errorPairingCancelledOnPhone,
      AppError.pairingCancelled => errorPairingCancelled,
      AppError.pairingNotAvailable => errorPairingNotAvailable,
      AppError.pairingServerFailed => errorPairingServerFailed,
      AppError.pairingOffInDemo => errorPairingOffInDemo,
      AppError.notPaired => errorNotPaired,
      AppError.invalidPeerKey => errorInvalidPeerKey,
      AppError.unsafePeerKey => errorUnsafePeerKey,
      AppError.encryptFailed => errorEncryptFailed,
      AppError.decryptFailed => errorDecryptFailed,
      AppError.payloadUnknown => errorPayloadUnknown,
      AppError.payloadForeign => errorPayloadForeign,
      AppError.sharingAndroidOnly => errorSharingAndroidOnly,
      AppError.nativeServiceFailed => errorNativeServiceFailed,
      AppError.nativeServiceUnavailable => errorNativeServiceUnavailable,
      AppError.replyEmpty => errorReplyEmpty,
      AppError.replyTooLong => errorReplyTooLong,
      AppError.replyNotPossible => errorReplyNotPossible,
      AppError.replyDismissed => errorReplyDismissed,
    };
    final detail = error.detail;
    return detail == null ? sentence : errorWithDetail(sentence, detail);
  }
}

extension DescribeErrorContext on BuildContext {
  /// [error] as a sentence in the person's language.
  String describeError(Object error) => l10n.describe(error);
}
