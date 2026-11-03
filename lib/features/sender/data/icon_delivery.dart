import 'dart:convert';
import 'dart:typed_data';

import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/sender/domain/app_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class BridgeAppIconSource implements AppIconSource {
  BridgeAppIconSource(this._bridge);

  final NotificationBridge _bridge;

  @override
  Future<Uint8List?> iconFor(String packageName) async {
    try {
      return await _bridge.appIcon(packageName);
    } on Object {
      return null; // an icon is a nicety; never block a notification on it
    }
  }
}

final class PreferencesIconDeliveryLog implements IconDeliveryLog {
  PreferencesIconDeliveryLog(this._prefs, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _key = 'air_reply.icons_sent.v1';
  static const resendAfter = Duration(days: 7);
  static const _maxEntries = 400;

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _clock;
  Map<String, int>? _cache;

  Future<Map<String, int>> _entries() async {
    if (_cache case final cache?) return cache;
    try {
      final raw = await _prefs.getString(_key);
      return _cache = raw == null ? {} : (jsonDecode(raw) as Map).cast<String, int>();
    } on Object {
      return _cache = {};
    }
  }

  @override
  Future<bool> isDue(String pairId, String packageName) async {
    final sentAt = (await _entries())['$pairId|$packageName'];
    return sentAt == null || _clock().difference(DateTime.fromMillisecondsSinceEpoch(sentAt)) > resendAfter;
  }

  @override
  Future<void> recordSent(String pairId, String packageName) async {
    final entries = await _entries();
    entries['$pairId|$packageName'] = _clock().millisecondsSinceEpoch;
    if (entries.length > _maxEntries) {
      final oldest = entries.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      for (final e in oldest.take(entries.length - _maxEntries)) {
        entries.remove(e.key);
      }
    }
    await _prefs.setString(_key, jsonEncode(entries));
  }

  @override
  Future<void> keepOnly(Set<String> pairIds) async {
    final entries = await _entries();
    final kept = {
      for (final e in entries.entries)
        if (pairIds.contains(e.key.split('|').first)) e.key: e.value,
    };
    if (kept.length == entries.length) return;
    _cache = kept;
    await _prefs.setString(_key, jsonEncode(kept));
  }
}
