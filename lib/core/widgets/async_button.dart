import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:flutter/material.dart';

enum AsyncButtonStyle { filled, outlined, text }

/// A button that runs an async action: it shows a spinner while running, ignores taps meanwhile, and reports
/// failures in a snackbar.
class AsyncButton extends StatefulWidget {
  const AsyncButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = AsyncButtonStyle.filled,
    this.expand = false,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Future<void> Function()? onPressed;
  final AsyncButtonStyle style;
  final bool expand;
  final bool destructive;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  var _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final filled = widget.style == AsyncButtonStyle.filled;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: _busy
              ? SizedBox.square(
                  key: const ValueKey('busy'),
                  dimension: AppDimensions.iconSm,
                  child: CircularProgressIndicator(strokeWidth: 2, color: filled ? c.accentInk : c.accent),
                )
              : widget.icon != null
              ? Icon(widget.icon, key: const ValueKey('icon'), size: AppDimensions.iconSm + 2)
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
        if (_busy || widget.icon != null) const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final button = switch (widget.style) {
      AsyncButtonStyle.filled => FilledButton(
        onPressed: onPressed,
        style: widget.destructive
            ? FilledButton.styleFrom(backgroundColor: c.danger, foregroundColor: c.surface)
            : null,
        child: child,
      ),
      AsyncButtonStyle.outlined => OutlinedButton(
        onPressed: onPressed,
        style: widget.destructive
            ? OutlinedButton.styleFrom(
                foregroundColor: c.danger,
                side: BorderSide(color: c.danger.withValues(alpha: .4), width: 1.5),
              )
            : null,
        child: child,
      ),
      AsyncButtonStyle.text => TextButton(
        onPressed: onPressed,
        style: widget.destructive ? TextButton.styleFrom(foregroundColor: c.danger) : null,
        child: child,
      ),
    };
    return widget.expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
