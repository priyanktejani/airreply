import 'package:air_reply/core/domain/device_role.dart';

/// Non-secret, per-install choices.
abstract interface class DeviceSettingsStore {
  Future<DeviceRole?> readRole();

  Future<void> writeRole(DeviceRole? role);

  Future<bool> readDisclosureAccepted();

  Future<void> writeDisclosureAccepted();
}
