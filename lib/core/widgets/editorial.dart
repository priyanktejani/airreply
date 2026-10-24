import 'dart:async';
import 'dart:math' as math;

import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:flutter/material.dart';

// The shared building blocks of the editorial design: pages, headers, sections, rows, badges, notices and states.
// Screens compose these instead of styling widgets themselves.

/// A scrolling page whose content is centred and never wider than [Space.maxContentWidth], with page padding at
/// the sides. [slivers] are laid out under [header].
class EditorialPage extends StatelessWidget {
  const EditorialPage({
    required this.slivers,
    this.header,
    this.onRefresh,
    this.maxWidth = Space.maxContentWidth,
    this.controller,
    super.key,
  });

  final Widget? header;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final ScrollController? controller;

  /// Side inset that keeps [maxWidth] centred while respecting the page padding.
  static double inset(double width, BuildContext context, {double maxWidth = Space.maxContentWidth}) =>
      math.max(Space.page(context), (width - maxWidth) / 2);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = inset(constraints.maxWidth, context, maxWidth: maxWidth);
        Widget pad(Widget sliver) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: sliver,
        );
        final scroll = CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (header != null) pad(SliverToBoxAdapter(child: header)),
            for (final sliver in slivers) pad(sliver),
            SliverToBoxAdapter(child: SizedBox(height: Space.x12 + bottom)),
          ],
        );
        return SafeArea(
          bottom: false,
          child: onRefresh == null
              ? scroll
              : RefreshIndicator(onRefresh: onRefresh!, color: context.colors.ink, child: scroll),
        );
      },
    );
  }
}

/// Page title block: an optional caps eyebrow, the serif display title, an optional supporting line, and actions
/// aligned with the eyebrow.
class PageHeader extends StatelessWidget {
  const PageHeader({required this.title, this.eyebrow, this.subtitle, this.actions = const [], super.key});

  final String title;
  final String? eyebrow;
  final Widget? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: Space.x4, bottom: Space.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: eyebrow == null
                      ? const SizedBox.shrink()
                      : Text(eyebrow!.toUpperCase(), style: AppType.label.copyWith(color: c.secondary)),
                ),
                ...actions,
              ],
            ),
          ),
          Semantics(
            header: true,
            child: Text(title, style: AppType.display.copyWith(color: c.ink)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: Space.x2),
            DefaultTextStyle.merge(
              style: AppType.supporting.copyWith(color: c.secondary),
              child: subtitle!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Caps label that opens a section, with an optional trailing action or count.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {this.trailing, this.top = Space.x8, super.key});

  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: Space.x2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text.toUpperCase(), style: AppType.label.copyWith(color: c.secondary)),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Rows separated by hairlines, with a hairline above and below: the basic list of the design.
class RuledList extends StatelessWidget {
  const RuledList({required this.children, this.top = true, this.bottom = true, super.key});

  final List<Widget> children;
  final bool top;
  final bool bottom;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (top) const Divider(),
      for (final (i, child) in children.indexed) ...[if (i > 0) const Divider(), child],
      if (bottom) const Divider(),
    ],
  );
}

/// One row of a settings-like list: leading icon, title, supporting text, and a trailing control or chevron.
class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;

  /// A chevron, for rows that open another screen.
  static const chevron = Icon(Icons.chevron_right, size: 20);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = !enabled ? c.disabled : (destructive ? c.error : c.ink);
    final lead = leading ?? (icon == null ? null : Icon(icon, size: 22, color: destructive ? c.error : c.secondary));
    return InkWell(
      onTap: enabled ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x3),
          child: Row(
            children: [
              if (lead != null) ...[SizedBox(width: 24, child: Center(child: lead)), const SizedBox(width: Space.x4)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppType.subtitle.copyWith(color: ink, fontWeight: FontWeight.w400),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppType.supporting.copyWith(color: enabled ? c.secondary : c.disabled)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.x3),
                IconTheme.merge(
                  data: IconThemeData(color: c.secondary),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A switch row; the whole row toggles.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InfoRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    ),
  );
}

enum Tone { neutral, success, warning, error }

extension ToneColor on Tone {
  Color of(BuildContext context) {
    final c = context.colors;
    return switch (this) {
      Tone.neutral => c.secondary,
      Tone.success => c.success,
      Tone.warning => c.warning,
      Tone.error => c.error,
    };
  }
}

/// A state in words with an icon: never colour alone.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.icon, this.tone = Tone.neutral, this.busy = false, super.key});

  final String label;
  final IconData icon;
  final Tone tone;

  /// Shows a small spinner instead of the icon (connecting, sending).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = tone.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 14,
          child: busy ? CircularProgressIndicator(strokeWidth: 1.5, color: color) : Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: Space.x1 + 2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.supporting.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// A big serif figure over a caps label. Tappable when [onTap] is set.
