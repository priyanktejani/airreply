import 'dart:convert';

import 'package:air_reply/features/notifications/domain/alert_style.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Choices that change how this device behaves. Stored on the device only.
final class AppPreferences {
  const AppPreferences({
    this.alertShowsContent = true,
    this.haptics = true,
    this.mutedApps = const {},
    this.alertStyle = const AlertStyle(),
    this.autostartConfirmed = false,
    this.setupCardHidden = false,
    this.alertPromptShown = false,
    this.receiveWhenClosed = false,
  });

  factory AppPreferences.fromJson(Map<String, Object?> json) => AppPreferences(
    alertShowsContent: json['alertShowsContent'] != false,
    haptics: json['haptics'] != false,
    mutedApps: {...?(json['mutedApps'] as List<Object?>?)?.whereType<String>()},
    autostartConfirmed: json['autostartConfirmed'] == true,
    setupCardHidden: json['setupCardHidden'] == true,
    alertPromptShown: json['alertPromptShown'] == true,
    receiveWhenClosed: json['receiveWhenClosed'] == true,
  );

  /// Receivers: whether system alerts include the message text, or only "New notification" under the app's name (for shared
  /// screens and lock screens). The inbox always shows everything.
  final bool alertShowsContent;

  /// Light vibration on meaningful actions (send, toggle, confirm).
  final bool haptics;

  /// Receivers: apps whose notifications still arrive in the inbox but never raise an alert on this device.
  final Set<String> mutedApps;

  /// Receivers: how alerts present themselves, for messages and for other notifications.
  /// How alerts use the Android channels (messages pop up, others in the list). Fixed: the person chooses pop-up,
  /// sound, vibration and lock screen in the system's settings for each channel, as in other messaging apps. Choices
  /// an earlier version stored are left behind.
  final AlertStyle alertStyle;

  /// Phones with a maker's autostart switch: the person said it is on (no app can read it).
  final bool autostartConfirmed;

  /// Home's "Finish setting up" card was put away while only recommended steps were left.
  final bool setupCardHidden;

  /// Home has asked once to let alerts pop up (a phone that holds them back); later, only the Setup assistant and
  /// How alerts appear offer it.
  final bool alertPromptShown;

  /// Android receivers: also keep receiving in a background service (with a status notification), for phones that
  /// hold back pushes. Pushes alone wake a closed app, so this is off unless the person turns it on.
  final bool receiveWhenClosed;

  bool alertsFor(String packageName) => !mutedApps.contains(packageName);

  AppPreferences copyWith({
    bool? alertShowsContent,
    bool? haptics,
    Set<String>? mutedApps,
    AlertStyle? alertStyle,
    bool? autostartConfirmed,
    bool? setupCardHidden,
    bool? alertPromptShown,
    bool? receiveWhenClosed,
  }) => AppPreferences(
    alertShowsContent: alertShowsContent ?? this.alertShowsContent,
    haptics: haptics ?? this.haptics,
    mutedApps: mutedApps ?? this.mutedApps,
    alertStyle: alertStyle ?? this.alertStyle,
    autostartConfirmed: autostartConfirmed ?? this.autostartConfirmed,
    setupCardHidden: setupCardHidden ?? this.setupCardHidden,
    alertPromptShown: alertPromptShown ?? this.alertPromptShown,
    receiveWhenClosed: receiveWhenClosed ?? this.receiveWhenClosed,
  );

  Map<String, Object?> toJson() => {
    'alertShowsContent': alertShowsContent,
    'haptics': haptics,
    'mutedApps': mutedApps.toList(),
    'autostartConfirmed': autostartConfirmed,
    'setupCardHidden': setupCardHidden,
    'alertPromptShown': alertPromptShown,
    'receiveWhenClosed': receiveWhenClosed,
  };
}

abstract interface class AppPreferencesStore {
  Future<AppPreferences> load();

  Future<void> save(AppPreferences preferences);
}

final class SharedAppPreferencesStore implements AppPreferencesStore {
  SharedAppPreferencesStore(this._prefs);

  static const _key = 'air_reply.preferences.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<AppPreferences> load() async {
    try {
      final raw = await _prefs.getString(_key);
      return raw == null ? const AppPreferences() : AppPreferences.fromJson((jsonDecode(raw) as Map).cast());
    } on Object {
      return const AppPreferences();
    }
  }

  @override
  Future<void> save(AppPreferences preferences) => _prefs.setString(_key, jsonEncode(preferences.toJson()));
}
