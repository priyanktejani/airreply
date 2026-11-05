import 'dart:convert';
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

  /// The largest notification, as clear JSON, that still fits firestore.rules' 16 KB once sealed (12-byte nonce,
  /// 16-byte tag) and base64-encoded (4/3 of it), with room to spare.
  static const maxPayloadBytes = 11500;

  /// [content] made to fit [maxPayloadBytes]: text in Hindi, Chinese or emoji takes three or four bytes a character,
  /// so a long one with an icon could pass the character limit yet be refused by the server, and never arrive. The
  /// icon goes first (it is sent again with a later notification); then the text, and at worst the title, are
  /// shortened by bytes, at a character boundary, with an ellipsis.
  static NotificationContent fit(NotificationContent content) {
    int size(NotificationContent c) => utf8.encode(jsonEncode(c.toJson())).length;
    var c = content;
    if (size(c) <= maxPayloadBytes) return c;
    if (c.iconPng != null) {
      c = c.withIcon(null);
      if (size(c) <= maxPayloadBytes) return c;
    }
    String shorten(String s, int over) {
      // room for the ellipsis (3 bytes) and JSON escapes the cut might not save
      final keep = utf8.encode(s).length - over - 16;
      if (keep <= 0) return '';
      final out = StringBuffer();
      var bytes = 0;
      for (final rune in s.runes) {
        final ch = String.fromCharCode(rune);
        bytes += utf8.encode(ch).length;
        if (bytes > keep) break;
        out.write(ch);
      }
      return '$out…';
    }

    c = c.withWords(text: shorten(c.text, size(c) - maxPayloadBytes));
    if (size(c) > maxPayloadBytes) c = c.withWords(title: shorten(c.title, size(c) - maxPayloadBytes));
    return c;
  }

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
      sender: captured.sender,
      conversationId: switch (captured.conversationId) {
        final id? => opaqueId('${captured.packageName}|$id'),
        null => null,
      },
      isMessage: captured.isMessage,
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
      copy = fit(copy);
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
    throw SyncException(AppError.devicesUnreachable, count: failed, total: targets.length, cause: firstError);
  }
}

/// A short, stable stand-in for an app's conversation id: two 32-bit FNV-1a hashes with different seeds, as 16 hex
/// digits. Receivers only compare it, so the raw id (often a phone number) never leaves the phone, not even inside
/// the encrypted payload. 32-bit arithmetic keeps it exact on every platform, the web included.
String opaqueId(String raw) =>
    [_fnv1a32(raw, 0x811c9dc5), _fnv1a32(raw, 0x9747b28c)].map((h) => h.toRadixString(16).padLeft(8, '0')).join();

int _fnv1a32(String input, int seed) {
  var hash = seed;
  for (final unit in input.codeUnits) {
    hash = (hash ^ unit) & 0xFFFFFFFF;
    // hash * 16777619 (the FNV prime, 2^24 + 403), modulo 2^32.
    hash = (((hash << 24) & 0xFFFFFFFF) + hash * 403) & 0xFFFFFFFF;
  }
  return hash;
}
