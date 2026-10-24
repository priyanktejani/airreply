import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/features/notifications/domain/inbox_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PreferencesInboxStateStore implements InboxStateStore {
  PreferencesInboxStateStore(this._prefs);

  static const _key = 'air_reply.inbox.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<InboxState?> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return InboxState.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(InboxState state) => _prefs.setString(_key, jsonEncode(state.toJson()));
}

/// App icons that arrived with mirrored notifications, kept so every later notification of that app shows it.
final class AppIconCache {
  AppIconCache(this._prefs);

  static const _key = 'air_reply.app_icons.v1';
  static const _maxApps = 150;

  final SharedPreferencesAsync _prefs;

  Future<Map<String, Uint8List>> load() async {
    try {
      final raw = await _prefs.getString(_key);
      if (raw == null) return {};
      return {for (final e in (jsonDecode(raw) as Map).cast<String, String>().entries) e.key: base64.decode(e.value)};
    } on Object {
      return {};
    }
  }

  Future<void> save(Map<String, Uint8List> icons) {
    final kept = icons.entries.toList();
    final trimmed = kept.length <= _maxApps ? kept : kept.sublist(kept.length - _maxApps);
    return _prefs.setString(_key, jsonEncode({for (final e in trimmed) e.key: base64.encode(e.value)}));
  }
}
