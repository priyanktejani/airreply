import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// The big headline of Home and Welcome: [first] on one line, then [second] in the accent colour with a drawn underline, left
/// aligned. Each line rises into place, then the underline draws itself.
class UnderlinedHeadline extends StatefulWidget {
  const UnderlinedHeadline({required this.first, required this.second, super.key});

  final String first;
  final String second;

  @override
  State<UnderlinedHeadline> createState() => _UnderlinedHeadlineState();
}

class _UnderlinedHeadlineState extends State<UnderlinedHeadline> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _a.value = 1;
    } else if (_a.value == 0 && !_a.isAnimating) {
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
