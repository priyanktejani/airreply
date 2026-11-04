import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';

/// A device's status in the person's language.
extension DeviceStatusText on DeviceStatus {
  /// One or two words: "Connected", "Offline".
  String label(AppLocalizations l10n) => switch (condition) {
    DeviceCondition.receiving || DeviceCondition.sharing => l10n.deviceConnected,
    DeviceCondition.offline => l10n.deviceOffline,
    DeviceCondition.connecting => l10n.deviceConnecting,
    DeviceCondition.needsAccess => l10n.deviceNeedsAccess,
    DeviceCondition.paused => l10n.devicePaused,
    DeviceCondition.notReceiving => l10n.deviceNotReceiving,
  };

  /// A sentence: what it means for the person.
  String detail(AppLocalizations l10n) => switch (condition) {
    DeviceCondition.receiving => l10n.deviceReceivingDetail,
    DeviceCondition.sharing => l10n.deviceSharingDetail,
    DeviceCondition.offline => l10n.deviceOfflineDetail,
    DeviceCondition.connecting => l10n.deviceConnectingDetail,
    DeviceCondition.needsAccess => l10n.deviceNeedsAccessDetail,
    DeviceCondition.paused => l10n.devicePausedDetail,
    DeviceCondition.notReceiving => l10n.deviceNotReceivingDetail,
  };
}
