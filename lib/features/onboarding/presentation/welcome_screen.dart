import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_tokens.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/widgets/editorial.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First launch: does this device share its notifications, or show and answer another phone's?
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final canShare = AppPlatform.canShareNotifications;

    void choose(DeviceRole role) {
      ref.tick();
      runGuarded(context, () => ref.read(deviceSessionProvider.notifier).chooseRole(role));
    }

    final sender = _RoleOption(
      icon: Icons.smartphone_outlined,
      title: 'Share my notifications',
      description: canShare
          ? 'This phone sends its notifications to your other devices, and sends the replies you write there.'
          : 'Only Android lets apps read notifications. Use an Android phone to share.',
      onTap: canShare ? () => choose(DeviceRole.sender) : null,
    );
    final receiver = _RoleOption(
      icon: Icons.devices_outlined,
      title: 'View and reply here',
      description: 'See your phone\'s notifications on this device and answer messages without picking it up.',
      onTap: () => choose(DeviceRole.receiver),
    );

    return Scaffold(
      body: EditorialPage(
        maxWidth: 560,
        header: PageHeader(
          eyebrow: 'AirReply',
          title: 'Your phone\'s notifications, on every screen.',
          subtitle: const Text('Read them on your iPhone, iPad, Mac, PC or browser, and reply to messages from there.'),
        ),
        slivers: [
          SliverList.list(
            children: [
              const SectionLabel('How will you use this device?', top: Space.x4),
              // The option this platform can use goes first.
              RuledList(children: canShare ? [sender, receiver] : [receiver, sender]),
              const SizedBox(height: Space.x8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: c.secondary),
                  const SizedBox(width: Space.x2),
                  Expanded(
                    child: Text(
                      'End-to-end encrypted with a key only your devices hold. The server relays ciphertext it '
                      'cannot read.',
                      style: AppType.supporting.copyWith(color: c.secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.icon, required this.title, required this.description, required this.onTap});

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: enabled ? c.ink : c.disabled),
              const SizedBox(width: Space.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.title.copyWith(color: enabled ? c.ink : c.disabled)),
                    const SizedBox(height: Space.x1),
                    Text(description, style: AppType.body.copyWith(color: c.secondary)),
                  ],
                ),
              ),
              const SizedBox(width: Space.x3),
              Icon(enabled ? Icons.arrow_forward : Icons.block, size: 20, color: enabled ? c.ink : c.disabled),
            ],
          ),
        ),
      ),
    );
  }
}
