import 'package:air_reply/core/firebase/server_time.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Translates between the transport-neutral document maps the codecs use (DateTime, [ServerTime]) and the
/// FlutterFire types (Timestamp, FieldValue).
abstract final class SdkValues {
  static Map<String, Object?> toSdk(Map<String, Object?> data) => {
    for (final e in data.entries)
      e.key: switch (e.value) {
        ServerTime() => FieldValue.serverTimestamp(),
        final DateTime time => Timestamp.fromDate(time),
        final value => value,
      },
  };

  static Map<String, Object?> fromSdk(Map<String, Object?>? data) => {
    for (final e in (data ?? const {}).entries)
      e.key: switch (e.value) {
        final Timestamp time => time.toDate(),
        final value => value,
      },
  };
}
