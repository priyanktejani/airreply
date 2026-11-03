import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

/// A document in one of a pair's collections, as a transport reads it: plain Dart values, timestamps as [DateTime].
typedef MailboxDocument = ({String id, Map<String, Object?> data});

/// An equality filter on one field.
typedef MailboxFilter = ({String field, Object value});

/// What a backend does for one pair: sealed documents dropped into a collection, picked up by the other device and
/// then deleted, as a mail server holds a message only until it is delivered. Implemented over FlutterFire
/// ([FirestoreMailbox]) and over REST ([RestMailbox]); [MirrorSyncRepository] builds the app's sync on top of it.
abstract interface class PairMailbox {
  /// A new, unused document id, made on the device (no server round trip).
  String newId();

  /// Creates the document [id]; fails if it exists.
  Future<void> create(String collection, String id, Map<String, Object?> data);

  Future<void> update(String collection, String id, Map<String, Object?> data);

  Future<void> delete(String collection, Iterable<String> ids);

  /// Null when the document does not exist (any more).
  Future<MailboxDocument?> get(String collection, String id);

  /// The documents waiting in [collection] (a batch at most), each time they change. A polling transport checks
  /// collections that are not [urgent] less often.
  Stream<List<MailboxDocument>> watch(String collection, {MailboxFilter? where, bool urgent = true});

  /// One read straight from the server.
  Future<List<MailboxDocument>> fetch(String collection, {MailboxFilter? where});

  /// Whether this pair is currently reaching the server.
  Stream<SyncState> watchSyncState();
}
