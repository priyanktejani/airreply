import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Choices that change how this device behaves. Stored on the device only.
final class AppPreferences {
  const AppPreferences({this.alertShowsContent = true, this.haptics = true, this.mutedApps = const {}});

  factory AppPreferences.fromJson(Map<String, Object?> json) => AppPreferences(
    alertShowsContent: json['alertShowsContent'] != false,
    haptics: json['haptics'] != false,
    mutedApps: {...?(json['mutedApps'] as List<Object?>?)?.whereType<String>()},
  );

  /// Receivers: whether system alerts include the message text, or only "New notification" under the app's name (for shared
  /// screens and lock screens). The inbox always shows everything.
  final bool alertShowsContent;

  /// Light vibration on meaningful actions (send, toggle, confirm).
  final bool haptics;

  /// Receivers: apps whose notifications still arrive in the inbox but never raise an alert on this device.
  final Set<String> mutedApps;

  bool alertsFor(String packageName) => !mutedApps.contains(packageName);

  AppPreferences copyWith({bool? alertShowsContent, bool? haptics, Set<String>? mutedApps}) => AppPreferences(
    alertShowsContent: alertShowsContent ?? this.alertShowsContent,
    haptics: haptics ?? this.haptics,
    mutedApps: mutedApps ?? this.mutedApps,
  );

  Map<String, Object?> toJson() => {
    'alertShowsContent': alertShowsContent,
    'haptics': haptics,
    'mutedApps': mutedApps.toList(),
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
