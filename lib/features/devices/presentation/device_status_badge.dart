import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:flutter/material.dart';

/// A device's state as a badge: icon, word and colour together.
class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({required this.status, super.key});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (status.state) {
      DeviceState.connected => (Icons.check_circle_outline, Tone.success),
      DeviceState.connecting => (Icons.sync, Tone.neutral),
      DeviceState.disconnected => (Icons.cloud_off_outlined, Tone.warning),
      DeviceState.permissionRequired => (Icons.lock_outline, Tone.error),
    };
    return StatusBadge(label: status.label, icon: icon, tone: tone, busy: status.state == DeviceState.connecting);
  }
}
