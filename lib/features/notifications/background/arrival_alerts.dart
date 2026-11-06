import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/settings/domain/app_preferences.dart';

/// Turns a pair's feed, each time it changes, into alerts for what is new: once per notification, only recent ones
/// (messages that waited in the mailbox while the device was away arrive together and do not all alert), never for
/// apps muted on this device. Shared by the open app and the background engine that keeps an Android device
/// receiving while AirReply is closed; both use the notification's own alert id, so one never alerts twice.
final class ArrivalAlerts {
  ArrivalAlerts(this._alerts, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final MirroredAlerts _alerts;
  final DateTime Function() _clock;

  static const window = Duration(minutes: 10);

  /// Per pair, the notification ids already known. Null until that pair's first load, which never alerts.
  final _seen = <String, Set<String>>{};

  /// What [items] holds that the last call for [pairId] did not, recent and still open on the phone. Whether each may
  /// alert (a muted app) is [alertable]'s to say, with the preferences as they are when it shows.
  List<MirroredNotification> arrived(String pairId, List<MirroredNotification> items) {
    final known = _seen[pairId];
    _seen[pairId] = {for (final n in items) n.id};
    if (known == null) return const [];
    final recent = _clock().subtract(window);
    return [
      for (final n in items)
        if (!known.contains(n.id) && !n.dismissedOnSender && n.postedAt.isAfter(recent)) n,
    ];
  }

  static bool alertable(MirroredNotification n, AppPreferences preferences) =>
      preferences.alertsFor(n.content.packageName);

  Future<void> show(
    MirroredNotification notification, {
    required String pairId,
    required AppPreferences preferences,
    String? deviceName,
  }) => _alerts.show(notification, pairId: pairId, deviceName: deviceName, showContent: preferences.alertShowsContent);
}
