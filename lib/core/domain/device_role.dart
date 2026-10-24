/// What this install does in a pair. Chosen once at onboarding; changing it means unpairing first.
enum DeviceRole {
  /// Android phone whose notifications are mirrored, and which executes replies.
  sender,

  /// Device that shows the mirrored feed and writes replies.
  receiver;

  static DeviceRole? tryParse(String? value) => DeviceRole.values.where((r) => r.name == value).firstOrNull;
}
