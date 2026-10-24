import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logs to DevTools *and* the platform log (`adb logcat -s flutter`, Xcode console), so problems in background
/// isolates (the sender's sync engine, push handlers) can be seen on a device without a debugger attached.
/// Never pass notification content here: only ids, package names, counts and errors.
void appLog(String message, {String name = 'air_reply', Object? error, StackTrace? stackTrace}) {
  developer.log(message, name: name, error: error, stackTrace: stackTrace);
  debugPrint('[$name] $message${error == null ? '' : ': $error'}');
}
