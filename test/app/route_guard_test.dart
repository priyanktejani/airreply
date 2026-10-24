import 'dart:typed_data';

import 'package:air_reply/app/router/route_guard.dart';
import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/features/pairing/domain/entities/pairing_credentials.dart';
import 'package:air_reply/features/session/domain/device_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PairingCredentials credentials(DeviceRole role, {String pairId = 'p'}) => PairingCredentials(
  pairId: pairId,
  role: role,
  sharedKey: Uint8List(32),
  peerName: 'Peer',
  pairedAt: DateTime(2026),
);

void main() {
  String? redirect(DeviceSession session, String location) => resolveRedirect(AsyncData(session), location);

  test('stays on the splash screen while the session loads', () {
    expect(resolveRedirect(const AsyncLoading(), AppRoutes.welcome), AppRoutes.splash);
    expect(resolveRedirect(const AsyncLoading(), AppRoutes.splash), isNull);
  });

  test('a fresh install chooses a role first', () {
    expect(redirect(DeviceSession.fresh, AppRoutes.splash), AppRoutes.welcome);
    expect(redirect(DeviceSession.fresh, AppRoutes.home), AppRoutes.welcome);
    expect(redirect(DeviceSession.fresh, AppRoutes.welcome), isNull);
  });

  test('a sender sees the disclosure before anything else, then pairs', () {
    const sender = DeviceSession(role: DeviceRole.sender);
    expect(redirect(sender, AppRoutes.pair), AppRoutes.setup);
    expect(redirect(sender, AppRoutes.home), AppRoutes.setup);

    final accepted = sender.withDisclosureAccepted();
    expect(redirect(accepted, AppRoutes.splash), AppRoutes.pair);
    expect(redirect(accepted, AppRoutes.setup), isNull);
    expect(redirect(accepted, AppRoutes.home), AppRoutes.pair);
  });

  test('a paired sender lands on Home, uses every tab and can add more devices', () {
    final paired = const DeviceSession(
      role: DeviceRole.sender,
      disclosureAccepted: true,
    ).withPair(credentials(DeviceRole.sender));
    expect(redirect(paired, AppRoutes.splash), AppRoutes.home);
    expect(redirect(paired, AppRoutes.welcome), AppRoutes.home);
    for (final location in [
      ...AppRoutes.tabs,
      AppRoutes.apps,
      AppRoutes.diagnostics,
      AppRoutes.pair,
      AppRoutes.setup,
    ]) {
      expect(redirect(paired, location), isNull, reason: location);
    }
    expect(redirect(paired, AppRoutes.notification('p', 'n1')), isNull);
  });

  test('a receiver pairs, then lives in the tabs and can add more phones', () {
    const receiver = DeviceSession(role: DeviceRole.receiver);
    expect(redirect(receiver, AppRoutes.splash), AppRoutes.pair);
    expect(redirect(receiver, AppRoutes.notifications), AppRoutes.pair);

    final paired = receiver.withPair(credentials(DeviceRole.receiver));
    expect(redirect(paired, AppRoutes.splash), AppRoutes.home);
    expect(redirect(paired, AppRoutes.pair), isNull);
    expect(redirect(paired, AppRoutes.settings), isNull);
    expect(redirect(paired, AppRoutes.notification('p', 'n1')), isNull);
    // Setup is the sender's notification-access flow.
    expect(redirect(paired, AppRoutes.setup), AppRoutes.home);
  });

  test('only real tab paths match, not look-alikes', () {
    final paired = const DeviceSession(role: DeviceRole.receiver).withPair(credentials(DeviceRole.receiver));
    expect(redirect(paired, '/homework'), AppRoutes.home);
    expect(redirect(paired, '/settingsx'), AppRoutes.home);
  });

  test('removing the last pair keeps the role and sends the device back to pairing', () {
    final two = const DeviceSession(
      role: DeviceRole.receiver,
    ).withPair(credentials(DeviceRole.receiver, pairId: 'a')).withPair(credentials(DeviceRole.receiver, pairId: 'b'));
    expect(two.pairs, hasLength(2));

    final one = two.withoutPair('a');
    expect(redirect(one, AppRoutes.notifications), isNull);

    final none = one.withoutPair('b');
    expect(none.role, DeviceRole.receiver);
    expect(redirect(none, AppRoutes.notifications), AppRoutes.pair);
  });

  test('notification links survive ids that need escaping', () {
    expect(AppRoutes.notification('pair/1', 'a b'), '/notifications/pair%2F1/a%20b');
  });
}
