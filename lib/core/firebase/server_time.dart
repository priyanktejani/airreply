/// "Set this field to the server's commit time." A transport-neutral stand-in that each backend translates
/// (`FieldValue.serverTimestamp()` for FlutterFire, a `REQUEST_TIME` transform for REST), so document codecs can be
/// shared between them.
final class ServerTime {
  const ServerTime._();

  static const value = ServerTime._();
}
