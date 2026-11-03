import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// The steps on one card, numbered and joined by a line: a receiver's ([steps]) or a phone's ([senderSteps]).
class HowItWorks extends StatelessWidget {
  const HowItWorks({this.items = steps, super.key});

  final List<(String, String)> items;

  static const steps = [
    ('Share from your phone', 'On your Android phone, AirReply sends each notification here, end-to-end encrypted.'),
    ('Read it here', 'Notifications arrive within seconds, grouped by app and by person.'),
    ('Reply from anywhere', 'Write an answer here; your phone sends it through the app it came from.'),
  ];

  static const senderSteps = [
    ('Pick what to share', 'Choose every app, or only the ones you want on your other devices.'),
    ('Pair your devices', 'A Mac, PC, iPhone, iPad or browser scans a code once, and they stay paired.'),
    ('Reply from anywhere', 'Replies written there are sent from this phone, through the app they belong to.'),
  ];

  /// The numbered dot's diameter.
  static const double _dot = 36;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    // each title's line is centred on its numbered dot (the line grows with the phone's text size)
    final titleLine = MediaQuery.textScalerOf(context).scale(AppType.title.fontSize!) * AppType.title.height!;
    final titleTop = ((_dot - titleLine) / 2).clamp(0.0, _dot);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (final (i, (title, text)) in items.indexed)
            FadeSlideIn.staggered(
              index: i * 2,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: _dot / 2,
                          backgroundColor: c.accent,
                          child: Text(
                            '${i + 1}',
                            style: AppType.titleSmall.copyWith(color: c.accentInk, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (i < items.length - 1)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              child: VerticalDivider(width: 2, thickness: 2, color: c.line),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: titleTop, bottom: i < items.length - 1 ? AppSpacing.lg : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppType.title.copyWith(color: c.ink)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(text, style: AppType.body.copyWith(color: c.muted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
