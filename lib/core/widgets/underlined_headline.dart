import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// The big headline of Home and Welcome: [first] on one line, then [second] in the accent colour with a drawn underline, left
/// aligned. Each line rises into place, then the underline draws itself.
///
/// With [playOnce], that happens once while the app runs: Home's headline animates as the app opens, and is simply
/// there whenever it is built again (scrolled back into view, a tab switch, the window resized or turned).
class UnderlinedHeadline extends StatefulWidget {
  const UnderlinedHeadline({required this.first, required this.second, this.playOnce, super.key});

  final String first;
  final String second;

  /// Names this headline: once it has played, it shows in place until the app starts again.
  final String? playOnce;

  /// The headlines that have played since the app started.
  static final _played = <String>{};

  @visibleForTesting
  static void resetPlayed() => _played.clear();

  @override
  State<UnderlinedHeadline> createState() => _UnderlinedHeadlineState();
}

class _UnderlinedHeadlineState extends State<UnderlinedHeadline> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final once = widget.playOnce;
    if (MediaQuery.of(context).disableAnimations || (once != null && UnderlinedHeadline._played.contains(once))) {
      _a.value = 1;
    } else if (_a.value == 0 && !_a.isAnimating) {
      if (once != null) UnderlinedHeadline._played.add(once);
      _a.forward();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  // the part of the animation from [from], lasting 40% (400 ms)
  double _step(double from) => Curves.easeOutCubic.transform(((_a.value - from) / .4).clamp(0, 1));

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final style = AppType.hero;
    Widget rise(String text, double from, {Color? color}) => AnimatedBuilder(
      animation: _a,
      builder: (_, child) {
        final v = _step(from);
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, 60 * (1 - v)),
            child: Opacity(opacity: v, child: child),
          ),
        );
      },
      // each line always stays one line: it shrinks a little on a narrow phone rather than wrapping
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text, maxLines: 1, style: style.copyWith(color: color ?? c.ink)),
      ),
    );
    return Semantics(
      header: true,
      label: '${widget.first} ${widget.second}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rise(widget.first, 0),
            const SizedBox(height: AppSpacing.xxs),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rise(widget.second, .12, color: c.accent),
                  AnimatedBuilder(
                    animation: _a,
                    builder: (_, _) => CustomPaint(
                      size: const Size(double.infinity, 12),
                      painter: _Underline(
                        Curves.easeInOutCubic.transform(((_a.value - .55) / .4).clamp(0, 1)),
                        c.accent,
                      ),
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

/// The curved underline under the last word, drawn up to [t] (0 to 1).
class _Underline extends CustomPainter {
  _Underline(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final path = Path()
      ..moveTo(2, size.height * .7)
      ..quadraticBezierTo(size.width * .5, size.height * .05, size.width - 2, size.height * .55);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Underline o) => o.t != t || o.color != color;
}