class Stat extends StatelessWidget {
  const Stat({required this.value, required this.label, this.onTap, super.key});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      label: '$value $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.controlBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppType.section.copyWith(color: c.ink, fontFeatures: const [FontFeature.liningFigures()]),
              ),
              const SizedBox(height: Space.x1),
              Text(label.toUpperCase(), style: AppType.label.copyWith(color: c.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something that needs the person's attention: a rule in the tone's colour, an icon, a title, a sentence, and the
/// actions that fix it.
class Notice extends StatelessWidget {
  const Notice({
    required this.title,
    required this.message,
    this.tone = Tone.warning,
    this.icon,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String message;
  final Tone tone;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = tone.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: Radii.controlBorder,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          icon ?? (tone == Tone.error ? Icons.error_outline : Icons.warning_amber_outlined),
                          size: 20,
                          color: color,
                        ),
                        const SizedBox(width: Space.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppType.subtitle.copyWith(color: c.ink)),
                              const SizedBox(height: 2),
                              Text(message, style: AppType.supporting.copyWith(color: c.secondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: Space.x2),
                      Padding(
                        padding: const EdgeInsets.only(left: Space.x6),
                        child: Wrap(spacing: Space.x2, children: actions),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty, error and permission states: an icon, a serif title, a sentence, and what to do about it.
class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.secondaryAction,
    this.tone = Tone.neutral,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Widget? secondaryAction;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                ),
                child: Icon(icon, size: 24, color: tone == Tone.neutral ? c.secondary : tone.of(context)),
              ),
              const SizedBox(height: Space.x5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppType.section.copyWith(fontSize: 24, height: 28 / 24, color: c.ink),
              ),
              if (message != null) ...[
                const SizedBox(height: Space.x2),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppType.body.copyWith(color: c.secondary),
                ),
              ],
              if (action != null) ...[const SizedBox(height: Space.x6), action!],
              if (secondaryAction != null) ...[const SizedBox(height: Space.x2), secondaryAction!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey placeholder rows that gently pulse while content loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({this.rows = 5, super.key});

  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: c.subtle, borderRadius: BorderRadius.circular(4)),
    );
    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
        child: Column(
          children: [
            for (var i = 0; i < widget.rows; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(40, 40),
                    const SizedBox(width: Space.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(120, 10),
                          const SizedBox(height: Space.x3),
                          bar(double.infinity, 14),
                          const SizedBox(height: Space.x2),
                          bar(180, 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum AsyncButtonStyle { filled, outlined, text }

/// A button that runs an async action: it shows progress while running, ignores taps meanwhile, and reports
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
    final c = context.colors;
    final onPressed = widget.onPressed == null || _busy ? null : _run;
    final foreground = switch (widget.style) {
      AsyncButtonStyle.filled => c.paper,
      _ => widget.destructive ? c.error : c.ink,
    };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_busy)
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: widget.style == AsyncButtonStyle.filled ? c.paper : c.ink,
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 18),
        if (_busy || widget.icon != null) const SizedBox(width: Space.x2),
        Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final button = switch (widget.style) {
      AsyncButtonStyle.filled => FilledButton(
        onPressed: onPressed,
        style: widget.destructive
            ? FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: foreground)
            : null,
        child: child,
      ),
      AsyncButtonStyle.outlined => OutlinedButton(
        onPressed: onPressed,
        style: widget.destructive ? OutlinedButton.styleFrom(foregroundColor: c.error) : null,
        child: child,
      ),
      AsyncButtonStyle.text => TextButton(
        onPressed: onPressed,
        style: widget.destructive ? TextButton.styleFrom(foregroundColor: c.error) : null,
        child: child,
      ),
    };
    return widget.expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// "View all →": an inline text link with an arrow.
class ArrowLink extends StatelessWidget {
  const ArrowLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Space.x2)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: Space.x1),
        const Icon(Icons.arrow_forward, size: 16),
      ],
    ),
  );
}

/// A search box with a clear button. [value] is the current query; when it changes from outside (filters cleared
/// elsewhere), the box follows.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.onChanged,
    this.hint = 'Search',
    this.value = '',
    this.autofocus = false,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final String value;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.search,
    onChanged: _changed,
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.search, size: 20),
      isDense: true,
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _controller.clear();
                _changed('');
              },
            ),
    ),
  );
}

/// Runs [action] and shows any failure; for callbacks of plain buttons and switches.
Future<void> runGuarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on Object catch (e) {
    if (context.mounted) context.showError(e);
  }
}

/// Fires [action] without awaiting it, reporting failures (for `onPressed`).
VoidCallback guarded(BuildContext context, Future<void> Function() action) =>
    () => unawaited(runGuarded(context, action));
