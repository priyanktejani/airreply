import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/session/domain/device_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PreferencesDeviceSettingsStore implements DeviceSettingsStore {
  PreferencesDeviceSettingsStore(this._prefs);

  static const _roleKey = 'air_reply.role';
  static const _disclosureKey = 'air_reply.disclosure_accepted';

  final SharedPreferencesAsync _prefs;

  @override
  Future<DeviceRole?> readRole() async => DeviceRole.tryParse(await _prefs.getString(_roleKey));

  @override
  Future<void> writeRole(DeviceRole? role) =>
      role == null ? _prefs.remove(_roleKey) : _prefs.setString(_roleKey, role.name);

  @override
  Future<bool> readDisclosureAccepted() async => await _prefs.getBool(_disclosureKey) ?? false;

  @override
  Future<void> writeDisclosureAccepted() => _prefs.setBool(_disclosureKey, true);
}
