import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('counts read naturally, from none to many', () {
    expect(en.inboxUnread(0), 'All read');
    expect(en.inboxUnread(1), '1 unread');
    expect(en.inboxUnread(12), '12 unread');
    expect(en.tabNotificationsUnread(0), 'Notifications');
    expect(en.tabNotificationsUnread(1), 'Notifications, 1 unread');
    expect(en.tabNotificationsUnread(3), 'Notifications, 3 unread');
  });

  test('English is the template and the fallback for languages without their own strings', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.localizationsDelegates, contains(AppLocalizations.delegate));
  });

  test('Hindi, Chinese, Spanish, French and German are supported', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'hi', 'zh', 'es', 'fr', 'de']),
    );
  });

  test('each language says counts and times in its own words', () async {
    await initializeDateFormatting();
    final now = DateTime(2026, 10, 24, 15);
    final expected = {
      'hi': ('3 अपठित', '4 मिनट पहले', 'कल'),
      'zh': ('3 条未读', '4 分钟前', '昨天'),
      'es': ('3 sin leer', 'hace 4 min', 'Ayer'),
      'fr': ('3 non lues', 'il y a 4 min', 'Hier'),
      'de': ('3 ungelesen', 'vor 4 Min.', 'Gestern'),
    };
    for (final MapEntry(key: code, value: (unread, ago, yesterday)) in expected.entries) {
      final l10n = lookupAppLocalizations(Locale(code));
      expect(l10n.inboxUnread(3), unread, reason: code);
      expect(formatAgo(l10n, DateTime(2026, 10, 24, 14, 56), now: now), ago, reason: code);
      expect(formatDayLabel(l10n, DateTime(2026, 10, 23, 9), now: now), yesterday, reason: code);
      // weekday names come from intl, in the same language
      expect(formatDayLabel(l10n, DateTime(2026, 10, 20), now: now), isNot('Tuesday'), reason: code);
    }
  });

  testWidgets('screens read their strings from the context', (tester) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            title = context.l10n.appTitle;
            return Text(context.l10n.tabHome);
          },
        ),
      ),
    );
    expect(title, 'AirReply');
    expect(find.text('Home'), findsOneWidget);
  });
}
