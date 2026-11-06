import 'package:air_reply/core/core_providers.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/sender/presentation/controllers/sender_controllers.dart';
import 'package:air_reply/features/session/session_providers.dart';
import 'package:air_reply/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../support/fakes.dart';

void main() {
  test('"Receive when AirReply is closed": the choice is kept and the service follows it, in one step', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final bridge = FakeNotificationBridge();
    final container = ProviderContainer(
      overrides: [
        notificationBridgeProvider.overrideWithValue(bridge),
        deviceRoleProvider.overrideWithValue(DeviceRole.receiver),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncStatusProvider, (_, _) {});

    await container.read(syncStatusProvider.notifier).setReceiveWhenClosed(true);
    expect(bridge.syncStarted, isTrue);
    expect(bridge.startedReceiving, isTrue, reason: 'receiving, not sharing');
    expect((await container.read(appPreferencesProvider.future)).receiveWhenClosed, isTrue);

    await container.read(syncStatusProvider.notifier).setReceiveWhenClosed(false);
    expect(bridge.syncStopped, isTrue);
    expect((await container.read(appPreferencesProvider.future)).receiveWhenClosed, isFalse);
  });
}
