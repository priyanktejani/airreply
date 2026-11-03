import 'dart:async';

import 'package:air_reply/core/firebase/rest/firestore_rest_client.dart';

/// One read of a polled document: the document (null when it does not exist), or why it could not be read.
typedef DocumentPoll = ({RestDocument? document, Object? error});

/// Polls of single documents over REST, each shared by everything watching that document: two screens (or a status
/// and a check) asking about the same document cost one read per interval, not one each. A new watcher gets the last
/// read at once; the poll stops when the last watcher leaves.
final class DocumentPolls {
  DocumentPolls(this._client, {this.every = const Duration(seconds: 30)});

  final FirestoreRestClient _client;
  final Duration every;
  final _polls = <String, _Poll>{};

  /// Each read of the document at [path].
  Stream<DocumentPoll> watch(String path) {
    final poll = _polls.putIfAbsent(
      path,
      () => _Poll(() => _client.get(path), every, onIdle: () => _polls.remove(path)),
    );
    late final StreamController<DocumentPoll> out;
    StreamSubscription<DocumentPoll>? reads;
    out = StreamController<DocumentPoll>(
      onListen: () {
        reads = poll.reads.listen(out.add);
        if (poll.last case final last?) out.add(last);
      },
      onCancel: () => reads?.cancel(),
    );
    return out.stream;
  }
}

final class _Poll {
  _Poll(this._read, this._every, {required this.onIdle}) {
    _reads = StreamController<DocumentPoll>.broadcast(onListen: _tick, onCancel: _stop);
  }

  final Future<RestDocument?> Function() _read;
  final Duration _every;
  final void Function() onIdle;
  late final StreamController<DocumentPoll> _reads;
  Timer? _timer;
  var _active = false;
  DocumentPoll? last;

  Stream<DocumentPoll> get reads => _reads.stream;

  Future<void> _tick() async {
    _active = true;
    DocumentPoll result;
    try {
      result = (document: await _read(), error: null);
    } on Object catch (e) {
      result = (document: null, error: e);
    }
    if (!_active) return;
    _reads.add(last = result);
    _timer = Timer(_every, _tick);
  }

  void _stop() {
    _active = false;
    _timer?.cancel();
    onIdle();
  }
}
