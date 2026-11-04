import 'dart:async';

import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six digits in cells, split 3 + 3, large enough to compare across two screens at a glance.
class DigitCells extends StatelessWidget {
  const DigitCells({required this.code, this.cellSize = 48, this.highlight = false, super.key});

  final String code;
  final double cellSize;

  /// Ink edges, for the verification code both devices must show.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    Widget cell(String digit) => Container(
      width: cellSize,
      height: cellSize * 1.2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: highlight ? c.ink : c.line, width: highlight ? 1.5 : 1),
      ),
      child: Text(
        digit,
        style: AppType.section.copyWith(
          fontSize: cellSize * 0.62,
          height: 1,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
        ),
      ),
    );

    final digits = code.split('');
    return Semantics(
      label: digits.join(' '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < digits.length; i++) ...[
            if (i == 3) SizedBox(width: cellSize * 0.35) else if (i > 0) const SizedBox(width: 6),
            cell(digits[i]),
          ],
        ],
      ),
    );
  }
}

/// The verification code both devices must show.
class VerificationCodeView extends StatelessWidget {
  const VerificationCodeView({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) => FittedBox(child: DigitCells(code: code, highlight: true, cellSize: 52));
}

/// A draining line and "Expires in 9:41"; calls [onExpired] once when time is up.
class ExpiryCountdown extends StatefulWidget {
  const ExpiryCountdown({required this.expiresAt, required this.lifetime, this.onExpired, super.key});

  final DateTime expiresAt;
  final Duration lifetime;
  final VoidCallback? onExpired;

  @override
  State<ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<ExpiryCountdown> {
  Timer? _timer;
  var _fired = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining == Duration.zero && !_fired) {
        _fired = true;
        _timer?.cancel();
        widget.onExpired?.call();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final left = widget.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final left = _remaining;
    final fraction = (left.inMilliseconds / widget.lifetime.inMilliseconds).clamp(0.0, 1.0);
    final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = left < const Duration(minutes: 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: fraction, color: urgent ? c.warnInk : c.ink),
        const SizedBox(height: AppSpacing.sm),
        Text(
          left == Duration.zero ? context.l10n.pairCodeExpired : context.l10n.pairExpiresIn(left.inMinutes, seconds),
          textAlign: TextAlign.center,
          style: AppType.supporting.copyWith(color: urgent ? c.warnInk : c.muted),
        ),
      ],
    );
  }
}

/// Six-digit entry drawn as six cells over one invisible text field (so paste, autofill and the system keyboard all
/// behave normally).
class PairingCodeField extends StatefulWidget {
  const PairingCodeField({required this.controller, required this.onSubmitted, this.enabled = true, super.key});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final bool enabled;

  @override
  State<PairingCodeField> createState() => _PairingCodeFieldState();
}

class _PairingCodeFieldState extends State<PairingCodeField> {
  final _focus = FocusNode();
  String? _submitted;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    final text = widget.controller.text;
    // Submit as soon as the sixth digit is in, once per code typed.
    if (text.length == 6 && widget.enabled && _focus.hasFocus && text != _submitted) {
      _submitted = text;
      widget.onSubmitted(text);
    } else if (text.length < 6) {
      _submitted = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final text = widget.controller.text;

    Widget cell(int i) {
      final active = _focus.hasFocus && (i == text.length || (i == 5 && text.length == 6));
      return Expanded(
        child: AspectRatio(
          aspectRatio: 0.85,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.smBorder,
              border: Border.all(color: active ? c.ink : c.line, width: active ? 1.5 : 1),
            ),
            child: Text(
              i < text.length ? text[i] : '',
              style: AppType.section.copyWith(color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i == 3) const SizedBox(width: AppSpacing.base) else if (i > 0) const SizedBox(width: 6),
                cell(i),
              ],
            ],
          ),
          // The real input: invisible, on top, so taps and paste reach it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brackets at the four corners of [child]: a scanner frame for QR codes.
class CornerFrame extends StatelessWidget {
  const CornerFrame({required this.child, this.length = 28, this.thickness = 2, super.key});

  final Widget child;
  final double length;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.ink;
    Widget corner(Alignment alignment) => Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: alignment.y < 0 ? BorderSide(color: color, width: thickness) : BorderSide.none,
              bottom: alignment.y > 0 ? BorderSide(color: color, width: thickness) : BorderSide.none,
              left: alignment.x < 0 ? BorderSide(color: color, width: thickness) : BorderSide.none,
              right: alignment.x > 0 ? BorderSide(color: color, width: thickness) : BorderSide.none,
            ),
          ),
        ),
      ),
    );
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                corner(Alignment.topLeft),
                corner(Alignment.topRight),
                corner(Alignment.bottomLeft),
                corner(Alignment.bottomRight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "1 Show code — 2 Verify — 3 Done": where the person is in pairing.
class PairingSteps extends StatelessWidget {
  const PairingSteps({required this.steps, required this.current, super.key});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Semantics(
      label: context.l10n.pairStepNamed(current + 1, steps.length, steps[current]),
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  color: i <= current ? c.ink : c.line,
                ),
              ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= current ? c.ink : null,
                border: i <= current ? null : Border.all(color: c.line),
              ),
              child: i < current
                  ? Icon(AppIcons.check, size: 13, color: c.bg)
                  : Text(
                      '${i + 1}',
                      style: AppType.label.copyWith(color: i <= current ? c.bg : c.muted, letterSpacing: 0),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              steps[i],
              style: AppType.supporting.copyWith(
                color: i == current ? c.ink : c.muted,
                fontWeight: i == current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
