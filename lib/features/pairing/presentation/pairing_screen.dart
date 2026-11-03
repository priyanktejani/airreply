import 'dart:async';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/animations/motion.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/app_platform.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_radius.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/time_format.dart';
import 'package:air_reply/core/widgets/empty_state.dart';
import 'package:air_reply/core/widgets/feedback.dart';
import 'package:air_reply/core/widgets/glass_scroll_page.dart';
import 'package:air_reply/core/widgets/notice.dart';
import 'package:air_reply/core/widgets/page_intro.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_session.dart';
import 'package:air_reply/features/pairing/presentation/controllers/receiver_pairing_controller.dart';
import 'package:air_reply/features/pairing/presentation/controllers/sender_pairing_controller.dart';
import 'package:air_reply/features/pairing/presentation/widgets/pairing_widgets.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pairing for this device's role: a sender shows a code, a receiver scans or types it. Both then compare a
/// verification code before anything is shared.
class PairingScreen extends ConsumerWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(deviceRoleProvider) == DeviceRole.sender ? const _SenderPairing() : const _ReceiverPairing();
}

/// App bar, title and steps shared by both sides. Unpaired devices may switch role from the menu.
class _PairingPage extends ConsumerWidget {
  const _PairingPage({
    required this.title,
    required this.step,
    required this.steps,
    required this.child,
    this.switchRole,
  });

