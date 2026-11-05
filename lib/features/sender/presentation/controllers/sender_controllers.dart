import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------------ sync on / off

final syncStatusProvider = AsyncNotifierProvider.autoDispose<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);

/// The foreground service + headless engine state, kept current by native `syncState` events.
final class SyncStatusController extends AsyncNotifier<SyncStatus> {
  NotificationBridge get _bridge => ref.read(notificationBridgeProvider);

  @override
  Future<SyncStatus> build() async {
    final bridge = ref.watch(notificationBridgeProvider);
    final events = bridge.events().whereType<SyncStateEvent>().listen((e) => state = AsyncData(e.status));
    ref.onDispose(events.cancel);
    return bridge.syncStatus();
  }

  /// Throws [NativeBridgeException] (state unchanged) when the service refuses to start or stop.
  /// On a device that shows notifications, the same service keeps it receiving while AirReply is closed.
  Future<void> setEnabled(bool enabled) async {
    enabled
        ? await _bridge.startSync(receiving: ref.read(deviceRoleProvider) == DeviceRole.receiver)
        : await _bridge.stopSync();
    state = AsyncData(await _bridge.syncStatus());
  }

  Future<void> refresh() async => state = await AsyncValue.guard(_bridge.syncStatus);

  /// Asks Android to bind the notification listener again; the `syncState` event updates the status once it does.
  Future<void> reconnectListener() async {
    await _bridge.requestListenerRebind();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (ref.mounted) await refresh();
  }
}

// ------------------------------------------------------------------ which apps

final installedAppsProvider = FutureProvider.autoDispose<List<InstalledApp>>(
  (ref) => ref.watch(notificationBridgeProvider).installedApps(),
);

final appFilterProvider = AsyncNotifierProvider.autoDispose<AppFilterController, AppFilter>(AppFilterController.new);

final class AppFilterController extends AsyncNotifier<AppFilter> {
  @override
  Future<AppFilter> build() => ref.watch(notificationBridgeProvider).appFilter();

  Future<void> setMode(AppFilterMode mode) => _save((f) => f.copyWith(mode: mode));

  Future<void> toggle(String packageName) => _save((f) {
    final packages = {...f.packages};
    packages.contains(packageName) ? packages.remove(packageName) : packages.add(packageName);
    return f.copyWith(packages: packages);
  });

  Future<void> _save(AppFilter Function(AppFilter current) change) async {
    final current = state.value;
    if (current == null) return;
    final next = change(current);
    state = AsyncData(next); // optimistic: the switch moves at once
    try {
      await ref.read(notificationBridgeProvider).setAppFilter(next);
    } on Object {
      state = AsyncData(current);
      rethrow;
    }
  }
}

extension<T> on Stream<T> {
  Stream<S> whereType<S>() => where((e) => e is S).cast<S>();
}
