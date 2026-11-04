import 'dart:async';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/firebase/firestore_schema.dart';
import 'package:air_reply/core/firebase/rest/document_polls.dart';
import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';
import 'package:air_reply/core/firebase/rest/polling.dart';
import 'package:air_reply/features/mirror/data/doorbell.dart';
import 'package:air_reply/features/mirror/data/pair_mailbox.dart';
import 'package:air_reply/features/mirror/domain/entities/sync_state.dart';

/// [PairMailbox] for one pair over the Firestore REST API (Windows, Linux). With a [Doorbell] it reads the mailbox when
/// the phone rings, and only now and then otherwise (in case a ring was lost); without one, or while its connection is
/// down, it polls every few seconds. Delivered documents are deleted, so a read of an idle mailbox finds nothing and
/// costs a single read.
final class RestMailbox implements PairMailbox {
  RestMailbox(
    this._client,
    this._pairId, {
    this.pollInterval = const Duration(seconds: 3),
    this.relaxedPollInterval = const Duration(seconds: 30),
    this.backstopInterval = const Duration(minutes: 2),
    this.relaxedBackstopInterval = const Duration(minutes: 10),
    DocumentPolls? pairPolls,
    this._doorbell,
  }) : _pairPolls = pairPolls ?? DocumentPolls(_client);

  /// Documents taken per poll; once they are delivered and deleted, the next poll brings the next ones.
  static const batchSize = 300;

  final FirestoreRestClient _client;
  final String _pairId;
  final Duration pollInterval;

  /// For collections that are not urgent: every poll is a billed read, even of an empty mailbox.
  final Duration relaxedPollInterval;

  /// While the doorbell is live: reads in case a ring was lost.
  final Duration backstopInterval;
  final Duration relaxedBackstopInterval;

  /// The pair document, polled once for this status and for whether the pair is active (see RestPairingRepository).
  final DocumentPolls _pairPolls;
  final Doorbell? _doorbell;

  String get _parent => '${FirestoreSchema.pairs}/$_pairId';

  String _doc(String collection, String id) => '$_parent/$collection/$id';

  @override
  String newId() => _client.newId();

  @override
  Future<void> create(String collection, String id, Map<String, Object?> data) =>
      _guard(() => _client.commit([RestWrite.set(_doc(collection, id), data, mustNotExist: true)]));

  @override
  Future<void> update(String collection, String id, Map<String, Object?> data) =>
      _guard(() => _client.commit([RestWrite.update(_doc(collection, id), data)]));

  @override
  Future<void> delete(String collection, Iterable<String> ids) async {
    final writes = [for (final id in ids) RestWrite.delete(_doc(collection, id))];
    for (var start = 0; start < writes.length; start += 500) {
      await _guard(() => _client.commit(writes.skip(start).take(500).toList()));
    }
  }

  @override
  Future<MailboxDocument?> get(String collection, String id) async {
    final doc = await _guard(() => _client.get(_doc(collection, id)));
    return doc == null ? null : (id: doc.id, data: doc.data);
  }

  @override
  Stream<List<MailboxDocument>> watch(String collection, {MailboxFilter? where, bool urgent = true}) {
    String? last;
    return pollingStream(
      () async {
        final docs = await _query(collection, where);
        // only when something was added, removed or changed
        final version = [for (final d in docs) '${d.id}@${d.updateTime.microsecondsSinceEpoch}'].join(',');
        if (version == last) return null;
        last = version;
        return [for (final d in docs) (id: d.id, data: d.data)];
      },
      every: urgent ? pollInterval : relaxedPollInterval,
      wake: _doorbell?.wakes,
      slower: () => (_doorbell?.live ?? false) ? (urgent ? backstopInterval : relaxedBackstopInterval) : null,
    );
  }

  @override
  Future<List<MailboxDocument>> fetch(String collection, {MailboxFilter? where}) async => [
    for (final d in await _query(collection, where)) (id: d.id, data: d.data),
  ];

  Future<List<RestDocument>> _query(String collection, MailboxFilter? where) => _guard(
    () => _client.runQuery(
      RestQuery(
        collection,
        filters: [if (where != null) RestFilter(where.field, RestOperator.equal, where.value)],
        limit: batchSize,
      ),
      parent: _parent,
    ),
  );

  /// Whether the pair document can be read: the same poll that tells whether the pair is still active.
  @override
  Stream<SyncState> watchSyncState() {
    var state = SyncState.connecting;
    return _pairPolls
        .watch(_parent)
        .map((read) => state = state.next(fromServer: read.error == null, now: DateTime.now()));
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on RestFirestoreException catch (e) {
      throw SyncException(AppError.syncFailed, detail: e.status, cause: e);
    }
  }
}
