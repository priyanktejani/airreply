import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/features/mirror/data/pair_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

/// The mailbox of a pair that has ended: nothing arrives, and nothing can be sent. Lets a removed device's history be
/// read with the same code as an active pair's, without touching the server.
final class ClosedMailbox implements PairMailbox {
  const ClosedMailbox();

  static const _ended = NotPairedException();

  @override
  String newId() => throw _ended;

  @override
  Future<void> create(String collection, String id, Map<String, Object?> data) => Future.error(_ended);

  @override
  Future<void> update(String collection, String id, Map<String, Object?> data) => Future.error(_ended);

  @override
  Future<void> delete(String collection, Iterable<String> ids) async {}

  @override
  Future<MailboxDocument?> get(String collection, String id) async => null;

  @override
  Stream<List<MailboxDocument>> watch(String collection, {MailboxFilter? where, bool urgent = true}) =>
      Stream.value(const []);

  @override
  Future<List<MailboxDocument>> fetch(String collection, {MailboxFilter? where}) async => const [];

  @override
  Stream<SyncState> watchSyncState() => Stream.value(const SyncState(SyncHealth.offline));
}
