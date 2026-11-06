import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/platform/launcher_icon.dart';
import 'package:air_reply/core/platform/notification_permission.dart';
import 'package:air_reply/features/settings/domain/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appPreferencesStoreProvider = Provider<AppPreferencesStore>(
  (ref) => SharedAppPreferencesStore(ref.watch(sharedPreferencesProvider)),
);

final appPreferencesProvider = AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
  AppPreferencesController.new,
);

final class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() => ref.watch(appPreferencesStoreProvider).load();

  Future<void> setAlertShowsContent(bool value) => _update((p) => p.copyWith(alertShowsContent: value));

  Future<void> setHaptics(bool value) => _update((p) => p.copyWith(haptics: value));

  Future<void> setAutostartConfirmed(bool value) => _update((p) => p.copyWith(autostartConfirmed: value));

  Future<void> setSetupCardHidden(bool value) => _update((p) => p.copyWith(setupCardHidden: value));

  Future<void> setAlertPromptShown() => _update((p) => p.copyWith(alertPromptShown: true));

  Future<void> setReceiveWhenClosed(bool value) => _update((p) => p.copyWith(receiveWhenClosed: value));

  /// Muting stops alerts for that app on this device; its notifications still reach the inbox.
  Future<void> setMuted(String packageName, {required bool muted}) => _update((p) {
    final apps = {...p.mutedApps};
    muted ? apps.add(packageName) : apps.remove(packageName);
    return p.copyWith(mutedApps: apps);
  });

  Future<void> _update(AppPreferences Function(AppPreferences current) change) async {
    final current = state.value ?? await future;
    final next = change(current);
    state = AsyncData(next);
    await ref.read(appPreferencesStoreProvider).save(next);
  }
}

/// Whether this device may show system alerts (receivers), kept current when the app comes back to the front.
final alertPermissionProvider = AsyncNotifierProvider.autoDispose<AlertPermissionController, bool>(
  AlertPermissionController.new,
);

final class AlertPermissionController extends AsyncNotifier<bool> {
  NotificationPermission get _permission => ref.read(notificationPermissionProvider);

  @override
  Future<bool> build() => ref.watch(notificationPermissionProvider).isGranted();

  Future<void> refresh() async => state = await AsyncValue.guard(_permission.isGranted);

  Future<void> request() async {
    await _permission.request();
    await refresh();
  }
}

final launcherIconsProvider = Provider((ref) => LauncherIcons());

/// The app icon on the home screen (Settings → Appearance → App icon): null where the system has only one.
final launcherIconProvider = AsyncNotifierProvider.autoDispose<LauncherIconController, LauncherIcon?>(
  LauncherIconController.new,
);

class LauncherIconController extends AsyncNotifier<LauncherIcon?> {
  @override
  Future<LauncherIcon?> build() async => LauncherIcons.isSupported ? ref.watch(launcherIconsProvider).current() : null;

  Future<void> choose(LauncherIcon icon) async {
    if (state.value == icon) return;
    await ref.read(launcherIconsProvider).set(icon);
    state = AsyncData(icon);
  }
}
