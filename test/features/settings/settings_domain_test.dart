import 'package:air_reply/features/settings/domain/app_preferences.dart';
import 'package:air_reply/features/settings/domain/diagnostics.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('preferences', () {
    test('default to alerts with content, haptics on and nothing muted', () {
      const p = AppPreferences();
      expect(p.alertShowsContent, isTrue);
      expect(p.haptics, isTrue);
      expect(p.alertsFor('com.whatsapp'), isTrue);
    });

    test('muting an app stops its alerts only', () {
      final p = const AppPreferences().copyWith(mutedApps: {'com.Slack'});
      expect(p.alertsFor('com.Slack'), isFalse);
      expect(p.alertsFor('com.whatsapp'), isTrue);
    });

    test('are stored on the device, and unreadable data falls back to defaults', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final prefs = SharedPreferencesAsync();
      final store = SharedAppPreferencesStore(prefs);

      expect((await store.load()).haptics, isTrue);
      await store.save(const AppPreferences(alertShowsContent: false, haptics: false, mutedApps: {'a', 'b'}));
      final loaded = await store.load();
      expect(loaded.alertShowsContent, isFalse);
      expect(loaded.haptics, isFalse);
      expect(loaded.mutedApps, {'a', 'b'});

      await prefs.setString('air_reply.preferences.v1', 'not json');
      expect((await store.load()).alertShowsContent, isTrue);
    });
  });

  test('muting and unmuting apps through the controller persists', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appPreferencesProvider.notifier);
    await container.read(appPreferencesProvider.future);

    await controller.setMuted('com.Slack', muted: true);
    await controller.setMuted('com.whatsapp', muted: true);
    expect(container.read(appPreferencesProvider).value?.mutedApps, {'com.Slack', 'com.whatsapp'});

    await controller.setMuted('com.Slack', muted: false);
    expect(container.read(appPreferencesProvider).value?.mutedApps, {'com.whatsapp'});
    expect((await container.read(appPreferencesStoreProvider).load()).mutedApps, {'com.whatsapp'});
  });

  test('the diagnostics report lists every section and row', () {
    final text = diagnosticsText([
      const DiagnosticsSection('This device', [('Platform', 'android'), ('Role', 'receiver')]),
      DiagnosticsSection('Alerts', [('Alerts allowed', onOff(true)), ('Muted apps', '0'), ('Other', onOff(null))]),
    ], generatedAt: DateTime.utc(2026, 10, 24, 9));
    expect(text, startsWith('AirReply diagnostics · 2026-10-24T09:00:00.000Z'));
    expect(text, contains('[This device]\nPlatform: android\nRole: receiver'));
    expect(text, contains('Alerts allowed: on'));
    expect(text, contains('Other: unknown'));
  });
}
