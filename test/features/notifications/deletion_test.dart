import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

void main() {
  group('an entry key', () {
    test('is written in one place and read back exactly', () {
      final key = FeedEntry.keyOf('pixel', 'n1');
      expect(key, 'pixel/n1');
      expect(FeedEntry.parseKey(key), (pairId: 'pixel', id: 'n1'));
      // ids may hold slashes: only the first one separates the pair
      expect(FeedEntry.parseKey('pixel/a/b'), (pairId: 'pixel', id: 'a/b'));
    });

    test('anything else is refused, never half-read', () {
      for (final bad in ['', 'pixel', '/n1', 'pixel/']) {
        expect(FeedEntry.parseKey(bad), isNull, reason: bad);
      }
    });
  });

  group('deleting', () {
    late RecordingMirror pixel;
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      pixel = RecordingMirror();
      container = ProviderContainer(
        overrides: [
          notificationFeedProvider.overrideWith((ref, pairId) => pixel),
          notificationBridgeProvider.overrideWithValue(FakeNotificationBridge()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(inboxStateProvider, (_, _) {});
      await container.read(inboxStateProvider.future);
    });

    test('stage hides at once, undo brings back, commit deletes from the history', () async {
      final deletions = container.read(deletedEntriesProvider.notifier);
      deletions.stage(['pixel/n1', 'pixel/n2']);
      expect(container.read(deletedEntriesProvider), {'pixel/n1', 'pixel/n2'});

      deletions.undo(['pixel/n2']);
      expect(container.read(deletedEntriesProvider), {'pixel/n1'});

      expect(await deletions.commit(['pixel/n1']), isTrue);
      expect(pixel.deleted, ['n1'], reason: 'by its id, from its own pair');
    });

    test('a delete that cannot be saved puts the notifications back, nothing vanishes unsaved', () async {
      pixel.deleteFails = StateError('database is locked');
      final deletions = container.read(deletedEntriesProvider.notifier)..stage(['pixel/n1']);

      expect(await deletions.commit(['pixel/n1']), isFalse);
      expect(container.read(deletedEntriesProvider), isEmpty);
      expect(pixel.deleted, isEmpty);
    });

    test('deleting forgets the read marks of what is gone', () async {
      final inbox = container.read(inboxStateProvider.notifier);
      await inbox.markRead(['pixel/n1', 'pixel/n2']);
      await inbox.delete(['pixel/n1']);
      expect(container.read(inboxStateProvider).value!.read, {'pixel/n2'});
    });
  });
}
