import 'package:air_reply/core/error/app_exception.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/widgets/app_logo.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown while the device session loads from secure storage; the router moves on as soon as it has a value.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: switch (ref.watch(deviceSessionProvider)) {
          AsyncError(:final error) => EmptyState(
            icon: AppIcons.errorOutline,
            tone: Tone.error,
            title: 'AirReply could not start',
            description: describeError(error),
            action: FilledButton(
              onPressed: () => ref.invalidate(deviceSessionProvider),
              child: const Text('Try again'),
            ),
          ),
          _ => Semantics(
            label: 'AirReply is starting',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(height: 34),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(width: 96, child: LinearProgressIndicator()),
              ],
            ),
          ),
        },
      ),
    );
  }
}
