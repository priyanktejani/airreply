import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app's haptics are on (Settings → Haptic feedback). On by default; the bootstrap ties it to the
/// person's preference, so this is the one place every haptic reads it.
final hapticsEnabledProvider = Provider<bool>((ref) => true);

/// The app's haptics, named by what happened rather than by strength, as ColorOS 16's own apps do: nothing for
/// getting around (switching tabs, opening or closing something, menus), a crisp tick for a choice or for a gesture
/// reaching the point where it acts, a firmer press when a long press opens a menu, light for something done, firm for
/// something refused.
abstract final class Haptics {
  /// A switch flipped, an option or a chip chosen.
  static void selection() => HapticFeedback.selectionClick();

  /// A gesture reached the point where it acts: a swipe passing its threshold, a pull that will refresh.
  static void threshold() => HapticFeedback.selectionClick();

  /// A long press took hold (it opens a menu). Android's own long-press feedback, which each maker tunes; on Apple
  /// devices a medium tap, as iOS's context menus give.
  static void longPress() =>
      defaultTargetPlatform == TargetPlatform.android ? HapticFeedback.vibrate() : HapticFeedback.mediumImpact();

  /// Something was sent or completed.
  static void success() => HapticFeedback.lightImpact();

  /// Something failed or was refused.
  static void failure() => HapticFeedback.heavyImpact();
}

/// The haptics from a widget with a [WidgetRef], silent when they are off.
extension HapticsRef on WidgetRef {
  bool get _on => read(hapticsEnabledProvider);

  /// A choice made (see [Haptics.selection]).
  void tick() {
    if (_on) Haptics.selection();
  }

  /// A gesture's threshold (see [Haptics.threshold]).
  void threshold() {
    if (_on) Haptics.threshold();
  }

  void success() {
    if (_on) Haptics.success();
  }

  void failure() {
    if (_on) Haptics.failure();
  }
}

/// The haptics from any widget under the app's provider scope; on, where there is none (a widget shown alone).
extension HapticsContext on BuildContext {
  bool get _hapticsOn {
    try {
      return ProviderScope.containerOf(this, listen: false).read(hapticsEnabledProvider);
    } on StateError {
      return true;
    }
  }

  /// A gesture's threshold (see [Haptics.threshold]).
  void hapticThreshold() {
    if (_hapticsOn) Haptics.threshold();
  }

  /// [onLongPress] with the long-press haptic first, for an [InkWell] with `enableFeedback: false` (its own feedback
  /// would ignore Settings → Haptic feedback).
  VoidCallback? withLongPressHaptic(VoidCallback? onLongPress) => onLongPress == null
      ? null
      : () {
          if (_hapticsOn) Haptics.longPress();
          onLongPress();
        };

  /// [onTap] with the system's tap sound, which `enableFeedback: false` would otherwise take away.
  VoidCallback? withTapSound(VoidCallback? onTap) => onTap == null
      ? null
      : () {
          Feedback.forTap(this);
          onTap();
        };
}
