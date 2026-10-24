import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/platform/background_sync_channel.dart';
import 'package:air_reply/features/mirror/mirror_providers.dart';
import 'package:air_reply/features/sender/background/sender_sync_runner.dart';
import 'package:air_reply/features/sender/data/icon_delivery.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _pairIdsProvider = Provider<List<String>>((ref) => [for (final p in ref.watch(pairedDevicesProvider)) p.pairId]);

final publishCapturedNotificationProvider = Provider(
  (ref) => PublishCapturedNotification(
    [
      for (final pairId in ref.watch(_pairIdsProvider))
        PublishTarget(pairId, ref.watch(notificationPublisherProvider(pairId))),
    ],
    icons: BridgeAppIconSource(ref.watch(notificationBridgeProvider)),
    iconLog: PreferencesIconDeliveryLog(ref.watch(sharedPreferencesProvider)),
  ),
);

final markNotificationDismissedProvider = Provider(
  (ref) => MarkNotificationDismissed([
    for (final pairId in ref.watch(_pairIdsProvider)) ref.watch(notificationPublisherProvider(pairId)),
  ]),
);

final backgroundSyncChannelProvider = Provider<BackgroundSyncChannel>((ref) => MethodChannelBackgroundSyncChannel());

final senderSyncRunnerProvider = Provider((ref) {
  final bridge = ref.watch(notificationBridgeProvider);
  final runner = SenderSyncRunner(
    channel: ref.watch(backgroundSyncChannelProvider),
    pairs: [
      for (final pairId in ref.watch(_pairIdsProvider))
        SenderPairLink(
          pairId: pairId,
          inbox: ref.watch(replyInboxProvider(pairId)),
          executeReply: ExecutePendingReply(bridge, ref.watch(replyInboxProvider(pairId))),
        ),
    ],
    publish: ref.watch(publishCapturedNotificationProvider),
    markDismissed: ref.watch(markNotificationDismissedProvider),
  );
  ref.onDispose(runner.stop);
  return runner;
});
