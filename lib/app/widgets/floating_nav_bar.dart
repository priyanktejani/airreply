import 'package:air_reply/core/animations/fade_slide_in.dart';
import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One tab of the [FloatingNavBar].
class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticLabel,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// What screen readers say, when it differs from [label] ("Notifications, 6 unread").
  final String? semanticLabel;

  /// A count on the icon (unread notifications); none at 0.
  final int badge;
}

/// The app's navigation: a frosted-glass pill floating above the content, with a soft green highlight that slides to
/// the selected tab. It sits clear of the screen edges and the phone's home indicator; put it in a Scaffold's
/// `bottomNavigationBar` with `extendBody: true` so content scrolls underneath and lists can pad for it (AppInsets).
///
/// With [popIn] its tabs rise in one after another when it is built.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.popIn = false,
    super.key,
  });

  final List<FloatingNavItem> items;
  final bool popIn;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final duration = still ? Duration.zero : const Duration(milliseconds: 320);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppDimensions.navBarMargin),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: GlassContainer(
              floating: true,
              height: AppDimensions.navBarHeight,
              borderRadius: AppRadius.fullBorder,
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, box) {
                  final slot = box.maxWidth / items.length;
                  return Stack(
                    children: [
                      // the selected tab's highlight glides between tabs
                      AnimatedPositioned(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        left: slot * selectedIndex,
                        top: 0,
                        bottom: 0,
                        width: slot,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.palette.accentSoft,
                            borderRadius: AppRadius.fullBorder,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                              child: _popIn(
                                i,
                                _NavTab(
                                  item: items[i],
                                  selected: i == selectedIndex,
                                  duration: duration,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    onSelected(i);
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popIn(int i, Widget tab) => popIn ? FadeSlideIn.staggered(index: i, offset: 12, child: tab) : tab;
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.duration, required this.onTap});

  final FloatingNavItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final color = selected ? c.accent : c.muted;
    final icon = AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: duration,
      curve: Curves.easeOutBack,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: duration,
        builder: (context, col, _) => Icon(selected ? item.selectedIcon : item.icon, size: 22, color: col),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticLabel ?? item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.semanticLabel ?? item.label,
        // the ripple takes the same pill shape as the selection behind it, drawn on the glass rather than under it
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.badge > 0)
                  Badge(label: Text(item.badge > 99 ? '99+' : '${item.badge}'), child: icon)
                else
                  icon,
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: AppType.caption.copyWith(
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                  child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
