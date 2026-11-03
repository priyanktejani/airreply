import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The AirReply logo: the reply mark (a reply arrow on a glowing brand-green circle, as on the app icon) and the
/// "AirReply" wordmark beside it, sized by [height]. [wordmark] false shows the mark alone (the rail, small spaces).
class AppLogo extends StatelessWidget {
  const AppLogo({this.height = 26, this.wordmark = true, super.key});

  final double height;
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final mark = Container(
      width: height,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.accent,
        boxShadow: [BoxShadow(color: c.accent.withValues(alpha: .35), blurRadius: height * .5)],
      ),
      child: Icon(Icons.reply_rounded, size: height * .62, color: c.accentInk),
    );
    return Semantics(
      label: 'AirReply',
      excludeSemantics: true,
      // shrinks a little rather than overflowing where space is tight (a narrow phone's app bar)
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            if (wordmark) ...[
              SizedBox(width: height * .28),
              Text(
                'AirReply',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: height * 1.0,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -height * .04,
                  color: c.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
