import 'dart:typed_data';

/// Where the sender gets an app's icon from (the Android package manager, via the bridge).
abstract interface class AppIconSource {
  Future<Uint8List?> iconFor(String packageName);
}

/// Remembers which paired device already has which app's icon, so icons travel once (then about weekly) rather than
/// with every notification.
abstract interface class IconDeliveryLog {
  Future<bool> isDue(String pairId, String packageName);

  Future<void> recordSent(String pairId, String packageName);
}
