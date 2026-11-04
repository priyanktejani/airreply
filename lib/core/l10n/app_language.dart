import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Each language the app speaks, named in itself, so a person who cannot read the current one still finds theirs.
const languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'zh': '简体中文',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
};

/// Persists the language chosen in Settings; none saved means the device's language.
final class AppLanguageStore {
  AppLanguageStore(this._prefs);

  static const _key = 'air_reply.language';

  final SharedPreferencesAsync _prefs;

  Future<Locale?> read() async {
    final saved = await _prefs.getString(_key);
    return AppLocalizations.supportedLocales.where((l) => l.languageCode == saved).firstOrNull;
  }

  Future<void> write(Locale? locale) =>
      locale == null ? _prefs.remove(_key) : _prefs.setString(_key, locale.languageCode);
}

/// The language read before the first frame (see bootstrap), so the app never opens in the wrong one.
final initialAppLocaleProvider = Provider<Locale?>((ref) => null);

/// The chosen language, or null to follow the device.
final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(AppLocaleController.new);

final class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final initial = ref.watch(initialAppLocaleProvider);
    chosenLocale = initial;
    return initial;
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    chosenLocale = locale;
    await AppLanguageStore(ref.read(sharedPreferencesProvider)).write(locale);
  }
}
