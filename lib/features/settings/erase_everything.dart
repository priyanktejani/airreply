import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/l10n/app_language.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/features/mirror/history_providers.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/pairing_providers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marks this install as seen, so a later start can tell a fresh install from an upgrade (see [forgetEarlierInstall]).
const installedKey = 'air_reply.installed';

/// Settings → Erase everything: leaves nothing of AirReply on this device or on the server.
///
/// Every pair ends (the other devices see it end and drop their side), the history of every device, kept or not, is
/// deleted, then the keys, the sign-in and its account on the server, the push token, alerts and their channels, what
/// the Android side keeps, and every setting. The app opens as new. Desktop systems never clean an app's data when it
/// is deleted, and the server never knows a phone uninstalled the app: this is how a person removes it all.
final eraseEverythingProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    Future<void> step(String what, Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (e) {
        // one step failing never stops the rest
        appLog('Erase everything: $what failed: $e', name: 'air_reply.erase');
      }
    }

    final pairs = await ref.read(pairingCredentialsStoreProvider).readAll();
    for (final pair in pairs) {
      await step('ending ${pair.pairId}', () => ref.read(unpairProvider).call(pair.pairId));
    }
    final archive = ref.read(archivedPairsStoreProvider);
    for (final kept in await archive.readAll()) {
      await step('forgetting ${kept.pairId}', () => archive.remove(kept.pairId));
    }
    await step('history', () => ref.read(eraseAllHistoryProvider)());
    await step('pending pairing', () => ref.read(pendingJoinStoreProvider).clear());
    await step('alerts', () => ref.read(mirroredAlertsProvider).clearAll());
    await step('native data', () async {
      final bridge = ref.read(notificationBridgeProvider);
      if (!bridge.isSupported) return;
      // the sharing or receiving service, even if no pair was left to stop it
      await bridge.stopSync();
      await bridge.clearNativeData();
    });
    if (AppPlatform.usesPush) await step('push token', () => FirebaseMessaging.instance.unregister());
    await step('account', () => ref.read(authGatewayProvider).signOut(deleteAccount: true));
    await step('keys', () => ref.read(secretStoreProvider).deleteAll());
    await step('settings', () async {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.clear();
      // still this install: the next start must not take the cleared store for a fresh one and wipe again
      await prefs.setBool(installedKey, true);
    });
    await step('language', () => ref.read(appLocaleProvider.notifier).set(null));
    // everything read from what was just deleted, read again: the app opens on the welcome screen
    ref
      ..invalidate(appPreferencesProvider)
      ..invalidate(archivedPairsProvider)
      ..invalidate(deviceSessionProvider);
  },
);

/// Apple keeps an app's keychain items after the app is deleted, so a reinstall would find the keys, pairs and sign-in
/// of the earlier install. A fresh install (no settings at all, and no mark of an earlier start) forgets them; an
/// upgrade from a version before the mark (settings present) keeps everything. Elsewhere the store is empty anyway.
Future<void> forgetEarlierInstall(ProviderContainer container) async {
  final prefs = container.read(sharedPreferencesProvider);
  try {
    if (await prefs.getBool(installedKey) == true) return;
    final upgrading = (await prefs.getKeys()).isNotEmpty;
    if (!upgrading) {
      await container.read(secretStoreProvider).deleteAll();
      await container.read(authGatewayProvider).signOut();
      appLog('Fresh install: forgot what an earlier install left in the keychain', name: 'air_reply');
    }
    await prefs.setBool(installedKey, true);
  } on Object catch (e) {
    appLog('Earlier install not checked: $e', name: 'air_reply');
  }
}
