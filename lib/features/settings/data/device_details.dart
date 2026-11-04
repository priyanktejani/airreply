import 'package:air_reply/core/platform/app_platform.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// What a problem report says about the device: the system and model, never a name the person gave it, their
/// notifications or keys.
Future<Map<String, String>> deviceDetails(DeviceInfoPlugin info) async {
  final details = {'Platform': AppPlatform.name};
  try {
    switch (AppPlatform.name) {
      case 'web':
        final web = await info.webBrowserInfo;
        details['Browser'] = '${web.browserName.name} ${web.appVersion ?? ''}'.trim();
      case 'android':
        final android = await info.androidInfo;
        details['Device'] = '${android.manufacturer} ${android.model}';
        details['System'] = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
      case 'iOS':
        final ios = await info.iosInfo;
        details['Device'] = ios.modelName;
        details['System'] = '${ios.systemName} ${ios.systemVersion}';
      case 'macOS':
        final mac = await info.macOsInfo;
        details['Device'] = mac.modelName;
        details['System'] = 'macOS ${mac.osRelease}';
      case 'windows':
        final windows = await info.windowsInfo;
        details['System'] = '${windows.productName} ${windows.displayVersion}';
      case 'linux':
        details['System'] = (await info.linuxInfo).prettyName;
    }
  } on Object {
    // the platform alone still helps
  }
  return details;
}
