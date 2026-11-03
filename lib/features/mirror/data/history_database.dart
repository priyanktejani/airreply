import 'package:air_reply/features/mirror/data/history_connection.dart';
import 'package:drift/drift.dart';

part 'history_database.g.dart';

// Every paired device's history, on this device (see MessageHistory). Payloads stay sealed with the pair's key, and the
// whole file is encrypted too (the search index is plain text inside it). Times are milliseconds since the epoch.

@DataClassName('NotificationRow')
@TableIndex(name: 'notifications_by_time', columns: {#pairId, #postedAt})
@TableIndex(name: 'notifications_by_app', columns: {#pairId, #packageName, #postedAt})
class HistoryNotifications extends Table {
  TextColumn get pairId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get postedAt => integer()();

  /// The source app, for filtering by app without opening payloads. Null until the notification is indexed for
  /// search (see `history_fts`); empty when its payload could not be opened.
  TextColumn get packageName => text().nullable()();

  /// The blind index of the source notification's key: how a later dismissal finds it.
  TextColumn get keyHash => text().nullable()();
  BoolColumn get canReply => boolean().withDefault(const Constant(false))();

  /// Flagged dismissed in the document itself (senders before dismissals had their own documents).
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {pairId, id};
}

@DataClassName('ReplyRow')
@TableIndex(name: 'replies_by_time', columns: {#pairId, #createdAt})
@TableIndex(name: 'replies_by_notification', columns: {#pairId, #notificationId})
class HistoryReplies extends Table {
  TextColumn get pairId => text()();
  TextColumn get id => text()();
  TextColumn get notificationId => text()();
  TextColumn get payload => text()();

  /// `ReplyStatus.wire`.
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {pairId, id};
}

/// When the sender's notification [keyHash] left its status bar.
@DataClassName('DismissalRow')
class HistoryDismissals extends Table {
  TextColumn get pairId => text()();
  TextColumn get keyHash => text()();
  IntColumn get at => integer()();

  @override
  Set<Column<Object>> get primaryKey => {pairId, keyHash};
}

/// Sender only: notifications mirrored since they were last dismissed, so only those send a dismissal.
@DataClassName('PublishedRow')
class HistoryPublished extends Table {
  TextColumn get pairId => text()();
  TextColumn get keyHash => text()();
  IntColumn get at => integer()();

  @override
  Set<Column<Object>> get primaryKey => {pairId, keyHash};
}

/// Full-text search over every notification: `history_fts` holds its title, text and app name, lower-cased, as plain
/// text beside the sealed payload, under the notification's own rowid (upserts keep it). The trigram tokenizer finds any
/// part of a word, as typing into search expects, through the index from three characters (shorter queries scan it).
/// Created by hand: drift's tables cannot be virtual.
const _createSearch = "CREATE VIRTUAL TABLE IF NOT EXISTS history_fts USING fts5(content, tokenize = 'trigram')";

@DriftDatabase(tables: [HistoryNotifications, HistoryReplies, HistoryDismissals, HistoryPublished])
final class HistoryDatabase extends _$HistoryDatabase {
  /// [executor] is an in-memory or temporary database in tests.
  HistoryDatabase(super.executor);

  /// The app's database file, encrypted with the key [hexKey] gives where the platform has files (see
  /// `history_connection_io.dart`).
  HistoryDatabase.open(Future<String> Function() hexKey) : this(openHistory(hexKey));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(_createSearch);
    },
    onUpgrade: (m, from, to) async {
      // 2 searched a plain table; 3 indexes the text and the app. Existing history is indexed again, a batch at a time,
      // as each pair's feed opens (rows without a package name are not indexed yet).
      if (from == 2) await customStatement('DROP TABLE IF EXISTS history_search');
      if (from < 3) {
        await m.addColumn(historyNotifications, historyNotifications.packageName);
        await m.create(notificationsByApp);
        await customStatement(_createSearch);
      }
      // 4: a page of history finds its replies by notification
      if (from < 4) await m.create(repliesByNotification);
    },
  );

  /// Changes whenever another connection (another isolate or engine) commits a write; this connection's own writes
  /// leave it as it is.
  Future<int> dataVersion() async => (await customSelect('PRAGMA data_version').getSingle()).read<int>('data_version');
}
