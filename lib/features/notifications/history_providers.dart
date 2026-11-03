import 'dart:async';

import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/domain/entities/history_query.dart';
import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/notifications/domain/feed.dart';
import 'package:air_reply/features/notifications/notifications_providers.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Search and browsing over the whole history on this device, a page at a time, straight from the database: the feed
// itself keeps only the newest notifications loaded. Results are a snapshot of what had arrived when they were asked
// for, so they stay put while new notifications come in; those are counted ([newResultsProvider]) and added on request.

/// Where history is shown: the inbox's search, Home's search, or one phone's history.
typedef HistoryScope = ({String view, String? pairId});

const inboxSearch = (view: 'inbox', pairId: null);
const homeSearch = (view: 'home', pairId: null);
HistoryScope deviceHistory(String pairId) => (view: 'device', pairId: pairId);

/// One pair's pages so far.
final class PairPages {
  const PairPages({this.notifications = const [], this.replies = const [], this.next, this.done = false, this.saved});

  final List<MirroredNotification> notifications;
  final List<ReplyCommand> replies;

  /// Where its next page starts.
  final HistoryCursor? next;
  final bool done;

  /// How far this pair's history went when the results were taken: later pages read no further, so they hold still.
  final int? saved;

  /// The oldest notification read so far: nothing older is known yet.
  DateTime? get frontier => notifications.isEmpty ? null : notifications.last.postedAt;

  /// [page] after these, each notification and reply once (a duplicate record is dropped).
  PairPages append(HistoryPage page) {
    final ids = {for (final n in notifications) n.id};
    final replyIds = {for (final r in replies) r.id};
    return PairPages(
      notifications: [
        ...notifications,
        for (final n in page.notifications)
          if (ids.add(n.id)) n,
      ],
      replies: [
        ...replies,
        for (final r in page.replies)
          if (replyIds.add(r.id)) r,
      ],
      next: page.next,
      done: page.next == null,
      saved: page.saved,
    );
  }

  /// [pages] of what arrived since [saved], merged in by time: the next page still starts where it did.
  PairPages including(List<HistoryPage> pages, {required int saved}) {
    final ids = {for (final n in notifications) n.id};
    final replyIds = {for (final r in replies) r.id};
    final fresh = [
      for (final p in pages)
        for (final n in p.notifications)
          if (ids.add(n.id)) n,
    ];
    return PairPages(
      notifications: [...notifications, ...fresh]..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
      replies: [
        ...replies,
        for (final p in pages)
          for (final r in p.replies)
            if (replyIds.add(r.id)) r,
      ],
      next: next,
      done: done,
      saved: saved,
    );
  }
}

/// History shown in one [HistoryScope]: the query, and the pages read for each pair.
final class HistoryResults {
  const HistoryResults({this.query, this.pages = const {}, this.total, this.loading = false, this.error});

  static const idle = HistoryResults();

  /// Null while nothing is shown.
  final HistoryQuery? query;
  final Map<String, PairPages> pages;

  /// Matches over all pages, once counted.
  final int? total;
  final bool loading;
  final Object? error;

  bool get isActive => query != null;
  bool get hasMore => pages.values.any((p) => !p.done);

  /// Notifications older than this are held back until every pair has read that far, so the merged list never has a
  /// gap that a later page would fill.
  DateTime? get _shownFrom {
    DateTime? from;
    for (final p in pages.values) {
      if (p.done) continue;
      final f = p.frontier;
      if (f == null) return DateTime.fromMillisecondsSinceEpoch(1 << 52); // nothing read yet: hold everything back
      if (from == null || f.isAfter(from)) from = f;
    }
    return from;
  }

  /// What is shown for [pairId], newest first.
  List<MirroredNotification> shown(String pairId) {
    final p = pages[pairId];
    if (p == null) return const [];
    final from = _shownFrom;
    return from == null
        ? p.notifications
        : [
            for (final n in p.notifications)
              if (!n.postedAt.isBefore(from)) n,
          ];
  }

  /// The oldest notification shown, of any pair: what arrives newer than this is new to the reader.
  DateTime? get oldestShown {
    DateTime? oldest;
    for (final id in pages.keys) {
      final shownHere = shown(id);
      if (shownHere.isEmpty) continue;
      final t = shownHere.last.postedAt;
      if (oldest == null || t.isBefore(oldest)) oldest = t;
    }
    return oldest;
  }

