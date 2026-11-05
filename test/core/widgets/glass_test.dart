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
    testWidgets('the bar slides away while reading and comes back on scrolling back; the search box stays', (
      tester,
    ) async {
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
                SliverList.list(children: [for (var i = 0; i < 80; i++) Text('Row $i')]),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(GlassBarBackground), findsOneWidget);
      // hidden: faded out, or not built at all (with no status bar, nothing of the bar is left)
      double opacityOf(String text) => find.text(text).evaluate().isEmpty
          ? 0
          : tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;
      final titleTop = tester.getTopLeft(find.text('Title')).dy;
      final searchTop = tester.getTopLeft(find.text('Search')).dy;
      expect(opacityOf('Title'), 1);

      // reading on: the bar goes, the search box moves up into its place and stays
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(opacityOf('Title'), 0);
      final pinned = tester.getTopLeft(find.text('Search')).dy;
      expect(pinned, lessThan(searchTop));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Search')).dy, pinned);

      // scrolling back a little, far from the top: the bar is back at once, with the search box under it
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(opacityOf('Title'), 1);
      expect(tester.getTopLeft(find.text('Title')).dy, titleTop);
      expect(tester.getTopLeft(find.text('Search')).dy, searchTop);
      expect(find.text('Row 0'), findsNothing);

      // back and forth, many times over: every snap animates, and none of them runs out of tickers
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 40));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(opacityOf('Title'), 1);
    });
  });

  testWidgets('a bar moved in the tree (a tab switch, a route transition) still snaps', (tester) async {
    // the page keeps its state while its render objects detach and attach again; the header then needs a new ticker
    final page = GlobalKey();
    var wrapped = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            final child = KeyedSubtree(
              key: page,
              child: GlassScrollPage(
                title: const Text('Title'),
                slivers: [
                  SliverList.list(children: [for (var i = 0; i < 80; i++) Text('Row $i')]),
                ],
              ),
            );
            return Scaffold(
              body: wrapped ? Padding(padding: EdgeInsets.zero, child: child) : child,
            );
          },
        ),
      ),
    );
    Future<void> snapBothWays() async {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 40));
      await tester.pumpAndSettle();
    }

    await snapBothWays();
    for (var i = 0; i < 3; i++) {
      rebuild(() => wrapped = !wrapped);
      await tester.pumpAndSettle();
      await snapBothWays();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('under a status bar, a strip of glass stays and the search box pins below it, never under the icons', (
    tester,
  ) async {
    const statusBar = 47.0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(top: statusBar)),
          child: child!,
        ),
        home: Scaffold(
          body: GlassScrollPage(
            title: const Text('Title'),
            search: SearchField(onChanged: (_) {}, hint: 'Search'),
            slivers: [
              SliverList.list(children: [for (var i = 0; i < 80; i++) Text('Row $i')]),
            ],
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.text('Title')).dy, greaterThan(statusBar));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    // the glass is still there, just the status bar's height of it
    final glass = tester.getRect(find.byType(GlassBarBackground));
    expect(glass.top, 0);
    expect(glass.height, statusBar);
    // the search box sits right under it
    final search = tester.getRect(find.byType(SearchField));
    expect(search.top, greaterThanOrEqualTo(statusBar));
    expect(search.top, lessThan(statusBar + 20));
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
