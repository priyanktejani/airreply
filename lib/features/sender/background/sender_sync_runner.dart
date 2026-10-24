import 'dart:async';
import 'package:air_reply/core/logging/app_log.dart';

import 'package:air_reply/core/platform/background_sync_channel.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/sync_wake_port.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';

/// One paired receiver as the sender loop sees it: where its replies arrive, and how to execute them.
final class SenderPairLink {
  const SenderPairLink({required this.pairId, required this.inbox, required this.executeReply});

  final String pairId;
  final ReplyInbox inbox;
  final ExecutePendingReply executeReply;
}

/// The sender's 24/7 loop, running in the headless engine owned by the Android foreground service:
///
/// * listener captured a notification  -> encrypt + publish to every paired device
/// * listener saw it removed           -> flag it dismissed on every paired device
/// * any receiver queued a reply       -> fire the cached RemoteInput action, report SENT / FAILED_EXPIRED
final class SenderSyncRunner implements BackgroundSyncHandler {
  SenderSyncRunner({
    required this._channel,
    required this._pairs,
    required this._publish,
    required this._markDismissed,
  });

  static const _rememberedReplies = 500;

  final BackgroundSyncChannel _channel;
  final List<SenderPairLink> _pairs;
  final PublishCapturedNotification _publish;
  final MarkNotificationDismissed _markDismissed;

  // Replies already taken: a resolved reply can still show up in one more snapshot before the server confirms.
  final _taken = <String>{};
  final _subscriptions = <StreamSubscription<Object?>>[];

  Future<void> start() async {
    _channel.attach(this);
    for (final pair in _pairs) {
      _subscriptions.add(pair.inbox.watchPending().listen((replies) => _executeAll(pair, replies), onError: _log));
    }
    _subscriptions.add(SyncWakePort.register(() => unawaited(onWake())));
    await _channel.signalReady();
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Future<void> onNotificationPosted(CapturedNotification notification) async {
    try {
      final mirrored = await _publish(notification);
      if (mirrored) {
        appLog('Mirrored ${notification.packageName} to ${_pairs.length} device(s)', name: 'air_reply.sync');
      }
    } on Object catch (e) {
      _log(e);
    }
  }

  @override
  Future<void> onNotificationRemoved(String key) async {
    try {
      await _markDismissed(key);
    } on Object catch (e) {
      _log(e);
    }
  }

  @override
  Future<void> onWake() async {
    for (final pair in _pairs) {
      try {
        await _executeAll(pair, await pair.inbox.fetchPending());
      } on Object catch (e) {
        _log(e);
      }
    }
  }

  Future<void> _executeAll(SenderPairLink pair, List<PendingReply> replies) async {
    for (final reply in replies) {
      if (!_take('${pair.pairId}/${reply.id}')) continue;
      try {
        final status = await pair.executeReply(reply);
        appLog('Reply ${reply.id}: ${status.wire}', name: 'air_reply.sync');
      } on Object catch (e) {
        _log(e);
      }
    }
  }

  bool _take(String id) {
    if (!_taken.add(id)) return false;
    if (_taken.length > _rememberedReplies) _taken.remove(_taken.first);
    return true;
  }

  static void _log(Object error, [StackTrace? stackTrace]) =>
      appLog('Sync error', error: error, stackTrace: stackTrace, name: 'air_reply.sync');
}
