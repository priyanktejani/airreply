import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'history_database.g.dart';

// Every paired device's history, on this device (see MessageHistory). Payloads stay sealed with the pair's key, so
// the database needs no encryption of its own. Times are milliseconds since the epoch.

@DataClassName('NotificationRow')
@TableIndex(name: 'notifications_by_time', columns: {#pairId, #postedAt})
class HistoryNotifications extends Table {
  TextColumn get pairId => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get postedAt => integer()();

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

/// What search looks through for each notification: its title, text and app name, lower-cased. Plain text, kept
/// beside the sealed payload so the whole history can be searched without opening every message.
@DataClassName('SearchRow')
class HistorySearch extends Table {
  TextColumn get pairId => text()();
  TextColumn get id => text()();
  TextColumn get content => text()();

  @override
  Set<Column<Object>> get primaryKey => {pairId, id};
}

@DriftDatabase(tables: [HistoryNotifications, HistoryReplies, HistoryDismissals, HistoryPublished, HistorySearch])
final class HistoryDatabase extends _$HistoryDatabase {
  /// [executor] is an in-memory or temporary database in tests.
  HistoryDatabase(super.executor);

  /// The app's database file. The app and the sender's background engine (a separate Flutter engine) each open their
  /// own connection: write-ahead logging lets them read and write at the same time, and a busy timeout makes one wait
  /// for the other's write instead of failing.
  HistoryDatabase.open()
    : this(
        driftDatabase(
          name: 'air_reply_history',
          native: DriftNativeOptions(
            setup: (db) => db
              ..execute('PRAGMA journal_mode = WAL')
              ..execute('PRAGMA busy_timeout = 5000'),
          ),
          web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // 2: search; filled in for existing history as each pair's feed opens
      if (from < 2) await m.createTable(historySearch);
    },
  );

  /// Changes whenever another connection (another isolate or engine) commits a write; this connection's own writes
  /// leave it as it is.
  Future<int> dataVersion() async => (await customSelect('PRAGMA data_version').getSingle()).read<int>('data_version');
}
