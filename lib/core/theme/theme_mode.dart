import 'package:air_reply/core/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the light / dark / system choice.
final class ThemeModeStore {
  ThemeModeStore(this._prefs);

  static const _key = 'air_reply.theme_mode';

  final SharedPreferencesAsync _prefs;

  Future<ThemeMode> read() async {
    final saved = await _prefs.getString(_key);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ?? ThemeMode.system;
  }

  Future<void> write(ThemeMode mode) => _prefs.setString(_key, mode.name);
}

/// The mode read before the first frame (see bootstrap), so the app never flashes the wrong theme.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

final class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ThemeModeStore(ref.read(sharedPreferencesProvider)).write(mode);
  }
}
