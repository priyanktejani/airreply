import 'package:air_reply/core/theme/app_dimensions.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet on frosted glass over the whole app: rounded top, a handle, the page dimmed behind, and room
/// for the keyboard. Use it for every sheet so they look and behave the same. [builder] builds the sheet's content
/// (scrolling and padded for you unless [padding] is zero).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  EdgeInsets padding = const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xs, AppSpacing.page, AppSpacing.page),
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  elevation: 0,
  constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
  builder: (c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
    child: AppSheetFrame(
      child: Flexible(
        child: SingleChildScrollView(
          padding: padding,
          child: Builder(builder: builder),
        ),
      ),
    ),
  ),
);

/// The sheet itself: strong frosted glass with a rounded top and the handle, then [child] (a [Flexible] or
/// [Expanded] for content that scrolls on its own).
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({required this.child, super.key});

  final Widget child;

  static const double _handleWidth = 40;

  @override
  Widget build(BuildContext context) => GlassContainer(
    strong: true,
    floating: true,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xxs),
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.palette.line, borderRadius: AppRadius.fullBorder),
                child: const SizedBox(width: _handleWidth, height: AppSpacing.xs),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}
