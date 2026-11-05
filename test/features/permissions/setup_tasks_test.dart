import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/permissions/domain/setup_tasks.dart';
import 'package:flutter_test/flutter_test.dart';

SenderGrants grants({
  bool access = true,
  bool post = true,
  bool battery = true,
  bool background = false,
  bool autostartScreen = false,
  String vendor = 'google',
}) => (
  notificationAccess: access,
  postNotifications: post,
  restrictions: BackgroundRestrictions(
    vendor: vendor,
    hasAutostartScreen: autostartScreen,
    ignoringBatteryOptimizations: battery,
    backgroundRestricted: background,
  ),
);

const on = SyncStatus(enabled: true, running: true, listenerConnected: true);

Map<SetupTaskId, SetupState> states(List<SetupTask> tasks) => {for (final t in tasks) t.id: t.state};

void main() {
  test('a phone with everything granted, paired and sharing: all done', () {
    final tasks = setupTasks(role: DeviceRole.sender, paired: true, sender: grants(), sharing: on);
    expect(tasks.allDone, isTrue);
    expect(tasks.doneCount, tasks.length);
    expect(tasks.map((t) => t.id), isNot(contains(SetupTaskId.autostart)), reason: 'no autostart screen here');
  });

  test('notification access refused or revoked: required and open; the listener is not asked about then', () {
    final tasks = setupTasks(role: DeviceRole.sender, paired: true, sender: grants(access: false), sharing: on);
    expect(states(tasks)[SetupTaskId.notificationAccess], SetupState.todo);
    expect(states(tasks), isNot(contains(SetupTaskId.listener)));
    expect(tasks.requiredOpen, isTrue);
  });

  test('sharing paused, or a listener Android stopped (force stop, reboot): required and open', () {
    final paused = setupTasks(
      role: DeviceRole.sender,
      paired: true,
      sender: grants(),
      sharing: const SyncStatus(enabled: false, running: false, listenerConnected: false),
    );
    expect(states(paused)[SetupTaskId.sharingOn], SetupState.todo);
    final stopped = setupTasks(
      role: DeviceRole.sender,
      paired: true,
      sender: grants(),
      sharing: const SyncStatus(enabled: true, running: true, listenerConnected: false),
    );
    expect(states(stopped)[SetupTaskId.listener], SetupState.todo);
    expect(stopped.requiredOpen, isTrue);
  });

  test('battery optimisation on: recommended; background usage restricted: required', () {
    final tasks = setupTasks(
      role: DeviceRole.sender,
      paired: true,
      sender: grants(battery: false, background: true),
      sharing: on,
    );
    final byId = {for (final t in tasks) t.id: t};
    expect(byId[SetupTaskId.battery]!.importance, SetupImportance.recommended);
    expect(byId[SetupTaskId.battery]!.state, SetupState.todo);
    expect(byId[SetupTaskId.backgroundActivity]!.importance, SetupImportance.required);
    expect(byId[SetupTaskId.backgroundActivity]!.state, SetupState.todo);
  });

  test('an autostart switch the app cannot read stays unknown until the person says it is on', () {
    List<SetupTask> tasks({required bool confirmed}) => setupTasks(
      role: DeviceRole.sender,
      paired: true,
      sender: grants(autostartScreen: true, vendor: 'xiaomi'),
      sharing: on,
      autostartConfirmed: confirmed,
    );
    expect(states(tasks(confirmed: false))[SetupTaskId.autostart], SetupState.unknown);
    expect(tasks(confirmed: false).allDone, isFalse);
    expect(states(tasks(confirmed: true))[SetupTaskId.autostart], SetupState.done);
  });

  test('required first, in a stable order; nothing guessed while permissions are still loading', () {
    final tasks = setupTasks(
      role: DeviceRole.sender,
      paired: false,
      sender: grants(post: false, battery: false),
      sharing: on,
    );
    final importance = tasks.map((t) => t.importance).toList();
    expect(importance, [...importance]..sort((a, b) => a.index.compareTo(b.index)));
    expect(setupTasks(role: DeviceRole.sender, paired: false).map((t) => t.id), [SetupTaskId.pairDevice]);
  });

  test('a device that shows notifications: alerts allowed (recommended) and a paired phone (required)', () {
    final denied = setupTasks(role: DeviceRole.receiver, paired: false, alertsAllowed: false);
    expect(states(denied), {SetupTaskId.pairDevice: SetupState.todo, SetupTaskId.alerts: SetupState.todo});
    expect(denied.first.id, SetupTaskId.pairDevice);
    expect(setupTasks(role: DeviceRole.receiver, paired: true, alertsAllowed: true).allDone, isTrue);
  });

  group('a device that shows notifications', () {
    final restricted = grants(battery: false, background: true, autostartScreen: true, vendor: 'oneplus').restrictions;

    test('Android (OnePlus): what lets a push reach it while closed is recommended, never required', () {
      final tasks = setupTasks(
        role: DeviceRole.receiver,
        paired: true,
        alertsAllowed: true,
        receiverRestrictions: restricted,
      );
      expect(states(tasks), {
        SetupTaskId.pairDevice: SetupState.done,
        SetupTaskId.alerts: SetupState.done,
        SetupTaskId.backgroundActivity: SetupState.todo,
        SetupTaskId.battery: SetupState.todo,
        SetupTaskId.autostart: SetupState.unknown,
      });
      expect(tasks.requiredOpen, isFalse, reason: 'it still receives while open');
    });

    test('elsewhere (nothing to restrict), or not yet paired: only alerts and pairing', () {
      expect(
        setupTasks(role: DeviceRole.receiver, paired: true, alertsAllowed: true).map((t) => t.id),
        unorderedEquals([SetupTaskId.pairDevice, SetupTaskId.alerts]),
      );
      expect(
        setupTasks(
          role: DeviceRole.receiver,
          paired: false,
          alertsAllowed: true,
          receiverRestrictions: restricted,
        ).map((t) => t.id),
        unorderedEquals([SetupTaskId.pairDevice, SetupTaskId.alerts]),
      );
    });
  });

  test('a phone that holds pop-ups back (OnePlus): asked for, once alerts are allowed at all', () {
    final held = setupTasks(role: DeviceRole.receiver, paired: true, alertsAllowed: true, popUpsWork: false);
    expect(states(held)[SetupTaskId.popUps], SetupState.todo);
    expect(held.firstWhere((t) => t.id == SetupTaskId.popUps).importance, SetupImportance.recommended);
    final fine = setupTasks(role: DeviceRole.receiver, paired: true, alertsAllowed: true, popUpsWork: true);
    expect(states(fine)[SetupTaskId.popUps], SetupState.done);
    final refused = setupTasks(role: DeviceRole.receiver, paired: true, alertsAllowed: false, popUpsWork: false);
    expect(states(refused), isNot(contains(SetupTaskId.popUps)), reason: 'allowing alerts comes first');
  });
}
