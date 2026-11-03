import 'package:air_reply/features/mirror/domain/entities/mirrored_notification.dart';
import 'package:air_reply/features/mirror/domain/entities/reply_command.dart';

/// Which notifications to read from the history on this device: all of them, or those matching a search and filters.
final class HistoryQuery {
  const HistoryQuery({this.text = '', this.packageName, this.after, this.savedUpTo, this.savedAfter});

  /// Found in the title, text or app name, ignoring case; empty for everything.
  final String text;

  /// Only this app's notifications.
  final String? packageName;

  /// Only notifications posted after this.
  final DateTime? after;

  /// Only notifications this device had saved by [HistoryPage.saved] of an earlier page: what had arrived when a
  /// search started, so its pages stay put while new notifications come in, however late they were sent.
  final int? savedUpTo;

  /// Only notifications saved after that point: what arrived since.
  final int? savedAfter;

  HistoryQuery saved({int? upTo, int? after}) =>
      HistoryQuery(text: text, packageName: packageName, after: this.after, savedUpTo: upTo, savedAfter: after);
}

/// Where a page ended: the next page starts after this notification (newest first).
typedef HistoryCursor = ({DateTime postedAt, String id});

/// One page of history, newest first, with the replies to its notifications. [next] is null on the last page; [saved]
/// is how far the history on this device went when the page was read (see [HistoryQuery.savedUpTo]).
typedef HistoryPage = ({
  List<MirroredNotification> notifications,
  List<ReplyCommand> replies,
  HistoryCursor? next,
  int saved,
});
