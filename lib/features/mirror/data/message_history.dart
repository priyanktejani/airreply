import 'dart:convert';
import 'dart:math';

import 'package:air_reply/core/logging/app_log.dart';
import 'package:air_reply/features/mirror/data/history_database.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mirrored notification as this device keeps it. [payload] is still sealed with the pair's key, so history on the
/// device is as private as it was in transit, and unreadable once the pair (and its key) is gone.
final class StoredNotification {
  const StoredNotification({
    required this.id,
    required this.payload,
    required this.postedAt,
    this.keyHash,
    this.canReply = false,
    this.dismissed = false,
  });

  factory StoredNotification._fromRow(NotificationRow row) => StoredNotification(
    id: row.id,
    payload: row.payload,
    postedAt: DateTime.fromMillisecondsSinceEpoch(row.postedAt),
    keyHash: row.keyHash,
    canReply: row.canReply,
    dismissed: row.dismissed,
  );

  /// As the first version of the history kept it, in SharedPreferences.
  factory StoredNotification._fromLegacy(String id, Map<String, Object?> json) => StoredNotification(
    id: id,
    payload: json['p']! as String,
    postedAt: DateTime.fromMillisecondsSinceEpoch((json['at']! as num).toInt()),
    keyHash: json['k'] as String?,
    canReply: json['r'] == true,
    dismissed: json['d'] == true,
  );

  final String id;
  final String payload;
  final DateTime postedAt;

  /// The blind index of the source notification's key: how a later dismissal finds it.
  final String? keyHash;
  final bool canReply;

  /// Flagged dismissed in the document itself (senders before dismissals had their own documents).
  final bool dismissed;

  HistoryNotificationsCompanion _row(String pairId) => HistoryNotificationsCompanion.insert(
    pairId: pairId,
    id: id,
    payload: payload,
    postedAt: postedAt.millisecondsSinceEpoch,
    keyHash: Value(keyHash),
    canReply: Value(canReply),
    dismissed: Value(dismissed),
  );
}

/// A reply as this device keeps it, its text still sealed with the pair's key.
final class StoredReply {
  const StoredReply({
    required this.id,
    required this.notificationId,
    required this.payload,
    required this.status,
    required this.createdAt,
  });

  factory StoredReply._fromRow(ReplyRow row) => StoredReply(
    id: row.id,
    notificationId: row.notificationId,
    payload: row.payload,
    status: ReplyStatus.parse(row.status),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  factory StoredReply._fromLegacy(String id, Map<String, Object?> json) => StoredReply(
    id: id,
    notificationId: json['n']! as String,
    payload: json['p']! as String,
    status: ReplyStatus.parse(json['s']),
    createdAt: DateTime.fromMillisecondsSinceEpoch((json['at']! as num).toInt()),
  );

  final String id;
  final String notificationId;
  final String payload;
  final ReplyStatus status;
  final DateTime createdAt;

  StoredReply withStatus(ReplyStatus status) =>
      StoredReply(id: id, notificationId: notificationId, payload: payload, status: status, createdAt: createdAt);

  HistoryRepliesCompanion _row(String pairId) => HistoryRepliesCompanion.insert(
    pairId: pairId,
    id: id,
    notificationId: notificationId,
    payload: payload,
    status: status.wire,
    createdAt: createdAt.millisecondsSinceEpoch,
  );
}

/// The newest of one pair's history, by document id; dismissals by key hash, with when they happened.
final class HistoryRecords {
  HistoryRecords({
    Map<String, StoredNotification>? notifications,
    Map<String, StoredReply>? replies,
    Map<String, DateTime>? dismissals,
  }) : notifications = notifications ?? {},
       replies = replies ?? {},
       dismissals = dismissals ?? {};

  final Map<String, StoredNotification> notifications;
  final Map<String, StoredReply> replies;
  final Map<String, DateTime> dismissals;

  /// Whether the sender's notification was gone when [n] was posted or later: a dismissal covers what came before it,
  /// not a new message that re-uses the same notification.
  bool isDismissed(StoredNotification n) {
    if (n.dismissed) return true;
    final at = n.keyHash == null ? null : dismissals[n.keyHash];
    return at != null && !n.postedAt.isAfter(at);
  }
}

/// This device's copy of one pair's history, in the [HistoryDatabase]. As in WhatsApp, messages live on the devices:
/// the server holds each one only until the other device has it (see [MirrorSyncRepository]).
///
/// Everything is kept; [load] reads the newest [maxNotifications] and [maxReplies], which is what the screens show.
/// [revision] changes when another isolate or engine writes (the sender's background engine publishes), so the app
/// can tell when to read again.
final class MessageHistory {
  MessageHistory(this._db, this.pairId, {this.maxNotifications = 2000, this.maxReplies = 1000, this._legacy});

