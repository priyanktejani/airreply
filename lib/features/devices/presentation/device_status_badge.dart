import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/features/devices/domain/device_status.dart';
import 'package:flutter/material.dart';

/// A device's state as a small pill: a dot, the word and its colour together (accent connected, amber offline, red
/// needs permission, grey connecting with a spinner).
class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({required this.status, super.key});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (ground, ink) = switch (status.state) {
      DeviceState.connected => (c.accentSoft, c.accent),
      DeviceState.connecting => (c.soft, c.muted),
      DeviceState.disconnected => (c.warnSoft, c.warnInk),
      DeviceState.permissionRequired => (c.dangerSoft, c.danger),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: ground, borderRadius: AppRadius.fullBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xxs, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.state == DeviceState.connecting)
              SizedBox.square(dimension: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: ink))
            else
              LiveDot(color: ink, live: status.state == DeviceState.connected),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.label.copyWith(color: ink, letterSpacing: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small dot; when [live], a ring breathes out of it a few times as the connection comes up, then rests.
class LiveDot extends StatefulWidget {
  const LiveDot({required this.color, this.live = false, this.size = 8, super.key});

  final Color color;
  final bool live;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool? _was;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveDot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final live = widget.live && !MediaQuery.disableAnimationsOf(context);
    if (live && _was != true) {
      _pulse
        ..value = 0
        ..repeat(count: 3);
    } else if (!live && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
    _was = live;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.live)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_pulse.value);
                final d = size + size * 1.6 * t;
                return OverflowBox(
                  maxWidth: d,
                  maxHeight: d,
                  child: Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: .35 * (1 - t)),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