  bool contains(FeedEntry e) => pages[e.pairId]?.notifications.any((n) => n.id == e.notification.id) ?? false;

  HistoryResults copyWith({
    Map<String, PairPages>? pages,
    int? total,
    bool? loading,
    Object? error,
    HistoryQuery? query,
  }) => HistoryResults(
    query: query ?? this.query,
    pages: pages ?? this.pages,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    error: error,
  );
}

final historyResultsProvider = NotifierProvider.family<HistoryResultsController, HistoryResults, HistoryScope>(
  HistoryResultsController.new,
);

/// Reads pages of history for one [HistoryScope]. A new query (typing on) interrupts the one before: its late pages are
/// dropped.
final class HistoryResultsController extends Notifier<HistoryResults> {
  HistoryResultsController(this.scope);

  final HistoryScope scope;

  static const pageSize = 50;

  /// Bumped by every new query, so pages of an earlier one are recognised and dropped.
  var _generation = 0;
  List<String> _pairIds = const [];

  @override
  HistoryResults build() {
    // The two searches follow what is typed into them; a phone's history is opened by its screen.
    switch (scope.view) {
      case 'inbox':
        ref.listen(inboxFilterProvider, (_, filter) => _follow(filter));
        // a search already typed: shown once this is built (state cannot change while building)
        if (ref.read(inboxFilterProvider).query.trim().isNotEmpty) {
          scheduleMicrotask(() => _follow(ref.read(inboxFilterProvider)));
        }
      case 'home':
        ref.listen(homeSearchQueryProvider, (_, query) => _follow(FeedFilter(query: query)));
        if (ref.read(homeSearchQueryProvider).trim().isNotEmpty) {
          scheduleMicrotask(() => _follow(FeedFilter(query: ref.read(homeSearchQueryProvider))));
        }
    }
    // a pair that is removed leaves the results
    ref.listen(pairedDevicesProvider, (_, pairs) {
      final ids = {for (final p in pairs) p.pairId};
      if (state.pages.keys.any((id) => !ids.contains(id))) {
        state = state.copyWith(
          pages: {
            for (final e in state.pages.entries)
              if (ids.contains(e.key)) e.key: e.value,
          },
        );
      }
    });
    return HistoryResults.idle;
  }

  void _follow(FeedFilter filter) {
    final text = filter.query.trim();
    if (text.isEmpty) {
      close();
      return;
    }
    final now = DateTime.now();
    final query = HistoryQuery(
      text: text,
      packageName: filter.packageName,
      after: switch (filter.period) {
        FeedPeriod.all => null,
        FeedPeriod.today => DateTime(now.year, now.month, now.day),
        FeedPeriod.week => DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
      },
    );
    final q = state.query;
    if (q != null && q.text == query.text && q.packageName == query.packageName && q.after == query.after) {
      if (filter.pairId == (_pairIds.length == 1 ? _pairIds.single : null)) return; // same search
    }
    unawaited(open(query, pairIds: filter.pairId == null ? null : [filter.pairId!]));
  }

  /// Shows [query] over [pairIds] (every paired device by default), from its first page: a snapshot of what had been
  /// saved by then.
  Future<void> open(HistoryQuery query, {List<String>? pairIds}) async {
    final generation = ++_generation;
    _pairIds = pairIds ?? [for (final p in ref.read(pairedDevicesProvider)) p.pairId];
    state = HistoryResults(query: query, pages: {for (final id in _pairIds) id: const PairPages()});
    await loadMore();
    if (generation == _generation) unawaited(_count(query, generation));
  }

