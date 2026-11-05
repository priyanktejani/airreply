import 'package:air_reply/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The AirReply logo: the app icon (two chat bubbles, a reply arrow on the front one, on a dark rounded square) and
/// the "AirReply" wordmark beside it, sized by [height]. [wordmark] false shows the mark alone (the rail, small spaces).
class AppLogo extends StatelessWidget {
  const AppLogo({this.height = 26, this.wordmark = true, super.key});

  final double height;
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    // the app icon itself (drawn by tool/make_app_icon.py), as launchers show it
    final mark = Image.asset(
      'assets/icon/app_logo.png',
      width: height,
      height: height,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
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