  final HistoryDatabase _db;
  final String pairId;
  final int maxNotifications;
  final int maxReplies;

  /// Where the first version kept history; moved into the database on the first [load].
  final SharedPreferencesAsync? _legacy;
  var _legacyChecked = false;

  /// Longer than the server keeps undelivered messages, so a dismissal outlives the message it covers.
  static const dismissalRetention = Duration(days: 45);

  /// Reads the newest of the history, after dropping dismissals and publish marks too old to matter.
  Future<HistoryRecords> load() async {
    await _importLegacy();
    final expired = DateTime.now().subtract(dismissalRetention).millisecondsSinceEpoch;
    await (_db.delete(
      _db.historyDismissals,
    )..where((d) => d.pairId.equals(pairId) & d.at.isSmallerThanValue(expired))).go();
    await (_db.delete(
      _db.historyPublished,
    )..where((p) => p.pairId.equals(pairId) & p.at.isSmallerThanValue(expired))).go();

    final notifications =
        await (_db.select(_db.historyNotifications)
              ..where((n) => n.pairId.equals(pairId))
              ..orderBy([(n) => OrderingTerm.desc(n.postedAt)])
              ..limit(maxNotifications))
            .get();
    final replies =
        await (_db.select(_db.historyReplies)
              ..where((r) => r.pairId.equals(pairId))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
              ..limit(maxReplies))
            .get();
    final dismissals = await (_db.select(_db.historyDismissals)..where((d) => d.pairId.equals(pairId))).get();
    return HistoryRecords(
      notifications: {for (final row in notifications) row.id: StoredNotification._fromRow(row)},
      replies: {for (final row in replies) row.id: StoredReply._fromRow(row)},
      dismissals: {for (final row in dismissals) row.keyHash: DateTime.fromMillisecondsSinceEpoch(row.at)},
    );
  }

  /// One notification, without loading the history (for a push handled in the background).
  Future<StoredNotification?> notification(String id) async {
    final row = await (_db.select(
      _db.historyNotifications,
    )..where((n) => n.pairId.equals(pairId) & n.id.equals(id))).getSingleOrNull();
    return row == null ? null : StoredNotification._fromRow(row);
  }

