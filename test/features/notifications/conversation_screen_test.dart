import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/domain/grouping.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/notifications/presentation/conversation_screen.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final t0 = DateTime(2026, 10, 31, 2, 10);

FeedEntry message(String id, String title, String text, int minute, {List<ReplyCommand> replies = const []}) =>
    FeedEntry(
      pairId: 'pixel',
      deviceName: 'Pixel 9 Pro',
      replies: replies,
      notification: MirroredNotification(
        id: id,
        canReply: true,
        // all cleared on the phone, as in the conversation that overflowed
        dismissedOnSender: true,
        content: NotificationContent(
          key: 'chat',
          packageName: 'com.whatsapp.w4b',
          appName: 'WhatsApp Business',
          title: title,
          text: text,
          postedAt: t0.add(Duration(minutes: minute)),
          conversationId: 'number',
          isMessage: true,
        ),
      ),
    );

void main() {
  testWidgets('a chat with your replies and messages from your phone fits a narrow phone', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final reply = ReplyCommand(
      id: 'r10',
      notificationId: '9',
      text: 'Test 10',
      status: ReplyStatus.sent,
      createdAt: t0.add(const Duration(minutes: 2)),
    );
    final entries = [
      message('11', 'You', 'Test 11', 3),
      // the app's copy of the reply below
      message('10', 'You', 'Test 10', 2),
      message('9', '+91 74052 94614', 'Test 9', 1, replies: [reply]),
    ];
    final thread = groupByApp(entries).single.threads.single;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...demoOverrides('receiver'), threadProvider.overrideWith((ref, _) => thread)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: ConversationScreen(source: thread.source, packageName: thread.packageName, threadKey: thread.key),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // named after the number, not "You"
    expect(find.text('+91 74052 94614'), findsOneWidget);
    // the reply once, delivered; the phone's copy of it is not a second bubble
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Test 10'), findsOneWidget);
    // the message written on the phone is yours; only theirs say they were cleared
    expect(find.text('Sent from your phone'), findsOneWidget);
    expect(find.text('Cleared on phone'), findsOneWidget);
    // and nothing runs past the edge of the screen
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
