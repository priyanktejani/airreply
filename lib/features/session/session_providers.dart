import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/archived_pair.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/data/preferences_device_settings_store.dart';
import 'package:air_reply/features/session/domain/device_session.dart';
import 'package:air_reply/features/session/domain/device_settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceSettingsStoreProvider = Provider<DeviceSettingsStore>(
  (ref) => PreferencesDeviceSettingsStore(ref.watch(sharedPreferencesProvider)),
);

/// The single source of truth for "who am I and who am I paired with".
final deviceSessionProvider = AsyncNotifierProvider<DeviceSessionController, DeviceSession>(
  DeviceSessionController.new,
);

/// The role this install plays; null before one is chosen (or while loading).
final deviceRoleProvider = Provider<DeviceRole?>(
  (ref) => ref.watch(deviceSessionProvider.select((s) => s.value?.role)),
);

/// Every paired device, oldest first. Empty while loading or unpaired.
final pairedDevicesProvider = Provider<List<PairingCredentials>>(
  (ref) => ref.watch(deviceSessionProvider.select((s) => s.value?.pairs ?? const <PairingCredentials>[])),
);

/// One pair's credentials. Throws [NotPairedException] once that pair is gone.
final pairCredentialsProvider = Provider.family<PairingCredentials, String>((ref, pairId) {
  final credentials = ref.watch(deviceSessionProvider.select((s) => s.value?.pair(pairId)));
  if (credentials == null) throw const NotPairedException();
  return credentials;
});

/// Emits false when the other device ends this pair.
final pairActiveProvider = StreamProvider.family<bool, String>(
  (ref, pairId) => ref.watch(pairingRepositoryProvider).watchPairActive(pairId),
);

final class DeviceSessionController extends AsyncNotifier<DeviceSession> {
  DeviceSettingsStore get _settings => ref.read(deviceSettingsStoreProvider);

  @override
  Future<DeviceSession> build() async {
    final settings = ref.watch(deviceSettingsStoreProvider);
    final pairs = await ref.watch(pairingCredentialsStoreProvider).readAll();
    var role = pairs.firstOrNull?.role ?? await settings.readRole();
    // A role this platform cannot play (e.g. data restored onto an iPhone) falls back to choosing again.
    if (role == DeviceRole.sender && !AppPlatform.canShareNotifications) role = null;
    return DeviceSession(role: role, disclosureAccepted: await settings.readDisclosureAccepted(), pairs: pairs);
  }

  Future<void> chooseRole(DeviceRole role) async {
    await _settings.writeRole(role);
    state = AsyncData(_current.withRole(role));
  }

  /// Back to role selection. Only possible while unpaired.
  Future<void> clearRole() async {
    if (_current.isPaired) return;
    await _settings.writeRole(null);
    state = AsyncData(_current.withRole(null));
  }

  Future<void> acceptDisclosure() async {
    await _settings.writeDisclosureAccepted();
    state = AsyncData(_current.withDisclosureAccepted());
  }

  /// Called by the pairing flows once the credentials are stored. A device paired again first gets back the history
  /// kept from before, so its screens open with it.
  Future<void> paired(PairingCredentials credentials) async {
    var continued = const <String>[];
    try {
      continued = await ref.read(continueHistoryProvider).call(credentials);
    } on Object catch (e) {
      appLog('History not continued: $e', name: 'air_reply.pairing');
    }
    await _settings.writeRole(credentials.role);
    state = AsyncData(_current.withPair(credentials));
    ref.invalidate(archivedPairsProvider);
    if (continued.isNotEmpty) {
      ref.read(continuedHistoryProvider.notifier).add([for (final id in continued) '${credentials.pairId}/$id']);
    }
  }

  /// Ends one pair. [notifyPeer] is false when the other device already ended it.
  /// Once the last device is gone, this device is unassigned again and opens on the choice of what it does (sharing
  /// or receiving); the privacy disclosure stays accepted.
  Future<void> unpair(String pairId, {bool notifyPeer = true}) async {
    await ref.read(unpairProvider).call(pairId, notifyPeer: notifyPeer);
    ref.invalidate(archivedPairsProvider);
    final next = _current.withoutPair(pairId);
    if (!next.isPaired) await _settings.writeRole(null);
    state = AsyncData(next.isPaired ? next : next.withRole(null));
  }

  DeviceSession get _current => state.value ?? DeviceSession.fresh;
}

/// Notifications that came back with a device paired again (by entry key): they were read before, so the inbox marks
/// them read rather than showing old history as new.
final continuedHistoryProvider = NotifierProvider<ContinuedHistory, List<String>>(ContinuedHistory.new);

final class ContinuedHistory extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(List<String> keys) => state = keys;
}

/// Removed devices whose history is kept on this device, newest removal first.
final archivedPairsProvider = AsyncNotifierProvider.autoDispose<ArchivedPairsController, List<ArchivedPair>>(
  ArchivedPairsController.new,
);

final class ArchivedPairsController extends AsyncNotifier<List<ArchivedPair>> {
  @override
  Future<List<ArchivedPair>> build() async =>
      (await ref.watch(archivedPairsStoreProvider).readAll())..sort((a, b) => b.unpairedAt.compareTo(a.unpairedAt));

  /// Deletes a removed device's history and its key: it can never be read again.
  Future<void> delete(String pairId) async {
    await ref.read(eraseHistoryProvider)(pairId);
    await ref.read(archivedPairsStoreProvider).remove(pairId);
    state = AsyncData([...?state.value?.where((p) => p.pairId != pairId)]);
  }

  Future<void> deleteAll() async {
    for (final pair in [...?state.value]) {
      await delete(pair.pairId);
    }
  }
}
