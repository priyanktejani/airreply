import 'dart:async';

import 'package:air_reply/core/haptics/haptics.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Swipe right to mark read or unread, left to delete; the same two actions for screen readers. Used by every
/// notification card, so a swipe looks and behaves the same on every screen.
///
/// The action's colour is drawn here rather than by the Dismissible, which clips it to a straight line at the card's
/// edge and leaves the page showing beside the card's rounded corners. Here it reaches [radius] further, under the
/// card, so the colour fills in behind the corners as the card slides.
class SwipeActions extends StatefulWidget {
  const SwipeActions({
    required this.id,
    required this.isRead,
    required this.onToggleRead,
    required this.onDelete,
    required this.child,
    this.radius = cardRadius,
    super.key,
  });

  /// A card's corner radius: what the swipe colour rounds to on the outside.
  static const double cardRadius = AppRadius.lg;

  /// Unique among the rows of the list.
  final String id;
  final bool isRead;
  final Future<void> Function() onToggleRead;
  final Future<void> Function() onDelete;
  final Widget child;

  /// The corner radius of what is swiped: the card's by default, 0 for a row inside a card.
  final double radius;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions> {
  DismissDirection? _direction;
  double _progress = 0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final read = _direction == DismissDirection.startToEnd;
      // the part uncovered by the sliding card, and the card's corner beside it
      final width = (_progress * box.maxWidth + widget.radius).clamp(0.0, box.maxWidth);
      return Stack(
        children: [
          if (_direction != null && _progress > 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: read ? 0 : null,
              right: read ? null : 0,
              width: width,
              child: read
                  ? _SwipeBackground(
                      icon: widget.isRead ? AppIcons.markEmailUnread : AppIcons.markEmailRead,
                      label: widget.isRead ? context.l10n.swipeUnread : context.l10n.swipeRead,
                      alignment: Alignment.centerLeft,
                      radius: widget.radius,
                    )
                  : _SwipeBackground(
                      icon: AppIcons.delete,
                      label: context.l10n.actionDelete,
                      alignment: Alignment.centerRight,
                      radius: widget.radius,
                      danger: true,
                    ),
            ),
          Dismissible(
            key: ValueKey('swipe/${widget.id}'),
            onUpdate: (details) {
              // one tick as the swipe reaches the point where it acts (and again if it comes back past it)
              if (details.reached != details.previousReached) context.hapticThreshold();
              setState(() {
                _direction = details.direction;
                _progress = details.progress;
              });
            },
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await widget.onToggleRead();
                return false; // the row stays, only its read state changes
              }
              return true;
            },
            onDismissed: (_) => unawaited(widget.onDelete()),
            child: Semantics(
              customSemanticsActions: {
                CustomSemanticsAction(label: widget.isRead ? context.l10n.markAsUnread : context.l10n.markAsRead): () =>
                    unawaited(widget.onToggleRead()),
                CustomSemanticsAction(label: context.l10n.actionDelete): () => unawaited(widget.onDelete()),
              },
              child: widget.child,
            ),
          ),
        ],
      );
    },
  );
}

/// What a swipe does, under the card: soft accent for read, soft red for delete.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.alignment,
    required this.radius,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;
  final double radius;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final ink = danger ? c.danger : c.accent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? c.dangerSoft : c.accentSoft,
        // rounded on the outside like the card; square on the inside, under the card's rounded corners
        borderRadius: alignment == Alignment.centerLeft
            ? BorderRadius.horizontal(left: Radius.circular(radius))
            : BorderRadius.horizontal(right: Radius.circular(radius)),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          // the label stays put as the colour widens, and is cut off rather than squeezed while it is narrow
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppDimensions.iconMd, color: ink),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: AppType.button.copyWith(color: ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
