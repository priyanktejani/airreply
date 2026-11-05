import 'dart:async';

import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/l10n/l10n.dart';
import 'package:air_reply/core/platform/system_notification_settings.dart';
import 'package:air_reply/core/theme/app_icons.dart';
import 'package:air_reply/core/theme/app_palette.dart';
import 'package:air_reply/core/theme/app_spacing.dart';
import 'package:air_reply/core/theme/app_typography.dart';
import 'package:air_reply/core/utils/guarded.dart';
import 'package:air_reply/core/widgets/app_sheet.dart';
import 'package:air_reply/core/widgets/icon_tile.dart';
import 'package:air_reply/core/widgets/notice.dart';
import 'package:air_reply/core/widgets/status_badge.dart';
import 'package:air_reply/features/notifications/alert_delivery_provider.dart';
import 'package:air_reply/features/notifications/domain/alert_delivery.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone maker's own name, as people see it on the phone.
String makerName(String vendor) => switch (vendor) {
  'oneplus' => 'OnePlus',
  'oppo' => 'OPPO',
  'realme' => 'realme',
  'xiaomi' => 'Xiaomi',
  'redmi' => 'Redmi',
  'poco' => 'POCO',
  'samsung' => 'Samsung',
  'vivo' => 'vivo',
  'iqoo' => 'iQOO',
  'huawei' => 'Huawei',
  'honor' => 'HONOR',
  _ => vendor.isEmpty ? '' : vendor[0].toUpperCase() + vendor.substring(1),
};

String alertDeliveryTitle(AppLocalizations l10n, AlertDelivery delivery) =>
    delivery.popsUp ? l10n.alertSoundOffTitle : l10n.popUpsTitle;

/// Why AirReply cannot fix it itself, then where the switch is on this maker's phones.
String alertDeliveryHelp(AppLocalizations l10n, AlertDelivery delivery) {
  // switched off, not held back: nothing about makers' lists
  if (delivery.messages == AlertExpectation.off) return l10n.expectOffHelp;
  final maker = makerName(delivery.vendor);
  final why = maker.isEmpty ? l10n.popUpsWhyGeneric : l10n.popUpsWhy(maker);
  final steps = switch (delivery.vendor) {
    'oneplus' || 'oppo' || 'realme' => l10n.popUpsStepsOppo(l10n.alertChannelPopUp),
    'xiaomi' || 'redmi' || 'poco' => l10n.popUpsStepsXiaomi,
    'samsung' => l10n.popUpsStepsSamsung,
    _ => l10n.popUpsStepsGeneric,
  };
  return '$why $steps';
}

/// Opens the system settings of the channel to fix and, when the person comes back with it fixed, says so. Shared by
/// the prompt, the Setup assistant and How alerts appear.
Future<void> fixAlertDelivery(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final fixed = context.l10n.popUpsFixed;
  final controller = ref.read(alertDeliveryProvider.notifier);
  // one at a time: a second tap before coming back replaces the first
  _pendingFix?.dispose();
  late final AppLifecycleListener listener;
  _pendingFix = listener = AppLifecycleListener(
    onResume: () {
      listener.dispose();
      if (identical(_pendingFix, listener)) _pendingFix = null;
      unawaited(
        controller.refresh().then((delivery) {
          if (delivery?.works ?? false) messenger?.showSnackBar(SnackBar(content: Text(fixed)));
        }, onError: (Object _) {}),
      );
    },
  );
  try {
    await controller.openSettings();
  } on Object {
    listener.dispose();
    if (identical(_pendingFix, listener)) _pendingFix = null;
    rethrow;
  }
}

/// The resume listener of the last trip to the system's settings, until the person comes back.
AppLifecycleListener? _pendingFix;

/// What alerts will do on this device, as its own settings have them now: the top of Settings' Alerts. Fine (messages
/// pop up with sound), held back (with why and the switch), or off (with Allow). Checked again on coming back from
/// the system's settings.
class AlertExpectationBanner extends ConsumerStatefulWidget {
  const AlertExpectationBanner({super.key});

  @override
  ConsumerState<AlertExpectationBanner> createState() => _AlertExpectationBannerState();
}

