import 'package:air_reply/core/domain/device_role.dart';
import 'package:air_reply/core/platform/native_models.dart';

/// Something this device needs (or works better with) to share or show notifications reliably.
enum SetupTaskId {
  // a phone that shares
  notificationAccess,
  sharingOn,
  listener,
  statusNotification,
  backgroundActivity,
  battery,
  autostart,

  // a device that shows them
  alerts,

  // both
  pairDevice,
}

/// Required tasks stop the app from working; recommended ones keep it working in the background.
enum SetupImportance { required, recommended }

enum SetupState {
  done,
  todo,

  /// The phone cannot tell (an OEM autostart switch): the person says when it is done.
  unknown,
}

final class SetupTask {
  const SetupTask(this.id, this.importance, this.state);

  final SetupTaskId id;
  final SetupImportance importance;
  final SetupState state;

  bool get isDone => state == SetupState.done;

  @override
  bool operator ==(Object other) =>
      other is SetupTask && other.id == id && other.importance == importance && other.state == state;

  @override
  int get hashCode => Object.hash(id, importance, state);

  @override
  String toString() => '$id/$importance/$state';
}

/// What a phone has granted, as far as the app can read it.
typedef SenderGrants = ({bool notificationAccess, bool postNotifications, BackgroundRestrictions restrictions});

/// What this device should have set up, required tasks first, each with its state as far as the app can tell.
///
/// A phone ([DeviceRole.sender]) needs notification access and sharing on, a connected listener, and, to keep running
/// in the background, no background restriction, battery optimisation off and, on phones that have one, the maker's
/// autostart switch on (which no app can read: [autostartConfirmed] is the person's word for it). A device that shows
/// notifications needs to be allowed to alert and, on Android, the same background allowances
/// ([receiverRestrictions]) so pushes reach it while AirReply is closed. Both need a paired device. Null permissions (still loading, or not
/// readable on this platform) leave those tasks out rather than guess.
List<SetupTask> setupTasks({
  required DeviceRole role,
  required bool paired,
  SenderGrants? sender,
  SyncStatus? sharing,
  bool? alertsAllowed,
  BackgroundRestrictions? receiverRestrictions,
  bool autostartConfirmed = false,
}) {
  SetupState state(bool done) => done ? SetupState.done : SetupState.todo;
  const required = SetupImportance.required;
  const recommended = SetupImportance.recommended;
  final tasks = <SetupTask>[];
  switch (role) {
    case DeviceRole.sender:
      if (sender != null) {
        tasks.add(SetupTask(SetupTaskId.notificationAccess, required, state(sender.notificationAccess)));
        if (sharing != null) {
          tasks.add(SetupTask(SetupTaskId.sharingOn, required, state(sharing.enabled)));
          // only meaningful once the listener may run at all
          if (sender.notificationAccess && sharing.enabled) {
            tasks.add(SetupTask(SetupTaskId.listener, required, state(sharing.listenerConnected)));
          }
        }
        tasks.add(SetupTask(SetupTaskId.statusNotification, recommended, state(sender.postNotifications)));
        final restrictions = sender.restrictions;
        tasks.add(SetupTask(SetupTaskId.backgroundActivity, required, state(!restrictions.backgroundRestricted)));
        tasks.add(SetupTask(SetupTaskId.battery, recommended, state(restrictions.ignoringBatteryOptimizations)));
        if (restrictions.hasAutostartScreen) {
          tasks.add(
            SetupTask(SetupTaskId.autostart, recommended, autostartConfirmed ? SetupState.done : SetupState.unknown),
          );
        }
      }
    case DeviceRole.receiver:
      if (alertsAllowed != null) tasks.add(SetupTask(SetupTaskId.alerts, recommended, state(alertsAllowed)));
      // An Android device that shows notifications: what lets a push wake it once AirReply is closed (a restricted
      // or stopped app gets none on some phones).
      if (receiverRestrictions != null && paired) {
        tasks.add(
          SetupTask(SetupTaskId.backgroundActivity, recommended, state(!receiverRestrictions.backgroundRestricted)),
        );
        tasks.add(
          SetupTask(SetupTaskId.battery, recommended, state(receiverRestrictions.ignoringBatteryOptimizations)),
        );
        if (receiverRestrictions.hasAutostartScreen) {
          tasks.add(
            SetupTask(SetupTaskId.autostart, recommended, autostartConfirmed ? SetupState.done : SetupState.unknown),
          );
        }
      }
  }
  tasks.add(SetupTask(SetupTaskId.pairDevice, required, state(paired)));
  // required first, keeping each group's order
  return [...tasks.where((t) => t.importance == required), ...tasks.where((t) => t.importance == recommended)];
}

/// How far setup is: done out of all, and whether anything required is still open.
extension SetupProgress on List<SetupTask> {
  int get doneCount => where((t) => t.isDone).length;
  bool get requiredOpen => any((t) => t.importance == SetupImportance.required && !t.isDone);
  bool get allDone => every((t) => t.isDone);
}