  /// Reads the next page of every pair that the merged list is waiting on.
  Future<void> loadMore() async {
    final query = state.query;
    if (query == null || state.loading || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(loading: true);
    try {
      final waiting = [
        for (final MapEntry(key: id, value: p) in state.pages.entries)
          if (!p.done && (p.frontier == null || !p.frontier!.isBefore(state._shownFrom!))) id,
      ];
      final read = await Future.wait([
        for (final id in waiting)
          ref
              .read(notificationFeedProvider(id))
              .browseHistory(
                query.saved(upTo: state.pages[id]!.saved),
                after: state.pages[id]!.next,
                limit: pageSize,
              ),
      ]);
      if (generation != _generation) return; // a newer query took over
      state = state.copyWith(
        loading: false,
        pages: {...state.pages, for (final (i, id) in waiting.indexed) id: state.pages[id]!.append(read[i])},
      );
    } on Object catch (e, st) {
      if (generation != _generation) return;
      appLog('History page failed', error: e, stackTrace: st, name: 'air_reply.history');
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Adds what arrived since the snapshot, in its place by time (late messages too), and moves the snapshot on: the
  /// query, the pages read and the place in the list stay.
  Future<void> includeNew() async {
    final query = state.query;
    if (query == null) return;
    final generation = _generation;
    try {
      final pages = {...state.pages};
      var added = 0;
      for (final id in _pairIds) {
        final current = pages[id] ?? const PairPages();
        final feed = ref.read(notificationFeedProvider(id));
        final read = <HistoryPage>[];
        int? upTo;
        HistoryCursor? cursor;
        do {
          final page = await feed.browseHistory(
            query.saved(after: current.saved, upTo: upTo),
            after: cursor,
            limit: pageSize,
          );
          if (generation != _generation) return;
          read.add(page);
          upTo = page.saved;
          cursor = page.next;
        } while (cursor != null);
        pages[id] = current.including(read, saved: upTo);
        added += pages[id]!.notifications.length - current.notifications.length;
      }
      state = state.copyWith(
        pages: pages,
        total: state.total == null ? null : state.total! + added,
        error: state.error,
      );
    } on Object catch (e, st) {
      appLog('Could not add new notifications', error: e, stackTrace: st, name: 'air_reply.history');
    }
  }

  /// Nothing shown: the results leave the feed.
  void close() {
    _generation++;
    if (state.isActive) state = HistoryResults.idle;
  }

  Future<void> _count(HistoryQuery query, int generation) async {
    try {
      var total = 0;
      for (final id in _pairIds) {
        total += await ref.read(notificationFeedProvider(id)).countHistory(query.saved(upTo: state.pages[id]?.saved));
      }
      if (generation == _generation) state = state.copyWith(total: total, error: state.error);
    } on Object {
      // the count is a nicety: the pages still show
    }
  }
}

/// The notifications of [scope]'s results, as entries, newest first.
final historyEntriesProvider = Provider.family<List<FeedEntry>, HistoryScope>((ref, scope) {
  final results = ref.watch(historyResultsProvider(scope));
  if (!results.isActive) return const [];
  final names = {for (final p in ref.watch(pairedDevicesProvider)) p.pairId: p.peerName};
  return mergeFeeds([
    for (final MapEntry(key: id, value: pages) in results.pages.entries)
      buildFeed(results.shown(id), pages.replies, pairId: id, deviceName: names[id] ?? ''),
  ], dedupe: ref.watch(deviceRoleProvider) == DeviceRole.sender);
});

/// Notifications that arrived since [scope]'s results were taken and would be among those shown: the "new
/// notifications" that can be added on request. One sent long ago and delivered late counts too, when it falls among
/// what is shown.
final newResultsProvider = Provider.autoDispose.family<int, HistoryScope>((ref, scope) {
  final results = ref.watch(historyResultsProvider(scope));
  final query = results.query;
  if (query == null) return 0;
  final oldest = results.oldestShown;
  final filter = FeedFilter(query: query.text, packageName: query.packageName);
  return [
    for (final e in ref.watch(liveFeedProvider).value ?? const <FeedEntry>[])
      if (results.pages.containsKey(e.pairId) &&
          (!results.hasMore || (oldest != null && !e.postedAt.isBefore(oldest))) &&
          (query.after == null || e.postedAt.isAfter(query.after!)) &&
          filter.matches(e, isRead: (_) => true) &&
          !results.contains(e))
        e,
  ].length;
});

/// Paired devices whose name contains [query]: search finds a phone itself, not every notification it sent.
final deviceMatchesProvider = Provider.autoDispose.family<List<PairingCredentials>, String>((ref, query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final p in ref.watch(pairedDevicesProvider))
      if (p.peerName.toLowerCase().contains(q)) p,
  ];
});

/// The results every view shows now, by pair: they join the feed, so a found notification groups with its chat and
/// opens like any other.
List<HistoryResults> shownHistory(Ref ref) => [
  ref.watch(historyResultsProvider(inboxSearch)),
  ref.watch(historyResultsProvider(homeSearch)),
  for (final p in ref.watch(pairedDevicesProvider)) ref.watch(historyResultsProvider(deviceHistory(p.pairId))),
];
