import 'dart:ui';

import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:air_reply/l10n/app_localizations.dart';

/// The app's strings in the user's language: `context.l10n.tabHome`. Every user-facing string lives in
/// `lib/l10n/app_en.arb` (other languages: `app_<code>.arb` beside it), never as a literal in a widget.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The language chosen in Settings in this isolate, or null to follow the device. Kept by `AppLocaleController`;
/// a background isolate loads it from `AppLanguageStore` before it raises an alert.
Locale? chosenLocale;

/// The strings in the app's language (the one chosen in Settings, else the device's), for code with no
/// [BuildContext]: alerts, which may be raised in a background isolate before any widget runs.
AppLocalizations appL10n() => lookupAppLocalizations(
  chosenLocale ?? basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales),
);
