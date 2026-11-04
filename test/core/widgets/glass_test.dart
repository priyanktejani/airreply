import 'dart:ui' as ui;

import 'package:air_reply/app/widgets/floating_nav_bar.dart';
import 'package:air_reply/core/theme/app_glass.dart';
import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/glass_app_bar.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/search_field.dart';
import 'package:air_reply/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme ?? AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  group('GlassContainer', () {
    testWidgets('frosts what is behind it', (tester) async {
      await tester.pumpWidget(wrap(const GlassContainer(child: Text('Frosted Content'))));

      expect(find.text('Frosted Content'), findsOneWidget);
      final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(backdrop.filter, ui.ImageFilter.blur(sigmaX: AppGlass.blur, sigmaY: AppGlass.blur));
    });

    testWidgets('is tappable with onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(GlassContainer(onTap: () => tapped = true, child: const Text('Glass'))));
      await tester.tap(find.text('Glass'));
      expect(tapped, isTrue);
    });
  });

  group('AppCard', () {
    testWidgets('is a plain card at rest and taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(AppCard(onTap: () => tapped = true, child: const Text('Tappable Card'))));

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      await tester.tap(find.text('Tappable Card'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('turns to accent glass when selected', (tester) async {
      await tester.pumpWidget(wrap(const AppCard(selected: true, child: Text('Chosen'))));
      await tester.pumpAndSettle();
      expect(find.byType(GlassContainer), findsOneWidget);
    });
  });

  group('FloatingNavBar', () {
    testWidgets('a frosted pill whose tabs select', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              items: const [
                FloatingNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
                FloatingNavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  badge: 3,
                ),
              ],
              selectedIndex: selected,
              onSelected: (i) => selected = i,
            ),
          ),
        ),
      );
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      expect(selected, 1);
    });
  });

  group('GlassScrollPage', () {
    testWidgets('pins a glass app bar and a search box that turns to glass over content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: GlassScrollPage(
              title: const Text('Title'),
              search: SearchField(onChanged: (_) {}, hint: 'Search'),
              slivers: [
                SliverList.list(children: [for (var i = 0; i < 40; i++) Text('Row $i')]),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(GlassBarBackground), findsOneWidget);
      final searchTop = tester.getTopLeft(find.text('Search')).dy;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      // the bar and the search box stay put while the rows scroll under them
      expect(find.text('Title'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Search')).dy, lessThanOrEqualTo(searchTop));
      expect(find.text('Search'), findsOneWidget);
    });
  });

  group('showAppSheet', () {
    testWidgets('opens on frosted glass with a handle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSheet<void>(context, builder: (_) => const Text('Sheet Body')),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet Body'), findsOneWidget);
      expect(find.byType(AppSheetFrame), findsOneWidget);
    });
  });
}
