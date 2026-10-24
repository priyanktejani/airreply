import 'package:air_reply/core/platform/app_platform.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// A human name for this device, shown on the other device after pairing ("Paired with Pixel 9", "Priyank's MacBook").
abstract interface class DeviceIdentity {
  Future<String> displayName();
}

final class DeviceInfoIdentity implements DeviceIdentity {
  DeviceInfoIdentity(this._info);

  final DeviceInfoPlugin _info;

  String? _cached;

  @override
  Future<String> displayName() async => _cached ??= await _lookup();

  Future<String> _lookup() async {
    try {
      final name = switch (AppPlatform.name) {
        'web' => _browserName((await _info.webBrowserInfo).browserName),
        'android' => _androidName(await _info.androidInfo),
        'iOS' => (await _info.iosInfo).modelName,
        'macOS' => (await _info.macOsInfo).computerName,
        'windows' => (await _info.windowsInfo).computerName,
        'linux' => (await _info.linuxInfo).prettyName,
        _ => '',
      };
      if (name.trim().isNotEmpty) return name.trim();
    } catch (_) {
      // Falls through to the generic name below.
    }
    return _fallback;
  }

  static String _androidName(AndroidDeviceInfo android) {
    final maker = android.manufacturer.trim();
    final model = android.model.trim();
    final name = model.toLowerCase().startsWith(maker.toLowerCase()) ? model : '$maker $model';
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }

  static String _browserName(BrowserName browser) => switch (browser) {
    BrowserName.chrome => 'Chrome',
    BrowserName.firefox => 'Firefox',
    BrowserName.safari => 'Safari',
    BrowserName.edge => 'Edge',
    BrowserName.opera => 'Opera',
    _ => 'Web browser',
  };

  static String get _fallback => switch (AppPlatform.name) {
    'iOS' => 'iPhone',
    'macOS' => 'Mac',
    'windows' => 'Windows PC',
    'linux' => 'Linux PC',
    'web' => 'Web browser',
    _ => 'Phone',
  };
}
