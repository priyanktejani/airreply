import 'dart:typed_data';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

MirroredNotification _notification(String id, String text, DateTime at) => MirroredNotification(
  id: id,
  content: NotificationContent(
    key: 'key-$id',
    packageName: 'com.whatsapp',
    appName: 'WhatsApp',
    title: 'Alex',
    text: text,
    postedAt: at,
  ),
  canReply: true,
  dismissedOnSender: false,
);

/// A pair whose loaded feed holds the newest notification, while its history on the device also has an old one.
final class _History extends RecordingMirror {
  final searched = <String>[];

  @override
  Stream<List<MirroredNotification>> watchNotifications({int limit = 2000}) =>
      Stream.value([_notification('new', 'Lunch today?', DateTime(2026, 11, 3))]);

  @override
  Stream<List<ReplyCommand>> watchReplies({int limit = 1000}) => Stream.value(const []);

  @override
  Future<HistoryMatches> searchHistory(String query, {int limit = 200}) async {
    searched.add(query);
    return 'parcel arrives tuesday'.contains(query)
        ? (
            notifications: [_notification('old', 'Parcel arrives Tuesday', DateTime(2025, 12, 1))],
            replies: const <ReplyCommand>[],
          )
        : (notifications: const <MirroredNotification>[], replies: const <ReplyCommand>[]);
  }
}

void main() {
  late _History history;
  late ProviderContainer container;

  setUp(() {
    history = _History();
    container = ProviderContainer(
      overrides: [
        pairedDevicesProvider.overrideWithValue([
          PairingCredentials(
            pairId: 'pixel',
            role: DeviceRole.receiver,
            sharedKey: Uint8List(32),
            peerName: 'Pixel 9',
            pairedAt: DateTime(2026),
          ),
        ]),
        deviceRoleProvider.overrideWithValue(DeviceRole.receiver),
        mirrorRepositoryProvider.overrideWith((ref, pairId) => history),
      ],
    );
    addTearDown(container.dispose);
  });

  /// The texts of what the inbox shows, once the history search has answered.
  Future<List<String>> shown() async {
    final sub = container.listen(visibleFeedProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return [for (final FeedEntry e in sub.read().value ?? const []) e.notification.content.text];
  }

  test('the inbox search finds a notification long gone from the loaded feed, and only while searching', () async {
    expect(await shown(), ['Lunch today?']);

    container.read(inboxFilterProvider.notifier).search('Parcel');
    expect(await shown(), ['Parcel arrives Tuesday']);
    expect(history.searched, ['parcel']);
    // found, it opens like any other
    expect(
      container.read(feedEntryProvider((pairId: 'pixel', id: 'old')))?.notification.content.text,
      'Parcel arrives Tuesday',
    );

    container.read(inboxFilterProvider.notifier).search('');
    expect(await shown(), ['Lunch today?']);
  });

  test("Home's search looks through the history too, from two characters", () async {
    final sub = container.listen(searchFeedProvider('par'), (_, _) {});
    addTearDown(sub.close);
    container.read(homeSearchQueryProvider.notifier).set('p');
    await Future<void>.delayed(Duration.zero);
    expect(history.searched, isEmpty);

    container.read(homeSearchQueryProvider.notifier).set('par');
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect([for (final e in sub.read()) e.notification.content.text], ['Parcel arrives Tuesday']);
  });

  test('a search for the phone’s own name does not dig through its history: everything of it matches', () async {
    container.read(inboxFilterProvider.notifier).search('pixel');
    await shown();
    expect(history.searched, isEmpty);
  });
}
