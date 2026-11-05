import 'package:air_reply/core/platform/native_models.dart';
import 'package:air_reply/features/notifications/data/mirrored_alerts.dart';
import 'package:air_reply/features/notifications/domain/alert_style.dart';

/// One Android alert channel the person's choices alert on, and what it should do.
typedef AlertChannelUse = ({String channelId, AlertMode mode, bool wantsPopUp, bool wantsSound});

/// The channels [style] alerts on, pop-up ones first; none for modes that neither pop up nor make a sound.
List<AlertChannelUse> alertChannelsFor(AlertStyle style) {
  final modes = {style.messages, style.others}.where((m) => m == AlertMode.popUp || m == AlertMode.normal).toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  return [
    for (final mode in modes)
      (
        channelId: MirroredAlerts.channelFor(mode, style),
        mode: mode,
        wantsPopUp: mode == AlertMode.popUp,
        wantsSound: style.soundFor(mode),
      ),
  ];
}

/// What one kind of alert does on this phone, as its system settings have it.
enum AlertExpectation {
  /// Over the screen, with a sound.
  popUp,

  /// Over the screen, without a sound.
  popUpSilent,

  /// In the notification list, with a sound.
  list,

  /// In the notification list, silently.
  quiet,

  /// No alert (the channel is switched off).
  off;

  static AlertExpectation of(AlertChannelState state) => switch (state) {
    (shown: false, popsUp: _, sounds: _) => off,
    (shown: true, popsUp: true, sounds: true) => popUp,
    (shown: true, popsUp: true, sounds: false) => popUpSilent,
    (shown: true, popsUp: false, sounds: true) => list,
    (shown: true, popsUp: false, sounds: false) => quiet,
  };
}

/// What the phone really does with the alerts the person chose. Phone makers (OnePlus, OPPO, realme, Xiaomi...)
/// let only a short list of apps (WhatsApp, Telegram...) pop up and ring out of the box; every other app's channels
/// are lowered to the list, silent, whatever the app asked for, and only the person can raise them again.
final class AlertDelivery {
  const AlertDelivery({
    required this.popsUp,
    required this.sounds,
    this.fixChannelId,
    this.vendor = '',
    this.messages,
    this.others,
  });

  /// What a message (a chat that can be answered) does; null when the system said nothing about its channel.
  final AlertExpectation? messages;

  /// What any other notification does.
  final AlertExpectation? others;

  /// Every channel meant to pop up does.
  final bool popsUp;

  /// Every channel meant to make a sound does.
  final bool sounds;

  /// The channel whose system settings fix the first problem; null when there is none.
  final String? fixChannelId;

  /// `Build.MANUFACTURER`, lower case, for the steps on that phone.
  final String vendor;

  bool get works => popsUp && sounds;

  /// OnePlus, OPPO and realme (ColorOS / OxygenOS) keep Banner, Ring and Vibrate on the app's notification page, off
  /// for apps not on their list, and a category offers Banner only once the app's is on: the fix starts there.
  /// Also when every kind is switched off: the app's own switch is there.
  bool get fixOnAppPage =>
      const {'oneplus', 'oppo', 'realme'}.contains(vendor) ||
      (messages == AlertExpectation.off && others == AlertExpectation.off);

  @override
  bool operator ==(Object other) =>
      other is AlertDelivery &&
      other.popsUp == popsUp &&
      other.sounds == sounds &&
      other.fixChannelId == fixChannelId &&
      other.vendor == vendor &&
      other.messages == messages &&
      other.others == others;

  @override
  int get hashCode => Object.hash(popsUp, sounds, fixChannelId, vendor, messages, others);

  @override
  String toString() => 'AlertDelivery(popsUp: $popsUp, sounds: $sounds, fix: $fixChannelId)';
}

/// Judges [states] (by channel id, as the system has them) against what [style] asks of each channel. Null when
/// nothing could be judged: no channel pops up or sounds, or the system said nothing about any of them.
AlertDelivery? judgeAlertDelivery(AlertStyle style, Map<String, AlertChannelState> states, {String vendor = ''}) {
  var judged = false;
  var popsUp = true;
  var sounds = true;
  String? fix;
  for (final use in alertChannelsFor(style)) {
    final state = states[use.channelId];
    if (state == null) continue;
    judged = true;
    final noPopUp = use.wantsPopUp && !state.popsUp;
    final noSound = use.wantsSound && !state.sounds;
    if (noPopUp) popsUp = false;
    if (noSound) sounds = false;
    if ((noPopUp || noSound) && fix == null) fix = use.channelId;
  }
  if (!judged) return null;
  AlertExpectation? expect(AlertMode mode) => switch (states[MirroredAlerts.channelFor(mode, style)]) {
    final state? => AlertExpectation.of(state),
    null => null,
  };
  return AlertDelivery(
    popsUp: popsUp,
    sounds: sounds,
    fixChannelId: fix,
    vendor: vendor,
    messages: expect(style.messages),
    others: expect(style.others),
  );
}
