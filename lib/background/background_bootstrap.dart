import 'dart:ui';

import 'package:air_reply/core/firebase/firebase_start.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Start-up shared by every isolate that has no UI: the sender's sync engine, the push handler and the alert-action
/// handler. They get the same providers as the app, so there is one wiring for the whole codebase.
Future<ProviderContainer> bootstrapBackgroundIsolate() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (Firebase.apps.isEmpty) await startFirebase();
  return ProviderContainer();
}