class _AlertExpectationBannerState extends ConsumerState<AlertExpectationBanner> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      unawaited(ref.read(alertPermissionProvider.notifier).refresh());
      unawaited(ref.read(alertDeliveryProvider.notifier).refresh().catchError((Object _) => null));
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    final permission = ref.read(alertPermissionProvider.notifier);
    await permission.request();
    // refused for good: only the system's page can turn them on now
    if (!(ref.read(alertPermissionProvider).value ?? false)) {
      await openSystemNotificationSettings(ref.read(notificationBridgeProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget banner;
    if (ref.watch(alertPermissionProvider).value == false) {
      banner = Notice(
        tone: Tone.error,
        icon: AppIcons.notificationsOff,
        title: l10n.noticeAlertsOffTitle,
        message: l10n.expectAlertsOffText,
        actions: [FilledButton(onPressed: guarded(context, _allow), child: Text(l10n.actionAllow))],
      );
    } else {
      final delivery = ref.watch(alertDeliveryProvider).value;
      final messages = delivery?.messages;
      if (delivery == null || messages == null) return const SizedBox.shrink();
      final others = delivery.others;
      final lines = [
        if (others != null) l10n.expectOthers(_othersPhrase(l10n, others)),
        if (delivery.works) l10n.expectChangeHint else alertDeliveryHelp(l10n, delivery),
      ];
      banner = Notice(
        tone: switch (messages) {
          _ when delivery.works => Tone.success,
          AlertExpectation.off => Tone.error,
          _ => Tone.warning,
        },
        icon: delivery.works ? AppIcons.notificationsActive : AppIcons.notificationsPaused,
        title: _messagesTitle(l10n, messages),
        message: lines.join(' '),
        actions: [
          if (!delivery.works)
            FilledButton(
              onPressed: () => unawaited(fixAlertDelivery(context, ref)),
              child: Text(l10n.actionOpenAlertSettings),
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: banner,
    );
  }

  static String _messagesTitle(AppLocalizations l10n, AlertExpectation e) => switch (e) {
    AlertExpectation.popUp => l10n.expectMessagesPopUp,
    AlertExpectation.popUpSilent => l10n.expectMessagesPopUpSilent,
    AlertExpectation.list => l10n.expectMessagesList,
    AlertExpectation.quiet => l10n.expectMessagesQuiet,
    AlertExpectation.off => l10n.expectMessagesOff,
  };

  static String _othersPhrase(AppLocalizations l10n, AlertExpectation e) => switch (e) {
    AlertExpectation.popUp => l10n.expectOthersPopUp,
    AlertExpectation.popUpSilent => l10n.expectOthersPopUpSilent,
    AlertExpectation.list => l10n.expectOthersList,
    AlertExpectation.quiet => l10n.expectOthersQuiet,
    AlertExpectation.off => l10n.expectOthersOff,
  };
}

/// Asked once, on Home, the first time the phone is found holding alerts back: the one step no app can take for the
/// person. Afterwards the Setup assistant and Settings' Alerts keep offering it.
Future<void> showAlertDeliveryPrompt(BuildContext context, WidgetRef ref, AlertDelivery delivery) async {
  final open = await showAppSheet<bool>(context, builder: (_) => _AlertDeliveryPrompt(delivery));
  // from the page that asked, which stays (the sheet is gone by now)
  if ((open ?? false) && context.mounted) await fixAlertDelivery(context, ref);
}

class _AlertDeliveryPrompt extends StatelessWidget {
  const _AlertDeliveryPrompt(this.delivery);

  final AlertDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.base),
        const Align(alignment: Alignment.centerLeft, child: IconTile(AppIcons.notificationsActive)),
        const SizedBox(height: AppSpacing.base),
        Text(
          delivery.popsUp ? l10n.alertSoundOffTitle : l10n.popUpsPromptTitle,
          style: AppType.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(alertDeliveryHelp(l10n, delivery), style: AppType.body.copyWith(color: c.muted)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.actionOpenAlertSettings)),
        const SizedBox(height: AppSpacing.xs),
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.actionNotNow)),
      ],
    );
  }
}
