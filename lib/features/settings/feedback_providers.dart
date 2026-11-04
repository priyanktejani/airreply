import 'package:air_reply/features/settings/data/device_details.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a `mailto:` link in the device's email app; false when there is none.
final openEmailProvider = Provider<Future<bool> Function(Uri mailto)>(
  (ref) => (mailto) async {
    try {
      return await launchUrl(mailto, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  },
);

/// The system and model, for a problem report that includes them.
final deviceDetailsProvider = Provider<Future<Map<String, String>> Function()>(
  (ref) =>
      () => deviceDetails(DeviceInfoPlugin()),
);