  /// Saves [notifications] (replacing any with the same id); returns the [revision] after it.
  Future<String> putNotifications(Iterable<StoredNotification> notifications) async {
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.historyNotifications, [for (final n in notifications) n._row(pairId)]),
    );
    return revision();
  }

  /// Makes notifications findable: their search text and app, by id (see `history_fts`). An empty package name marks
  /// one whose payload could not be opened, so it is not tried again.
  Future<void> index(Map<String, ({String content, String packageName})> byId) => _db.transaction(() async {
    const row = '(SELECT rowid FROM history_notifications WHERE pair_id = ? AND id = ?)';
    for (final MapEntry(key: id, value: (:content, :packageName)) in byId.entries) {
      final key = [Variable.withString(pairId), Variable.withString(id)];
      await _db.customUpdate('DELETE FROM history_fts WHERE rowid = $row', variables: key);
      if (content.isNotEmpty) {
        await _db.customInsert(
          'INSERT INTO history_fts (rowid, content) VALUES ($row, ?)',
          variables: [...key, Variable.withString(content)],
        );
      }
      await (_db.update(_db.historyNotifications)..where((n) => n.pairId.equals(pairId) & n.id.equals(id))).write(
        HistoryNotificationsCompanion(packageName: Value(packageName)),
      );
    }
  });

  /// Notifications not indexed for search yet (kept before search existed), newest first, up to [limit].
  Future<List<StoredNotification>> unindexed({int limit = 300}) async {
    final rows =
        await (_db.select(_db.historyNotifications)
              ..where((n) => n.pairId.equals(pairId) & n.packageName.isNull())
              ..orderBy([(n) => OrderingTerm.desc(n.postedAt)])
              ..limit(limit))
            .get();
    return [for (final row in rows) StoredNotification._fromRow(row)];
  }

  /// A page of notifications, newest first: those whose search text contains [text] (lower-cased; empty for all), of
  /// [packageName], posted after [after], saved up to [savedUpTo] or after [savedAfter] (see [saved]), and after the
  /// [cursor] of the previous page.
  Future<List<StoredNotification>> page({
    String text = '',
    String? packageName,
    DateTime? after,
    int? savedUpTo,
    int? savedAfter,
    ({DateTime postedAt, String id})? cursor,
    int limit = 50,
  }) async {
    final (from, where, variables) = _filter(
      text: text,
      packageName: packageName,
      after: after,
      savedUpTo: savedUpTo,
      savedAfter: savedAfter,
    );
    if (cursor != null) {
      final at = cursor.postedAt.millisecondsSinceEpoch;
      where.add('(n.posted_at < ? OR (n.posted_at = ? AND n.id < ?))');
      variables.addAll([Variable.withInt(at), Variable.withInt(at), Variable.withString(cursor.id)]);
    }
    final rows = await _db
        .customSelect(
          'SELECT n.* FROM $from WHERE ${where.join(' AND ')} ORDER BY n.posted_at DESC, n.id DESC LIMIT ?',
          variables: [...variables, Variable.withInt(limit)],
          readsFrom: {_db.historyNotifications},
        )
        .get();
    return [for (final row in rows) StoredNotification._fromRow(_db.historyNotifications.map(row.data))];
  }

  /// How many notifications [page] would go through, over all its pages.
  Future<int> count({String text = '', String? packageName, DateTime? after, int? savedUpTo, int? savedAfter}) async {
    final (from, where, variables) = _filter(
      text: text,
      packageName: packageName,
      after: after,
      savedUpTo: savedUpTo,
      savedAfter: savedAfter,
    );
    final row = await _db
        .customSelect('SELECT count(*) AS c FROM $from WHERE ${where.join(' AND ')}', variables: variables)
        .getSingle();
    return row.read<int>('c');
  }

  /// How far the history goes: notifications saved from now on come after this (SQLite's rowid, which grows with each
  /// insert and which an update keeps).
  Future<int> saved() async =>
      (await _db.customSelect('SELECT coalesce(max(rowid), 0) AS r FROM history_notifications').getSingle()).read<int>(
        'r',
      );

  (String, List<String>, List<Variable<Object>>) _filter({
    required String text,
    String? packageName,
    DateTime? after,
    int? savedUpTo,
    int? savedAfter,
  }) {
    var from = 'history_notifications n';
    final where = ['n.pair_id = ?'];
    final variables = <Variable<Object>>[Variable.withString(pairId)];
    if (text.isNotEmpty) {
      from = 'history_fts JOIN history_notifications n ON n.rowid = history_fts.rowid';
      if (text.length >= 3) {
        // one phrase: the query's trigrams in a row, so it matches as a substring
        where.add('history_fts MATCH ?');
        variables.add(Variable.withString('"${text.replaceAll('"', '""')}"'));
      } else {
        where.add('instr(history_fts.content, ?) > 0');
        variables.add(Variable.withString(text));
      }
    }
    if (packageName != null) {
      where.add('n.package_name = ?');
      variables.add(Variable.withString(packageName));
    }
    if (after != null) {
      where.add('n.posted_at > ?');
      variables.add(Variable.withInt(after.millisecondsSinceEpoch));
    }
    if (savedUpTo != null) {
      where.add('n.rowid <= ?');
      variables.add(Variable.withInt(savedUpTo));
    }
    if (savedAfter != null) {
      where.add('n.rowid > ?');
      variables.add(Variable.withInt(savedAfter));
    }
    return (from, where, variables);
  }

  /// When the sender's notifications were dismissed, by key hash.
  Future<Map<String, DateTime>> dismissals() async => {
    for (final row in await (_db.select(_db.historyDismissals)..where((d) => d.pairId.equals(pairId))).get())
      row.keyHash: DateTime.fromMillisecondsSinceEpoch(row.at),
  };

  /// The replies to [notificationIds].
  Future<List<StoredReply>> repliesTo(Iterable<String> notificationIds) async {
    final ids = notificationIds.toList();
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.historyReplies,
    )..where((r) => r.pairId.equals(pairId) & r.notificationId.isIn(ids))).get();
    return [for (final row in rows) StoredReply._fromRow(row)];
  }

  /// Saves [replies] (replacing any with the same id); returns the [revision] after it.
  Future<String> putReplies(Iterable<StoredReply> replies) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.historyReplies, [for (final r in replies) r._row(pairId)]));
    return revision();
  }

  /// Saves when the sender's notifications (by key hash) were dismissed; returns the [revision] after it.
  Future<String> putDismissals(Map<String, DateTime> dismissals) async {
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.historyDismissals, [
        for (final MapEntry(:key, value: at) in dismissals.entries)
          HistoryDismissalsCompanion.insert(pairId: pairId, keyHash: key, at: at.millisecondsSinceEpoch),
      ]),
    );
    return revision();
  }

  /// The sender mirrored a notification of the source notification [keyHash] (see [takePublished]).
  Future<void> notePublished(String keyHash) => _db
      .into(_db.historyPublished)
      .insertOnConflictUpdate(
        HistoryPublishedCompanion.insert(pairId: pairId, keyHash: keyHash, at: DateTime.now().millisecondsSinceEpoch),
      );

  /// Whether a notification of [keyHash] was mirrored since it was last dismissed; forgets it, so the next dismissal
  /// of the same notification is not sent again.
  Future<bool> takePublished(String keyHash) async =>
      await (_db.delete(_db.historyPublished)..where((p) => p.pairId.equals(pairId) & p.keyHash.equals(keyHash))).go() >
      0;

  /// Changes when another isolate or engine writes to the database; this one's own writes leave it as it is.
  Future<String> revision() async => '${await _db.dataVersion()}';

  /// How much of this pair's history is kept: notifications and replies.
  Future<({int notifications, int replies})> size() async {
    final row = await _db
        .customSelect(
          'SELECT (SELECT count(*) FROM history_notifications WHERE pair_id = ?1) AS n, '
          '(SELECT count(*) FROM history_replies WHERE pair_id = ?1) AS r',
          variables: [Variable.withString(pairId)],
        )
        .getSingle();
    return (notifications: row.read<int>('n'), replies: row.read<int>('r'));
  }

  /// Moves this pair's history into the pair [target]: the same device, paired again. Each payload is opened with this
  /// pair's key and sealed with the new one by [reseal] (null for one that cannot be opened, which is dropped). Rows
  /// keep their rowid, so the search index still finds them. A batch at a time, so an interrupted move continues on the
  /// next try. Returns the ids of the notifications moved.
  Future<List<String>> moveTo(
    String target, {
    required Future<String?> Function(String payload, {required bool reply}) reseal,
    int batch = 200,
  }) async {
    final moved = <String>[];
    while (true) {
      final rows =
          await (_db.select(_db.historyNotifications)
                ..where((n) => n.pairId.equals(pairId))
                ..limit(batch))
              .get();
      if (rows.isEmpty) break;
      final sealed = [for (final r in rows) (r.id, await reseal(r.payload, reply: false))];
      await _db.transaction(() async {
        for (final (id, payload) in sealed) {
          final row = _db.update(_db.historyNotifications)..where((n) => n.pairId.equals(pairId) & n.id.equals(id));
          if (payload == null) {
            await _db.customUpdate(
              'DELETE FROM history_fts WHERE rowid = (SELECT rowid FROM history_notifications WHERE pair_id = ? AND id = ?)',
              variables: [Variable.withString(pairId), Variable.withString(id)],
            );
            await (_db.delete(_db.historyNotifications)..where((n) => n.pairId.equals(pairId) & n.id.equals(id))).go();
          } else {
            await row.write(HistoryNotificationsCompanion(pairId: Value(target), payload: Value(payload)));
            moved.add(id);
          }
        }
      });
    }
    while (true) {
      final rows =
          await (_db.select(_db.historyReplies)
                ..where((r) => r.pairId.equals(pairId))
                ..limit(batch))
              .get();
      if (rows.isEmpty) break;
      final sealed = [for (final r in rows) (r.id, await reseal(r.payload, reply: true))];
      await _db.transaction(() async {
        for (final (id, payload) in sealed) {
          final where = _db.historyReplies.pairId.equals(pairId) & _db.historyReplies.id.equals(id);
          if (payload == null) {
            await (_db.delete(_db.historyReplies)..where((_) => where)).go();
          } else {
            await (_db.update(
              _db.historyReplies,
            )..where((_) => where)).write(HistoryRepliesCompanion(pairId: Value(target), payload: Value(payload)));
          }
        }
      });
    }
    // dismissals still match the moved notifications (both keep the old pair's key hashes); publish marks do not matter
    await _db.customUpdate(
      'UPDATE OR REPLACE history_dismissals SET pair_id = ? WHERE pair_id = ?',
      variables: [Variable.withString(target), Variable.withString(pairId)],
      updates: {_db.historyDismissals},
    );
    await (_db.delete(_db.historyPublished)..where((p) => p.pairId.equals(pairId))).go();
    return moved;
  }

  /// Deletes these notifications for good: their rows, their search entries and the replies sent to them.
  Future<String> deleteNotifications(Iterable<String> ids) async {
    final all = ids.toSet().toList();
    // in batches, under SQLite's limit on bound variables
    for (var start = 0; start < all.length; start += 500) {
      final batch = all.sublist(start, min(start + 500, all.length));
      final marks = List.filled(batch.length, '?').join(',');
      final variables = [Variable.withString(pairId), for (final id in batch) Variable.withString(id)];
      await _db.transaction(() async {
        await _db.customUpdate(
          'DELETE FROM history_fts WHERE rowid IN '
          '(SELECT rowid FROM history_notifications WHERE pair_id = ? AND id IN ($marks))',
          variables: variables,
        );
        await (_db.delete(_db.historyNotifications)..where((n) => n.pairId.equals(pairId) & n.id.isIn(batch))).go();
        await (_db.delete(
          _db.historyReplies,
        )..where((r) => r.pairId.equals(pairId) & r.notificationId.isIn(batch))).go();
      });
    }
    return revision();
  }

  /// Deletes every notification of this pair, with their search entries and replies ("Clear all"). Dismissals and
  /// publish marks stay: they say what the phone did, not what is kept here.
  Future<String> deleteAllNotifications() async {
    await _db.transaction(() async {
      await _db.customUpdate(
        'DELETE FROM history_fts WHERE rowid IN (SELECT rowid FROM history_notifications WHERE pair_id = ?)',
        variables: [Variable.withString(pairId)],
      );
      await (_db.delete(_db.historyNotifications)..where((n) => n.pairId.equals(pairId))).go();
      await (_db.delete(_db.historyReplies)..where((r) => r.pairId.equals(pairId))).go();
    });
    return revision();
  }

  /// Deletes this pair's history.
  Future<void> erase() => _db.transaction(() async {
    await _db.customUpdate(
      'DELETE FROM history_fts WHERE rowid IN (SELECT rowid FROM history_notifications WHERE pair_id = ?)',
      variables: [Variable.withString(pairId)],
    );
    await (_db.delete(_db.historyNotifications)..where((n) => n.pairId.equals(pairId))).go();
    await (_db.delete(_db.historyReplies)..where((r) => r.pairId.equals(pairId))).go();
    await (_db.delete(_db.historyDismissals)..where((d) => d.pairId.equals(pairId))).go();
    await (_db.delete(_db.historyPublished)..where((p) => p.pairId.equals(pairId))).go();
  });

  /// Moves what the first version kept in SharedPreferences (one key per document) into the database, once.
  Future<void> _importLegacy() async {
    final prefs = _legacy;
    if (prefs == null || _legacyChecked) return;
    _legacyChecked = true;
    final prefix = 'air_reply.history.v1.$pairId.';
    final keys = (await prefs.getKeys()).where((k) => k.startsWith(prefix)).toSet();
    if (keys.isEmpty) return;

    final notifications = <StoredNotification>[];
    final replies = <StoredReply>[];
    final dismissals = <String, DateTime>{};
    for (final MapEntry(:key, :value) in (await prefs.getAll(allowList: keys)).entries) {
      if (value is! String) continue;
      final name = key.substring(prefix.length);
      try {
        switch (name.length > 2 ? name.substring(0, 2) : name) {
          case 'n.':
            notifications.add(StoredNotification._fromLegacy(name.substring(2), _decode(value)));
          case 'r.':
            replies.add(StoredReply._fromLegacy(name.substring(2), _decode(value)));
          case 'x.':
            dismissals[name.substring(2)] = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
          case 'k.':
            await notePublished(name.substring(2));
        }
      } on Object catch (e) {
        appLog('Skipping unreadable history entry $key: $e', name: 'air_reply.history');
      }
    }
    if (notifications.isNotEmpty) await putNotifications(notifications);
    if (replies.isNotEmpty) await putReplies(replies);
    if (dismissals.isNotEmpty) await putDismissals(dismissals);
    await prefs.clear(allowList: keys);
    appLog(
      'Moved ${notifications.length} notifications and ${replies.length} replies into the database',
      name: 'air_reply.history',
    );
  }

  static Map<String, Object?> _decode(String raw) => (jsonDecode(raw) as Map).cast<String, Object?>();
}
