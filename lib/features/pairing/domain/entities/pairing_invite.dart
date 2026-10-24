import 'dart:convert';
import 'dart:typed_data';

/// What the sender's QR code carries: the 6-digit session code and the sender's public key.
///
/// Scanning gives the receiver the sender's key out of band, so a swapped key in the backend is detected
/// immediately. Typing the code instead relies on the verification code both screens show.
final class PairingInvite {
  const PairingInvite({required this.code, required this.senderPublicKey});

  static const _scheme = 'airreply';
  static const _host = 'pair';

  final String code;
  final Uint8List senderPublicKey;

  static bool isValidCode(String code) => RegExp(r'^\d{6}$').hasMatch(code);

  /// e.g. `airreply://pair?c=482913&k=...`
  String toUri() => Uri(
    scheme: _scheme,
    host: _host,
    queryParameters: {'c': code, 'k': base64Url.encode(senderPublicKey).replaceAll('=', '')},
  ).toString();

  /// Null when [raw] is not an AirReply pairing QR.
  static PairingInvite? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != _scheme || uri.host != _host) return null;
    final code = uri.queryParameters['c'];
    final key = uri.queryParameters['k'];
    if (code == null || !isValidCode(code) || key == null) return null;
    try {
      final bytes = base64Url.decode(base64Url.normalize(key));
      return bytes.length == 32 ? PairingInvite(code: code, senderPublicKey: bytes) : null;
    } on FormatException {
      return null;
    }
  }
}
