import 'package:air_reply/core/animations/pressable_scale.dart';
import 'package:air_reply/core/animations/smooth_size.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:air_reply/features/notifications/presentation/widgets/swipe_actions.dart';
import 'package:air_reply/features/notifications/presentation/widgets/unread_count.dart';
import 'package:flutter/material.dart';

/// What a swipe does to a card: right marks read or unread, left hides. See [SwipeActions].
class CardSwipe {
  const CardSwipe({required this.id, required this.isRead, required this.onToggleRead, required this.onHide});

  /// Unique among the cards of the list.
  final String id;
  final bool isRead;
  final Future<void> Function() onToggleRead;
  final Future<void> Function() onHide;
}

/// The one way a notification, an app's notifications or a conversation is shown, on every screen: an icon or avatar,
/// a muted line saying where it is from with the time and unread count, a title, the text, then status badges and a
/// green summary. The whole card is one tap target that presses in, and swipes the same way everywhere, the action's
/// colour filling in beneath it as it slides.
///
/// [expansion] opens rows inside the card (an app's conversations); while it is open only the top of the card is the
/// tap target and the card no longer presses in, so its rows take their own taps. [NotificationCard.row] is the same
/// layout as a row inside such a card: no surface of its own, and a square swipe.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.leading,
    required this.source,
    required this.time,
    required this.title,
    required this.text,
    this.unread = 0,
    this.badges = const [],
    this.summary,
    this.action,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.swipe,
    this.expansion,
    this.semanticLabel,
    this.compact = false,
    super.key,
  }) : _row = false;

  /// The card's layout as a row inside another card.
  const NotificationCard.row({
    required this.leading,
    required this.source,
    required this.time,
    required this.title,
    required this.text,
    this.unread = 0,
    this.badges = const [],
    this.summary,
    this.onTap,
    this.onLongPress,
    this.swipe,
    this.semanticLabel,
    super.key,
  }) : action = null,
       trailing = null,
       expansion = null,
       compact = true,
       _row = true;

  /// The app icon or avatar, built at the card's icon size.
  final Widget Function(double size) leading;

  /// Where it is from: the app (and phone), or the kind of conversation.
  final String source;
  final DateTime time;
  final String title;
  final String text;
  final int unread;

  /// Reply and phone states under the text.
  final List<Widget> badges;

  /// A green line at the bottom: how many notifications or messages.
  final String? summary;

  /// A small button at the end of the summary line.
  final Widget? action;

  /// Beside the content, at the top right (a menu on wide screens).
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Null for a card that does not swipe.
  final CardSwipe? swipe;

  /// Rows shown inside the card, under a hairline; null while closed.
  final Widget? expansion;
  final String? semanticLabel;

  /// Smaller icon and title and one line of text, where many cards share a screen with other content.
  final bool compact;
  final bool _row;

  @override
  Widget build(BuildContext context) {
    final open = expansion != null;
    final body = Padding(
      padding: _row
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.card, vertical: AppSpacing.md)
          : EdgeInsets.fromLTRB(
              AppSpacing.card,
              compact ? AppSpacing.md : AppSpacing.card,
              action == null ? AppSpacing.card : AppSpacing.md,
              // while closed the tap target runs to the card's bottom edge; open, to the hairline above its rows
              open ? AppSpacing.sm : (compact ? AppSpacing.md : AppSpacing.card),
            ),
      child: _Content(card: this),
    );
    final target = InkWell(onTap: onTap, onLongPress: onLongPress, child: body);

    Widget result = _row
        ? target
        : AppCard(
            padding: EdgeInsets.zero,
            child: SmoothSize(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  target,
                  if (open) ...[const Divider(height: 1), expansion!, const SizedBox(height: AppSpacing.sm)],
                ],
              ),
            ),
          );
    if (!_row && !open && (onTap != null || onLongPress != null)) result = PressableScale(child: result);
    if (semanticLabel != null) result = Semantics(label: semanticLabel, child: result);
    final s = swipe;
    if (s == null) return result;
    return SwipeActions(
      // a row's swipe is square: the card around it rounds the corners
      radius: _row ? 0 : SwipeActions.cardRadius,
      id: s.id,
      isRead: s.isRead,
      onToggleRead: s.onToggleRead,
      onHide: s.onHide,
      child: result,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.card});

  final NotificationCard card;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final unread = card.unread > 0;
    final summary = card.summary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card.leading(card.compact ? AppDimensions.iconTileSm : AppDimensions.iconTile),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.supporting.copyWith(color: c.muted),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(formatRelativeTime(card.time), style: AppType.supporting.copyWith(color: c.muted)),
                  const SizedBox(width: AppSpacing.sm),
                  UnreadCount(card.unread),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (card.title.isNotEmpty)
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (card.compact ? AppType.subtitle : AppType.title).copyWith(
                    color: c.ink,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              if (card.text.isNotEmpty)
                Text(
                  card.text,
                  maxLines: card.compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(color: unread ? c.ink : c.muted),
                ),
              if (card.badges.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(spacing: AppSpacing.base, runSpacing: AppSpacing.xs, children: card.badges),
                ),
              if (summary != null || card.action != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(summary ?? '', maxLines: 2, style: AppType.link.copyWith(color: c.accent)),
                      ),
                      ?card.action,
                    ],
                  ),
                ),
            ],
          ),
        ),
        ?card.trailing,
      ],
    );
  }
}
