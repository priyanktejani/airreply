import 'package:air_reply/core/platform/native_models.dart';
import 'package:flutter/services.dart';

/// Callbacks the native side drives in the sender's headless sync isolate.
abstract interface class BackgroundSyncHandler {
  Future<void> onNotificationPosted(CapturedNotification notification);

  Future<void> onNotificationRemoved(String key);

  /// Something (a push, the system) suggests replies may be waiting: fetch them now instead of waiting for the
  /// realtime listener to reconnect.
  Future<void> onWake();
}

/// The Dart end of `com.airreply/background`, which exists only in the headless engine the foreground service runs.
abstract interface class BackgroundSyncChannel {
  void attach(BackgroundSyncHandler handler);

  /// Tells native the handler is set; it then flushes the notifications it queued while Dart was starting.
  Future<void> signalReady();
}

final class MethodChannelBackgroundSyncChannel implements BackgroundSyncChannel {
  MethodChannelBackgroundSyncChannel({this._channel = const MethodChannel(channelName)});

  static const channelName = 'com.airreply/background';

  final MethodChannel _channel;

  @override
  void attach(BackgroundSyncHandler handler) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'notificationPosted':
          await handler.onNotificationPosted(CapturedNotification.fromMap(call.arguments as Map<Object?, Object?>));
        case 'notificationRemoved':
          await handler.onNotificationRemoved((call.arguments as Map<Object?, Object?>)['key']! as String);
        case 'wake':
          await handler.onWake();
        default:
          throw MissingPluginException(call.method);
      }
    });
  }

  @override
  Future<void> signalReady() => _channel.invokeMethod<void>('ready');
}