  final String title;
  final int step;
  final List<String> steps;
  final Widget child;
  final String? switchRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paired = ref.watch(pairedDevicesProvider).isNotEmpty;
    return Scaffold(
      body: GlassScrollPage(
        maxWidth: 520,
        title: Text(paired ? 'Pair a device' : 'Pair'),
        leading: paired
            ? BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.devices))
            : null,
        actions: [
          if (!paired && switchRole != null)
            PopupMenuButton<void>(
              tooltip: 'More',
              itemBuilder: (_) => [
                PopupMenuItem(onTap: ref.read(deviceSessionProvider.notifier).clearRole, child: Text(switchRole!)),
              ],
            ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: PageIntro(eyebrow: 'Step ${step + 1} of ${steps.length}', title: title),
          ),
          SliverToBoxAdapter(
            child: PairingSteps(steps: steps, current: step),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: context.motion(AppMotion.slow),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ sender

class _SenderPairing extends ConsumerWidget {
  const _SenderPairing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(senderPairingProvider);
    final controller = ref.read(senderPairingProvider.notifier);
    final paired = ref.watch(pairedDevicesProvider).isNotEmpty;

    ref.listen(senderPairingProvider, (_, next) {
      if (next is SenderPairingDone) {
        ref.success();
        context
          ..showMessage('Paired with ${next.peerName}')
          ..go(AppRoutes.home);
      } else if (next is SenderPairingFailed) {
        ref.failure();
      }
    });

    return _PairingPage(
      title: paired ? 'Add a device' : 'Pair a device',
      steps: const ['Show code', 'Verify', 'Done'],
      step: switch (state) {
        SenderPairingVerifying() => 1,
        SenderPairingDone() => 2,
        _ => 0,
      },
      switchRole: 'Use this device as a receiver',
      child: switch (state) {
        SenderPairingStarting() || SenderPairingDone() => const _Loading(),
        SenderPairingWaiting(:final pending) => _ShowCode(
          key: ValueKey(pending.session.code),
          qrData: pending.invite.toUri(),
          code: pending.session.code,
          expiresAt: pending.session.expiresAt,
          onNewCode: controller.newCode,
        ),
        final SenderPairingVerifying verifying => _ConfirmCodes(
          state: verifying,
          onConfirm: controller.confirm,
          onReject: controller.reject,
        ),
        SenderPairingFailed(:final message) => EmptyState(
          icon: Icons.link_off,
          tone: Tone.error,
          title: 'Pairing stopped',
          description: message,
          action: FilledButton(onPressed: controller.newCode, child: const Text('Make a new code')),
        ),
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.huge + AppSpacing.base),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ShowCode extends StatelessWidget {
  const _ShowCode({
    required this.qrData,
    required this.code,
    required this.expiresAt,
    required this.onNewCode,
    super.key,
  });

  final String qrData;
  final String code;
  final DateTime expiresAt;
  final VoidCallback onNewCode;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'On your iPhone, iPad, Mac, PC, browser or other Android, open AirReply, choose "View and reply here", then '
          'scan this code or type the digits.',
          style: AppType.body.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: CornerFrame(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              margin: const EdgeInsets.all(AppSpacing.sm),
              // QR codes scan best dark on light, whatever the theme.
              color: Colors.white,
              child: Semantics(
                label: 'Pairing QR code',
                child: QrImageView(data: qrData, size: 220, backgroundColor: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'OR TYPE THIS CODE',
          textAlign: TextAlign.center,
          style: AppType.label.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: FittedBox(child: DigitCells(code: code)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) context.showMessage('Code ${formatSixDigits(code)} copied');
            },
            icon: const Icon(Icons.content_copy_outlined, size: 16),
            label: const Text('Copy code'),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        ExpiryCountdown(expiresAt: expiresAt, lifetime: PairingSession.lifetime, onExpired: onNewCode),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: onNewCode,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('New code'),
        ),
      ],
    );
  }
}

class _ConfirmCodes extends StatelessWidget {
  const _ConfirmCodes({required this.state, required this.onConfirm, required this.onReject});

  final SenderPairingVerifying state;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Do the codes match?', style: AppType.pageTitle.copyWith(color: c.ink)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${state.receiverName} wants to pair. It must show exactly this code. If it does not, someone else may be '
          'trying to connect.',
          style: AppType.body.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        VerificationCodeView(code: state.secrets.verificationCode),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: state.confirming ? null : onConfirm,
          child: state.confirming
              ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.bg))
              : const Text('Codes match, pair'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: state.confirming ? null : onReject,
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: const Text('They do not match'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ receiver

enum _Method { scan, code }

class _ReceiverPairing extends ConsumerStatefulWidget {
  const _ReceiverPairing();

  @override
  ConsumerState<_ReceiverPairing> createState() => _ReceiverPairingState();
}

class _ReceiverPairingState extends ConsumerState<_ReceiverPairing> {
  final _code = TextEditingController();

  // Phones scan; desktops type the code (webcam scanning is awkward, and Windows/Linux have no scanner).
  var _method = AppPlatform.canScanQr && !AppPlatform.isDesktop ? _Method.scan : _Method.code;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiverPairingProvider);
    final controller = ref.read(receiverPairingProvider.notifier);
    final paired = ref.watch(pairedDevicesProvider).isNotEmpty;
    final c = context.palette;

    ref.listen(receiverPairingProvider, (previous, next) {
      if (next is ReceiverPairingDone) {
        ref.success();
        context
          ..showMessage('Paired with ${next.peerName}')
          ..go(AppRoutes.home);
      } else if (next is ReceiverPairingIdle && next.error != null && previous is! ReceiverPairingIdle) {
        ref.failure();
        _code.clear();
      }
    });

    return _PairingPage(
      title: paired ? 'Add another phone' : 'Pair with your phone',
      steps: const ['Enter code', 'Verify', 'Done'],
      step: switch (state) {
        ReceiverPairingAwaitingConfirmation() => 1,
        ReceiverPairingDone() => 2,
        _ => 0,
      },
      switchRole: AppPlatform.canShareNotifications ? 'Use this device as the sender' : null,
      child: switch (state) {
        ReceiverPairingAwaitingConfirmation(:final joined) => _AwaitingConfirmation(
          senderName: joined.session.senderName,
          code: joined.secrets.verificationCode,
          onCancel: controller.cancel,
        ),
        ReceiverPairingDone() => const _Loading(),
        _ => Column(
          key: const ValueKey('enter'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'On the Android phone you want to see here, open AirReply and choose "Share my notifications" (or '
              '"Add a device" if it already shares). It shows a QR code and six digits.',
              style: AppType.body.copyWith(color: c.muted),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (AppPlatform.canScanQr) ...[
              SegmentedButton<_Method>(
                segments: const [
                  ButtonSegment(value: _Method.scan, icon: Icon(Icons.qr_code_scanner), label: Text('Scan')),
                  ButtonSegment(value: _Method.code, icon: Icon(Icons.dialpad), label: Text('Type code')),
                ],
                selected: {_method},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (_method == _Method.scan && AppPlatform.canScanQr)
              _Scanner(enabled: state is ReceiverPairingIdle, onScan: controller.joinFromQr)
            else ...[
              Text('PAIRING CODE', style: AppType.label.copyWith(color: c.muted)),
              const SizedBox(height: AppSpacing.md),
              PairingCodeField(
                controller: _code,
                enabled: state is ReceiverPairingIdle,
                onSubmitted: controller.joinWithCode,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pairing starts as soon as you type the last digit.',
                style: AppType.supporting.copyWith(color: c.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.base),
            if (state is ReceiverPairingJoining) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connecting…',
                textAlign: TextAlign.center,
                style: AppType.supporting.copyWith(color: c.muted),
              ),
            ],
            if (state case ReceiverPairingIdle(:final String error))
              Notice(tone: Tone.error, title: 'Could not pair', message: error),
          ],
        ),
      },
    );
  }
}

class _Scanner extends StatefulWidget {
  const _Scanner({required this.enabled, required this.onScan});

  final bool enabled;
  final Future<void> Function(String raw) onScan;

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!widget.enabled) return;
    final raw = capture.barcodes.map((b) => b.rawValue).nonNulls.firstOrNull;
    if (raw != null) unawaited(widget.onScan(raw));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CornerFrame(
            length: 36,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: ClipRRect(
                borderRadius: AppRadius.smBorder,
                child: MobileScanner(controller: _controller, onDetect: _onDetect),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Point the camera at the QR code on your phone.',
          textAlign: TextAlign.center,
          style: AppType.supporting.copyWith(color: context.palette.muted),
        ),
      ],
    );
  }
}

class _AwaitingConfirmation extends StatelessWidget {
  const _AwaitingConfirmation({required this.senderName, required this.code, required this.onCancel});

  final String senderName;
  final String code;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      key: const ValueKey('verify'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm on $senderName', style: AppType.pageTitle.copyWith(color: c.ink)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Check that your phone shows the same code, then tap "Codes match" there.',
          style: AppType.body.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        VerificationCodeView(code: code),
        const SizedBox(height: AppSpacing.xxl),
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Waiting for your phone…',
          textAlign: TextAlign.center,
          style: AppType.supporting.copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}
