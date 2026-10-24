import 'dart:typed_data';

import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/core/platform/native_notification_bridge.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';
import 'package:air_reply/features/mirror/domain/repositories/mirror_repositories.dart';
import 'package:air_reply/features/sender/domain/app_icons.dart';

/// One paired receiver, as the publisher sees it.
final class PublishTarget {
  const PublishTarget(this.pairId, this.publisher);

  final String pairId;
  final NotificationPublisher publisher;
}

/// Mirrors one captured notification to every paired device (each pair has its own key, so each gets its own copy),
/// attaching the app's icon when that device does not have it yet.
final class PublishCapturedNotification {
  const PublishCapturedNotification(this._targets, {this._icons, this._iconLog});

  /// Long texts are trimmed so every payload stays well under the 16 KB limit in firestore.rules.
  static const maxTextLength = 4000;

  /// Larger icons are skipped rather than risk the payload limit.
  static const maxIconBytes = 6000;

  final List<PublishTarget> _targets;
  final AppIconSource? _icons;
  final IconDeliveryLog? _iconLog;

  /// Returns false when there was nothing worth mirroring. Throws [SyncException] if some device could not be
  /// reached; the others still get the notification.
  Future<bool> call(CapturedNotification captured) async {
    if (captured.title.trim().isEmpty && captured.text.trim().isEmpty) return false;
    final content = NotificationContent(
      key: captured.key,
      packageName: captured.packageName,
      appName: captured.appName,
      title: captured.title,
      text: captured.text.length > maxTextLength ? '${captured.text.substring(0, maxTextLength)}…' : captured.text,
      postedAt: captured.postedAt,
      conversationTitle: captured.conversationTitle,
      isGroupConversation: captured.isGroupConversation,
    );

    Future<Uint8List?>? icon;
    Future<Uint8List?> loadIcon() => icon ??= _icons!.iconFor(captured.packageName);

    await _toAll(_targets, (target) async {
      var copy = content;
      final iconLog = _iconLog;
      if (_icons != null && iconLog != null && await iconLog.isDue(target.pairId, captured.packageName)) {
        final png = await loadIcon();
        if (png != null && png.length <= maxIconBytes) copy = content.withIcon(png);
      }
      await target.publisher.publish(copy, canReply: captured.canReply);
      if (copy.iconPng != null) await iconLog?.recordSent(target.pairId, captured.packageName);
    });
    return true;
  }
}

/// The notification left the sender's status bar: receivers keep it, but can no longer reply.
final class MarkNotificationDismissed {
  const MarkNotificationDismissed(this._publishers);

  final List<NotificationPublisher> _publishers;

  Future<void> call(String notificationKey) => _toAll(_publishers, (p) => p.markDismissed(notificationKey));
}

/// Fires the cached `RemoteInput` action for a reply written on a receiver, and reports the outcome to that pair.
final class ExecutePendingReply {
  const ExecutePendingReply(this._bridge, this._inbox);

  final NotificationBridge _bridge;
  final ReplyInbox _inbox;

  Future<ReplyStatus> call(PendingReply reply) async {
    ReplyDispatchResult result;
    try {
      result = await _bridge.sendReply(notificationKey: reply.notificationKey, text: reply.text);
    } on NativeBridgeException {
      result = ReplyDispatchResult.failed;
    }
    final status = switch (result) {
      ReplyDispatchResult.sent => ReplyStatus.sent,
      ReplyDispatchResult.expired => ReplyStatus.expired,
      ReplyDispatchResult.failed => ReplyStatus.failed,
    };
    await _inbox.resolve(reply.id, status);
    return status;
  }
}

/// Runs [action] on every target, even when some fail; one unreachable device must not block the others.
Future<void> _toAll<T>(List<T> targets, Future<void> Function(T target) action) async {
  var failed = 0;
  Object? firstError;
  await Future.wait([
    for (final target in targets)
      action(target).catchError((Object e) {
        failed++;
        firstError ??= e;
      }),
  ]);
  if (failed > 0) {
    throw SyncException('Could not reach $failed of ${targets.length} paired devices.', cause: firstError);
  }
}
