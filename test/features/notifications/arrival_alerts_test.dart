import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/notifications/background/arrival_alerts.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/settings/domain/app_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 5, 19);

MirroredNotification _n(
  String id, {
  Duration age = Duration.zero,
  bool dismissed = false,
  String app = 'com.whatsapp',
}) => MirroredNotification(
  id: id,
  content: NotificationContent(
    key: 'k-$id',
    packageName: app,
    appName: 'WhatsApp',
    title: 'Alex',
    text: 'Hi $id',
    postedAt: _now.subtract(age),
    isMessage: true,
  ),
  canReply: true,
  dismissedOnSender: dismissed,
);

void main() {
  late ArrivalAlerts arrivals;

  setUp(() => arrivals = ArrivalAlerts(MirroredAlerts(FlutterLocalNotificationsPlugin()), clock: () => _now));

  List<String> ids(List<MirroredNotification> items) => [for (final n in items) n.id];

  test('the first load never alerts; what arrives after it does, once', () {
    expect(arrivals.arrived('p', [_n('a'), _n('b')]), isEmpty, reason: 'history already there when the app opened');
    expect(ids(arrivals.arrived('p', [_n('c'), _n('a'), _n('b')])), ['c']);
    expect(arrivals.arrived('p', [_n('c'), _n('a'), _n('b')]), isEmpty, reason: 'the same feed again');
  });

  test('messages that waited in the mailbox, or were already dismissed on the phone, do not alert', () {
    arrivals.arrived('p', const []);
    final fresh = arrivals.arrived('p', [
      _n('old', age: const Duration(hours: 2)),
      _n('gone', dismissed: true),
      _n('new', age: const Duration(minutes: 3)),
    ]);
    expect(ids(fresh), ['new']);
  });

  test('each paired phone is followed on its own', () {
    arrivals.arrived('phone1', [_n('a')]);
    expect(arrivals.arrived('phone2', [_n('a'), _n('b')]), isEmpty, reason: "phone2's first load");
    expect(ids(arrivals.arrived('phone1', [_n('b'), _n('a')])), ['b']);
  });

  test('apps muted on this device never alert', () {
    const preferences = AppPreferences(mutedApps: {'com.whatsapp'});
    expect(ArrivalAlerts.alertable(_n('a'), preferences), isFalse);
    expect(ArrivalAlerts.alertable(_n('a', app: 'org.telegram'), preferences), isTrue);
  });
}
