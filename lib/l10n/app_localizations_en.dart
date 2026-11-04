// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => 'Home';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count unread',
      one: 'Notifications, 1 unread',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get tabDevices => 'Devices';

  @override
  String get tabSettings => 'Settings';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count unread', zero: 'All read');
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => 'Your phone,';

  @override
  String get welcomeHeadlineSecond => 'Everywhere.';

  @override
  String get welcomeIntro =>
      'Read your phone\'s notifications on your iPhone, iPad, Mac, PC or browser, and reply to messages from there.';

  @override
  String get welcomeEyebrow => 'Get started';

  @override
  String get welcomeQuestion => 'How will you use this device?';

  @override
  String get roleShareTitle => 'Share my notifications';

  @override
  String get roleShareDescription =>
      'This phone sends its notifications to your other devices, and sends the replies you write there.';

  @override
  String get roleShareUnavailable => 'Only Android lets apps read notifications. Use an Android phone to share.';

  @override
  String get roleReceiveTitle => 'View and reply here';

  @override
  String get roleReceiveDescription =>
      'See your phone\'s notifications on this device and answer messages without picking it up.';

  @override
  String get errorOffline => 'You appear to be offline. Check your connection and try again.';

  @override
  String get errorServerUnreachable => 'Could not reach AirReply servers. Check your connection.';

  @override
  String get errorSignInRefused => 'Sign-in was refused. Is Anonymous sign-in enabled in the Firebase project?';

  @override
  String get errorSignInFailed => 'Sign-in failed.';

  @override
  String get errorSyncFailed => 'Sync with your paired device failed.';

  @override
  String get errorPairingCodeNotCreated => 'Could not create a pairing code. Please try again.';

  @override
  String get errorSessionNotConfirmable => 'This session cannot be confirmed.';

  @override
  String get errorCodeUnavailable => 'This code is no longer available. Make a new one on the other phone.';

  @override
  String get errorCannotPairWithItself => 'A device cannot pair with itself.';

  @override
  String get errorCodeAlreadyUsed => 'This code was already used.';

  @override
  String get errorNoDeviceJoined => 'No device has joined yet.';

  @override
  String get errorCodeFormat => 'Enter the 6-digit code shown on the phone.';

  @override
  String get errorNotAPairingCode => 'That is not an AirReply pairing code.';

  @override
  String get errorCodeNotFound => 'No pairing code like that. Check the code on the other phone.';

  @override
  String get errorCodeExpired => 'This code has expired. Make a new one.';

  @override
  String get errorQrMismatch => 'The QR code does not match this session. Pairing stopped for your safety.';

  @override
  String get errorNotConfirmedYet => 'The other phone has not confirmed yet.';

  @override
  String get errorPairingCancelledOnPhone => 'Pairing was cancelled on the other phone.';

  @override
  String get errorPairingCancelled => 'The pairing was cancelled. Make a new code to try again.';

  @override
  String get errorPairingNotAvailable => 'This pairing session is not available to this device.';

  @override
  String get errorPairingServerFailed => 'The server could not complete pairing.';

  @override
  String get errorPairingOffInDemo => 'Pairing is turned off in demo mode.';

  @override
  String get errorNotPaired => 'This device is not paired yet.';

  @override
  String get errorInvalidPeerKey => 'The other device sent an invalid key.';

  @override
  String get errorUnsafePeerKey => 'The other device sent an unsafe key.';

  @override
  String get errorEncryptFailed => 'Could not encrypt the notification.';

  @override
  String get errorDecryptFailed => 'Could not decrypt the notification.';

  @override
  String get errorPayloadUnknown => 'This notification is in an unknown format.';

  @override
  String get errorPayloadForeign => 'This notification was not made with this pair\'s key, or it was altered.';

  @override
  String get errorNativeServiceFailed => 'The Android notification service failed.';

  @override
  String get errorNativeServiceUnavailable => 'The Android notification service is not available.';

  @override
  String get errorReplyEmpty => 'Type a reply first.';

  @override
  String get errorReplyTooLong => 'That reply is too long.';

  @override
  String get errorReplyNotPossible => 'This notification cannot be answered.';

  @override
  String get errorReplyDismissed => 'This notification was dismissed on your phone, so it can no longer be answered.';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Could not reach $count of $total paired devices.',
      one: 'Could not reach 1 of $total paired devices.',
    );
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message ($detail)';
  }

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorSharingAndroidOnly => 'Sharing notifications is only available on Android.';

  @override
  String get timeNow => 'now';

  @override
  String timeMinutesShort(int n) {
    return '${n}m';
  }

  @override
  String timeHoursShort(int n) {
    return '${n}h';
  }

  @override
  String get timeToday => 'Today';

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeAt(String day, String time) {
    return '$day at $time';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n min ago', one: '1 min ago');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n h ago', one: '1 h ago');
    return '$_temp0';
  }

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get searchHint => 'Search';

  @override
  String get searchClear => 'Clear search';

  @override
  String get splashFailed => 'AirReply could not start';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get splashStarting => 'AirReply is starting';

  @override
  String get firebaseSetupEyebrow => 'Setup required';

  @override
  String get firebaseSetupTitle => 'Connect Firebase';

  @override
  String get firebaseSetupBody =>
      'AirReply syncs your devices through your own Firebase project. Run this in the project folder, then rebuild the app.';

  @override
  String get actionCopyCommand => 'Copy command';

  @override
  String get firebaseSetupDetails => 'Details';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceOffline => 'Offline';

  @override
  String get deviceConnecting => 'Connecting';

  @override
  String get deviceNeedsAccess => 'Needs access';

  @override
  String get devicePaused => 'Paused';

  @override
  String get deviceNotReceiving => 'Not receiving';

  @override
  String get deviceReceivingDetail => 'New notifications arrive as they happen.';

  @override
  String get deviceSharingDetail => 'New notifications are shared as they arrive.';

  @override
  String get deviceOfflineDetail => 'Showing saved notifications until this device is back online.';

  @override
  String get deviceConnectingDetail => 'Reaching the server…';

  @override
  String get deviceNeedsAccessDetail => 'Notification access is off, so nothing can be shared.';

  @override
  String get devicePausedDetail => 'Sharing is off. Turn it on to send notifications.';

  @override
  String get deviceNotReceivingDetail => 'Android stopped AirReply\'s notification listener.';

  @override
  String get settingsAccessEyebrow => 'Access';

  @override
  String get settingsPermissionsTitle => 'Permissions';

  @override
  String get settingsFilterEyebrow => 'Filter';

  @override
  String get settingsAppsTitle => 'Apps';

  @override
  String get settingsPrivacyEyebrow => 'Privacy';

  @override
  String get settingsPrivacyTitle => 'Mirroring and privacy';

  @override
  String get settingsConnectionEyebrow => 'Connection';

  @override
  String get settingsSyncTitle => 'Sync';

  @override
  String get settingsAppearanceEyebrow => 'Appearance';

  @override
  String get settingsAppearanceTitle => 'Appearance and accessibility';

  @override
  String get settingsDataEyebrow => 'Data';

  @override
  String get settingsDataTitle => 'Your data';

  @override
  String get settingsHelpEyebrow => 'Help';

  @override
  String get settingsHelpTitle => 'Help and about';

  @override
  String get permissionOn => 'On';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionAllow => 'Allow';

  @override
  String get permissionAccessTitle => 'Notification access';

  @override
  String get permissionAccessSubtitle => 'Required to read and share notifications';

  @override
  String get permissionStatusTitle => 'Status notification';

  @override
  String get permissionStatusSubtitle => 'Shows \"Notification Sync Active\" with a Pause button';

  @override
  String get permissionBatteryTitle => 'Battery optimisation';

  @override
  String get permissionBatteryOk => 'Unrestricted: Android will not pause sharing';

  @override
  String get permissionBatteryFix => 'Set to \"Unrestricted\" so Android never pauses sharing';

  @override
  String get permissionAlertsTitle => 'Alerts';

  @override
  String get permissionAlertsBrowser => 'Lets this browser show new notifications';

  @override
  String get permissionAlertsDevice => 'Lets this device alert you to new notifications';

  @override
  String get loading => 'Loading…';

  @override
  String get appsAllShared => 'Every app is shared';

  @override
  String get appsNoneShared => 'No apps selected: nothing is shared';

  @override
  String get appsToShareTitle => 'Apps to share';

  @override
  String get appsMutedTitle => 'Muted apps';

  @override
  String get encryptionTitle => 'End-to-end encrypted';

  @override
  String get encryptionDetail =>
      'Each pair has its own key, agreed between the two devices (X25519). Notifications and replies are sealed with AES-256-GCM. History stays on your devices: the server only relays ciphertext and deletes each message once it is delivered.';

  @override
  String get shareNotificationsTitle => 'Share notifications';

  @override
  String get shareNeedsAccess => 'Turn on notification access first';

  @override
  String get alertTextTitle => 'Show message text in alerts';

  @override
  String get alertTextSubtitle => 'Off: alerts only name the app, for lock screens and shared displays';

  @override
  String get alertsBrowserTitle => 'Alerts in this browser';

  @override
  String get alertsComputerTitle => 'Alerts on this computer';

  @override
  String get alertsWhileOpen =>
      'New notifications alert you while AirReply is running. Keep it open (on Mac it keeps running when you close the window).';

  @override
  String get syncNoDevices => 'No paired devices';

  @override
  String get syncStatusTitle => 'Sync status';

  @override
  String get syncChecking => 'Checking the connection…';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get listenerTitle => 'Notification listener';

  @override
  String get listenerSubtitle => 'Ask Android to connect AirReply\'s listener again if devices stop receiving';

  @override
  String get actionReconnect => 'Reconnect';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSubtitle => 'System follows this device';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get hapticsTitle => 'Haptic feedback';

  @override
  String get hapticsSubtitle => 'A light tap when you send, toggle or confirm';

  @override
  String get textSizeTitle => 'Text size';

  @override
  String get textSizeSubtitle => 'AirReply follows the text size and bold text set on this device';

  @override
  String get removeAllConfirmTitle => 'Remove all devices?';

  @override
  String get actionRemoveAll => 'Remove all';

  @override
  String get markAllReadTitle => 'Mark all as read';

  @override
  String get markedAllRead => 'All marked as read';

  @override
  String get restoreHiddenTitle => 'Restore hidden notifications';

  @override
  String get hiddenRestored => 'Hidden notifications restored';

  @override
  String get removeAllTitle => 'Remove all devices';

  @override
  String get removeAllSubtitle => 'Ends every pair; their history stays under Previous devices';

  @override
  String get troubleshootingTitle => 'Troubleshooting';

  @override
  String get troubleshootingSubtitle => 'What to check when notifications or replies do not arrive';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get diagnosticsSubtitle => 'Connection, permission and sync details to check or share';

  @override
  String get licencesTitle => 'Open-source licences';

  @override
  String get appTagline => 'Your phone\'s notifications, on every screen.';

  @override
  String get syncSharing => 'Sharing';

  @override
  String get syncStarting => 'Starting';

  @override
  String get permissionAutostartTitle => 'Autostart';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return 'Required on $vendor phones. Android cannot report it, so check it there.';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count selected apps',
      one: 'Only 1 selected app',
    );
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count muted: they arrive silently',
      zero: 'Every app can alert you',
    );
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state. Live now.';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state. Last synced $ago.';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state. $detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return 'Syncing with $name stops. Its history stays on this device under Previous devices, and comes back if you pair it again.';
  }

  @override
  String removeAllConfirmMany(int count) {
    return 'Syncing with all $count devices stops. Their history stays on this device under Previous devices, and comes back if you pair them again.';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count unread', zero: 'Nothing unread');
    return '$_temp0';
  }

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden on this device',
      zero: 'Nothing hidden',
    );
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => 'Notification access is off';

  @override
  String get noticeAccessOffMessage => 'AirReply cannot see new notifications until you turn it back on.';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get noticePausedTitle => 'Sharing is paused';

  @override
  String get noticePausedMessage => 'Notifications on this phone are not being sent to your devices.';

  @override
  String get actionResumeSharing => 'Resume sharing';

  @override
  String get noticeNotReceivingTitle => 'Not receiving notifications';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android stopped AirReply\'s listener. Reconnect, and turn on Autostart for AirReply on $vendor phones so it does not happen again.';
  }

  @override
  String get noticeNotReceivingMessage =>
      'Android stopped AirReply\'s notification listener. Reconnect to start again.';

  @override
  String get noticeBatteryTitle => 'Battery optimisation is on';

  @override
  String get noticeBatteryMessage => 'Android may pause sharing to save battery. Set AirReply to \"Unrestricted\".';

  @override
  String get actionBatterySettings => 'Battery settings';

  @override
  String get noticeAlertsOffTitle => 'Alerts are off on this device';

  @override
  String get noticeAlertsOffMessage => 'New notifications still appear here, but this device will not alert you.';

  @override
  String get actionAllowAlerts => 'Allow alerts';

  @override
  String noticeOneOffline(String name) {
    return '$name is offline';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count devices are offline';
  }

  @override
  String get noticeOfflineMessage => 'Showing saved notifications. New ones arrive once this device is back online.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get setupTitle => 'Set up';

  @override
  String get disclosureEyebrow => 'Before you start';

  @override
  String get disclosureTitle => 'AirReply needs access to your notifications';

  @override
  String get disclosureIntro =>
      'To share this phone\'s notifications with your paired devices, AirReply uses Android\'s Notification Access permission.';

  @override
  String get disclosureWhatTitle => 'What is accessed';

  @override
  String get disclosureWhatBody =>
      'The notifications shown on this phone: app name, title, text, time, and the reply action of messaging apps. This works in the background, even when AirReply is closed.';

  @override
  String get disclosureWhyTitle => 'Why';

  @override
  String get disclosureWhyBody =>
      'Only to show those notifications on the devices you pair, and to send the replies you type there through the original app on this phone.';

  @override
  String get disclosureHowTitle => 'How it is protected';

  @override
  String get disclosureHowBody =>
      'Each notification is encrypted on this phone with AES-256-GCM, using a key that only this phone and the paired device hold. Our servers relay ciphertext they cannot read, and delete it once delivered: history is kept only on your devices.';

  @override
  String get disclosureControlTitle => 'You stay in control';

  @override
  String get disclosureControlBody =>
      'Choose which apps are shared, pause from the status notification at any time, or remove a device to stop sharing; delete its history whenever you like. Notification content is never sold, shared with third parties, or used for ads or analytics.';

  @override
  String get actionAgreeAndContinue => 'Agree and continue';

  @override
  String get actionNoThanks => 'No thanks';

  @override
  String setupProgress(int done, int total) {
    return '$done of $total required steps done';
  }

  @override
  String get setupPhoneTitle => 'Set up this phone';

  @override
  String get setupPhoneSubtitle =>
      'Two permissions let AirReply share notifications and keep running in the background.';

  @override
  String get setupAccessSubtitle => 'Required. Find AirReply in the list and switch it on.';

  @override
  String get setupStatusSubtitle => 'Shows \"Notification Sync Active\" with a Pause button while sharing is on.';

  @override
  String setupAutostartSubtitle(String vendor) {
    return 'Required on $vendor. Without it the phone stops AirReply from listening once the app is closed. Find AirReply and switch Autostart on.';
  }

  @override
  String get setupBatterySubtitle => 'Recommended. Set AirReply to \"Unrestricted\" so Android never pauses sharing.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get setupNeedsAccess => 'Turn on notification access to continue';

  @override
  String get stepDone => 'Done';

  @override
  String get pairADevice => 'Pair a device';

  @override
  String get pairTitle => 'Pair';

  @override
  String get pairAddADevice => 'Add a device';

  @override
  String pairPairedWith(String name) {
    return 'Paired with $name';
  }

  @override
  String pairStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get pairStopped => 'Pairing stopped';

  @override
  String get actionMakeNewCode => 'Make a new code';

  @override
  String get pairShowCodeIntro =>
      'On your iPhone, iPad, Mac, PC, browser or other Android, open AirReply, choose \"View and reply here\", then scan this code or type the digits.';

  @override
  String get pairQrLabel => 'Pairing QR code';

  @override
  String get pairOrTypeCode => 'OR TYPE THIS CODE';

  @override
  String pairCodeCopied(String code) {
    return 'Code $code copied';
  }

  @override
  String get actionCopyCode => 'Copy code';

  @override
  String get actionNewCode => 'New code';

  @override
  String get pairCodesMatchQuestion => 'Do the codes match?';

  @override
  String pairVerifyWarning(String name) {
    return '$name wants to pair. It must show exactly this code. If it does not, someone else may be trying to connect.';
  }

  @override
  String get actionCodesMatch => 'Codes match, pair';

  @override
  String get actionCodesDoNotMatch => 'They do not match';

  @override
  String get pairAddAnotherPhone => 'Add another phone';

  @override
  String get pairWithYourPhone => 'Pair with your phone';

  @override
  String get pairEnterCodeIntro =>
      'On the Android phone you want to see here, open AirReply and choose \"Share my notifications\" (or \"Add a device\" if it already shares). It shows a QR code and six digits.';

  @override
  String get pairMethodScan => 'Scan';

  @override
  String get pairMethodType => 'Type code';

  @override
  String get pairCodeLabel => 'PAIRING CODE';

  @override
  String get pairStartsOnLastDigit => 'Pairing starts as soon as you type the last digit.';

  @override
  String get pairConnecting => 'Connecting…';

  @override
  String get pairPointCamera => 'Point the camera at the QR code on your phone.';

  @override
  String get cameraDenied =>
      'AirReply needs the camera to scan. Allow it in your phone\'s settings, or type the code instead.';

  @override
  String get cameraNotStarted => 'The camera did not start.';

  @override
  String pairConfirmOn(String name) {
    return 'Confirm on $name';
  }

  @override
  String get pairConfirmHint => 'Check that your phone shows the same code, then tap \"Codes match\" there.';

  @override
  String get pairWaitingForPhone => 'Waiting for your phone…';

  @override
  String get pairCodeExpired => 'Code expired, making a new one';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return 'Expires in $minutes:$seconds';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return 'Step $current of $total: $name';
  }

  @override
  String get pairCouldNotPair => 'Could not pair';

  @override
  String get stepShowCode => 'Show code';

  @override
  String get stepVerify => 'Verify';

  @override
  String get stepEnterCode => 'Enter code';

  @override
  String get notYet => 'Not yet';

  @override
  String get factStatus => 'Status';

  @override
  String get factLive => 'Live';

  @override
  String get factLastSynced => 'Last synced';

  @override
  String get factNow => 'Now';

  @override
  String get lastShared => 'Last shared';

  @override
  String get lastNotification => 'Last notification';

  @override
  String get factPaired => 'Paired';

  @override
  String get factEncryption => 'Encryption';

  @override
  String get factEncryptionValue => 'End-to-end, AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String removeDeviceMessage(String name) {
    return 'Syncing with $name stops on both devices. Its history stays on this device under Settings → Previous devices until you delete it. Other devices are not affected.';
  }

  @override
  String get actionRemove => 'Remove';

  @override
  String deviceRemoved(String name) {
    return '$name removed';
  }

  @override
  String get actionTurnOnAccess => 'Turn on notification access';

  @override
  String get browseShared => 'Browse what you shared';

  @override
  String get browseHistory => 'Browse notification history';

  @override
  String get actionRemoveDevice => 'Remove device';

  @override
  String get addAPhone => 'Add a phone';

  @override
  String factWithTime(String label, String time) {
    return '$label $time';
  }

  @override
  String pairedAgo(String time) {
    return 'Paired $time';
  }

  @override
  String devicesPaired(int count) {
    return '$count paired';
  }

  @override
  String get devicesIntroSender => 'This phone shares its notifications with these devices.';

  @override
  String get devicesIntroReceiver => 'This device shows notifications from these phones.';

  @override
  String get devicesNone => 'No devices';

  @override
  String get devicesNoneHint => 'Pair a device to start.';

  @override
  String get helpNotArrivingQ => 'Notifications are not arriving';

  @override
  String get helpNotArrivingA =>
      'On the phone, open AirReply and check that \"Share notifications\" is on and the app is allowed to run in the background. Both devices need an internet connection. Then retry here.';

  @override
  String get actionRetrySync => 'Retry sync';

  @override
  String get helpNoAlertsQ => 'No alerts on this device';

  @override
  String get helpNoAlertsA =>
      'New notifications always reach the Notifications tab. To be alerted too, allow notifications for AirReply, and check that the app is not muted in Settings → Muted apps.';

  @override
  String get helpExpiredQ => 'A reply says \"Expired on phone\"';

  @override
  String get helpExpiredA =>
      'Replies are sent through the notification on the phone. Once it is cleared there, or the app replaced it, it can no longer be answered. Reply to a newer notification, or from the phone.';

  @override
  String get helpNotReceivingQ => 'Devices are not receiving notifications';

  @override
  String get helpNotReceivingA =>
      'Check that notification access is on and sharing is not paused. If Android stopped AirReply\'s listener, reconnect it.';

  @override
  String get actionReconnectListener => 'Reconnect listener';

  @override
  String get helpStopsQ => 'Sharing stops after a while';

  @override
  String helpStopsAutostartA(String vendor) {
    return 'On $vendor phones, turn on Autostart for AirReply and set its battery use to \"Unrestricted\", or the phone stops it in the background.';
  }

  @override
  String get helpStopsA =>
      'Set AirReply\'s battery use to \"Unrestricted\" so Android does not pause it in the background.';

  @override
  String get helpRepliesQ => 'Replies are not delivered';

  @override
  String get helpRepliesA =>
      'A reply is sent through the notification it answers, so that notification must still be in this phone\'s status bar. Messaging apps that offer \"Reply\" in their notifications work best.';

  @override
  String get historyTitle => 'History';

  @override
  String get historySharedWithIt => 'Shared with it';

  @override
  String get emptyNothingYet => 'Nothing here yet';

  @override
  String historyEmptySender(String name) {
    return 'Notifications this phone shares with $name appear here.';
  }

  @override
  String historyEmptyReceiver(String name) {
    return 'Notifications from $name appear here.';
  }

  @override
  String get thisPhone => 'this phone';

  @override
  String get itDevice => 'it';

  @override
  String get homeHeadlineSender => 'Shared.';

  @override
  String get homeIntroSender => 'Notifications from this phone reach your other devices, and their replies come back.';

  @override
  String get homeIntroReceiver => 'Your phone’s notifications arrive here. Read them, and reply without picking it up.';

  @override
  String get searchNotificationsHint => 'Search notifications';

  @override
  String get homeTodayEyebrow => 'Today';

  @override
  String get homeGlanceTitle => 'At a glance';

  @override
  String get homeRecentEyebrow => 'Recent activity';

  @override
  String get homeLatestTitle => 'Latest notifications';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get homeRecentEmptySender => 'Nothing shared yet. New notifications on this phone will appear here.';

  @override
  String get homeRecentEmptyReceiver => 'Nothing yet. New notifications from your phone will appear here.';

  @override
  String get homeRecentFailed => 'Recent notifications could not be loaded.';

  @override
  String get homeSharingEyebrow => 'Sharing';

  @override
  String get homeThisPhoneTitle => 'This phone';

  @override
  String get howItWorksEyebrow => 'How it works';

  @override
  String get howItWorksSenderTitle => 'Share once. Reply anywhere.';

  @override
  String get howItWorksReceiverTitle => 'Three steps. Every screen.';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count unread',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get statToday => 'Today';

  @override
  String get statUnread => 'Unread';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Devices', one: 'Device');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'No matches';

  @override
  String searchNoMatchesDetail(String query) {
    return 'No notification or device mentions “$query”.';
  }

  @override
  String get searchEyebrow => 'Search';

  @override
  String get stepShareTitle => 'Share from your phone';

  @override
  String get stepShareText => 'On your Android phone, AirReply sends each notification here, end-to-end encrypted.';

  @override
  String get stepReadTitle => 'Read it here';

  @override
  String get stepReadText => 'Notifications arrive within seconds, grouped by app and by person.';

  @override
  String get stepReplyTitle => 'Reply from anywhere';

  @override
  String get stepReplyText => 'Write an answer here; your phone sends it through the app it came from.';

  @override
  String get stepPickTitle => 'Pick what to share';

  @override
  String get stepPickText => 'Choose every app, or only the ones you want on your other devices.';

  @override
  String get stepPairTitle => 'Pair your devices';

  @override
  String get stepPairText => 'A Mac, PC, iPhone, iPad or browser scans a code once, and they stay paired.';

  @override
  String get stepReplySenderText => 'Replies written there are sent from this phone, through the app they belong to.';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected apps',
      one: '1 selected app',
    );
    return '$_temp0';
  }

  @override
  String get actionChooseApps => 'Choose apps →';

  @override
  String get pairDeviceKinds => 'iPhone, iPad, Mac, PC, browser or Android';

  @override
  String get actionPairArrow => 'Pair →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count phones', one: '1 phone');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count devices', one: '1 device');
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return 'Receiving from $names.';
  }

  @override
  String statusConnectingTo(String names) {
    return 'Connecting to $names…';
  }

  @override
  String statusShowingSaved(String names) {
    return 'Showing saved notifications from $names.';
  }

  @override
  String get statusLive => 'Live. New notifications appear within seconds.';

  @override
  String statusLastSynced(String ago) {
    return 'Last synced $ago.';
  }

  @override
  String get statusNeedsAccess => 'Sharing needs notification access.';

  @override
  String get statusPaused => 'Sharing is paused.';

  @override
  String statusSharingWith(String names) {
    return 'Sharing with $names.';
  }

  @override
  String get statusNotWorking => 'Sharing is not working right now.';

  @override
  String get statusEncryptedDetail => 'Notifications are end-to-end encrypted on this phone before they leave it.';

  @override
  String get statusOffDetail => 'Nothing from this phone reaches your devices until sharing is on.';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get periodAnyTime => 'Any time';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'Last 7 days';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return '$_temp0';
  }

  @override
  String conversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversations',
      one: '1 conversation',
    );
    return '$_temp0';
  }

  @override
  String messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count messages', one: '1 message');
    return '$_temp0';
  }

  @override
  String newNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new notifications',
      one: '1 new notification',
    );
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label, $count unread';
  }

  @override
  String get nothingHereNow => 'Nothing here now';

  @override
  String get goneDetail => 'These notifications were hidden, removed, or came from a device that is no longer paired.';

  @override
  String get actionBackToNotifications => 'Back to notifications';

  @override
  String get searchConversationsHint => 'Search names, numbers and messages';

  @override
  String get conversationsEyebrow => 'Conversations';

  @override
  String conversationsEyebrowCount(int count) {
    return 'Conversations · $count';
  }

  @override
  String get peopleAndGroups => 'People and groups';

  @override
  String otherNotificationsCount(int count) {
    return 'Other notifications · $count';
  }

  @override
  String fromApp(String app) {
    return 'From $app';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String get notAvailable => 'Not available';

  @override
  String get notificationGoneDetail =>
      'This notification was removed, hidden, or belongs to a device that is no longer paired.';

  @override
  String get markAsUnread => 'Mark as unread';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get copyText => 'Copy text';

  @override
  String get hideFromDevice => 'Hide from this device';

  @override
  String get actionHide => 'Hide';

  @override
  String hideCount(int count) {
    return 'Hide $count notifications';
  }

  @override
  String get you => 'You';

  @override
  String youSaid(String text) {
    return 'You: $text';
  }

  @override
  String get sentFromPhone => 'Sent from your phone';

  @override
  String get clearedOnPhone => 'Cleared on phone';

  @override
  String get canReply => 'Can reply';

  @override
  String get canBeAnswered => 'Can be answered';

  @override
  String get noRepliesInApp => 'No replies in this app';

  @override
  String get replySending => 'Sending';

  @override
  String get replyDelivered => 'Delivered';

  @override
  String get replySent => 'Sent';

  @override
  String get replyExpired => 'Expired on phone';

  @override
  String get replyNotDelivered => 'Not delivered';

  @override
  String get replySendingPrefixed => 'Reply sending';

  @override
  String get replyDeliveredPrefixed => 'Reply delivered';

  @override
  String get replySentPrefixed => 'Reply sent';

  @override
  String get replyExpiredPrefixed => 'Reply expired on phone';

  @override
  String get replyNotDeliveredPrefixed => 'Reply not delivered';

  @override
  String get yourReply => 'Your reply';

  @override
  String yourReplyAsShown(String app) {
    return 'Your reply, as $app shows it';
  }

  @override
  String get allMarkedRead => 'All marked as read';

  @override
  String sharedWith(String name) {
    return 'Shared with $name';
  }

  @override
  String sharedWithDevices(int count) {
    return 'Shared with $count devices';
  }

  @override
  String fromDevice(String name) {
    return 'From $name';
  }

  @override
  String fromPhones(int count) {
    return 'From $count phones';
  }

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Filters, $count on', zero: 'Filters');
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => 'Nothing matches this search or filter.';

  @override
  String get actionClearSearchAndFilters => 'Clear search and filters';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get inboxEmptySender =>
      'Notifications this phone shares appear here, with the replies sent from your devices.';

  @override
  String get inboxEmptyReceiver => 'Notifications from your phone appear here the moment they arrive.';

  @override
  String get inboxAllHidden => 'Every notification is hidden. Restore them from Settings.';

  @override
  String get notificationsLoadFailed => 'Could not load notifications';

  @override
  String get removeFilter => 'Remove filter';

  @override
  String get filterUnread => 'Unread';

  @override
  String get device => 'Device';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared =>
      'These notifications were cleared on your phone, so they can no longer be answered from here.';

  @override
  String footnoteNoReplies(String app) {
    return '$app does not accept replies for this conversation.';
  }

  @override
  String get unknownSender => 'Unknown sender';

  @override
  String get dividerNew => 'New';

  @override
  String notificationHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications hidden',
      one: 'Notification hidden',
    );
    return '$_temp0';
  }

  @override
  String get copied => 'Copied';

  @override
  String get dismissedOnPhone => 'Dismissed on phone';

  @override
  String get moreActions => 'More actions';

  @override
  String get hideConversations => 'Hide conversations';

  @override
  String get showConversations => 'Show conversations';

  @override
  String unmuteApp(String app) {
    return 'Unmute alerts from $app';
  }

  @override
  String muteApp(String app) {
    return 'Mute alerts from $app';
  }

  @override
  String get threadChat => 'Chat';

  @override
  String get threadGroup => 'Group';

  @override
  String get threadNotification => 'Notification';

  @override
  String get replyHint => 'Reply';

  @override
  String replyToHint(String name) {
    return 'Reply to $name';
  }

  @override
  String get sendWithEnter => 'Send (Enter)';

  @override
  String get actionSend => 'Send';

  @override
  String get filterTitle => 'Filter';

  @override
  String get actionClearAll => 'Clear all';

  @override
  String get filterShow => 'Show';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnreadOnly => 'Unread only';

  @override
  String get filterWhen => 'When';

  @override
  String get filterSharedWith => 'Shared with';

  @override
  String get filterPhone => 'Phone';

  @override
  String get filterApp => 'App';

  @override
  String get filterAllApps => 'All apps';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count notifications',
      one: 'Show 1 notification',
    );
    return '$_temp0';
  }

  @override
  String get actionShowMore => 'Show more';

  @override
  String get browseSharedWithIt => 'Browse what you shared with it';

  @override
  String get browseItsHistory => 'Browse its notification history';

  @override
  String get swipeUnread => 'Unread';

  @override
  String get swipeRead => 'Read';

  @override
  String get diagnosticsIntro => 'Nothing here includes notification text or encryption keys.';

  @override
  String get reportCopied => 'Report copied';

  @override
  String get actionCopyReport => 'Copy report';

  @override
  String get checkingAgain => 'Checking again…';

  @override
  String get actionCheckAgain => 'Check again';

  @override
  String get diagnosticsReportNote => 'The report itself stays in English, so whoever helps you can read it.';

  @override
  String get welcomeEncryption =>
      'End-to-end encrypted with a key only your devices hold. The server relays ciphertext it cannot read.';

  @override
  String get theOtherDevice => 'The other device';

  @override
  String get appsShareIntro => 'Choose what reaches your devices. This applies even while AirReply is closed.';

  @override
  String get appsOnlySelected => 'Only selected';

  @override
  String get searchApps => 'Search apps';

  @override
  String get appsNothingSelected => 'Nothing selected: no notifications are shared';

  @override
  String appsSelected(int count) {
    return '$count selected';
  }

  @override
  String get appsOnlySelectedHint => 'Choose \"Only selected\" to pick which apps reach your devices.';

  @override
  String get appsChoiceLoadFailed => 'Could not load your choice';

  @override
  String get appsMutedIntro => 'Muted apps still arrive in Notifications, but never alert you on this device.';

  @override
  String get appsNoneYet => 'No apps yet';

  @override
  String get appsNoneYetHint => 'Apps appear here once your phone has sent a notification from them.';

  @override
  String get appMuted => 'Muted';

  @override
  String get appAlertsOn => 'Alerts on';

  @override
  String get appsNoMatch => 'No apps match';

  @override
  String get appsListFailed => 'Could not list apps';

  @override
  String get appsReading => 'Reading installed apps…';

  @override
  String get alertChannelName => 'Mirrored notifications';

  @override
  String get alertChannelDescription => 'Notifications mirrored from your paired phone';

  @override
  String get alertReply => 'Reply';

  @override
  String get alertReplyHint => 'Reply…';

  @override
  String get alertOpenApp => 'Open AirReply';

  @override
  String get alertNewNotification => 'New notification';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Same as this device';

  @override
  String languageSystemCurrent(String language) {
    return 'Same as this device ($language)';
  }

  @override
  String get previousDevicesTitle => 'Previous devices';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed devices, history kept',
      one: '1 removed device, history kept',
      zero: 'History of removed devices stays here',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro =>
      'When you remove a device, its history stays on this device. Pair the same device again to continue where you left off, or delete the history here.';

  @override
  String get previousDevicesNone => 'No previous devices';

  @override
  String get previousDevicesNoneHint => 'The history of devices you remove appears here.';

  @override
  String previousDeviceSummary(String date, String count) {
    return 'Removed $date · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return 'Removed $date';
  }

  @override
  String previousDeviceContinue(String name) {
    return 'Pair $name again to continue this history in your inbox.';
  }

  @override
  String get actionDeleteHistory => 'Delete history';

  @override
  String deleteHistoryTitle(String name) {
    return 'Delete the history of $name?';
  }

  @override
  String get deleteHistoryMessage =>
      'Its notifications and replies are deleted from this device. This cannot be undone.';

  @override
  String historyDeleted(String name) {
    return 'History of $name deleted';
  }

  @override
  String get actionDeleteAll => 'Delete all';

  @override
  String get deleteAllHistoryTitle => 'Delete all previous history?';

  @override
  String get deleteAllHistoryMessage =>
      'The history of every removed device is deleted from this device. This cannot be undone.';

  @override
  String get allHistoryDeleted => 'Previous history deleted';

  @override
  String get feedbackReportTitle => 'Report a problem';

  @override
  String get feedbackReportSubtitle => 'Something not working? Tell us what happened';

  @override
  String get feedbackIdeaTitle => 'Suggest a feature';

  @override
  String get feedbackIdeaSubtitle => 'An idea that would make AirReply better';

  @override
  String get feedbackKindLabel => 'Type';

  @override
  String get feedbackKindProblem => 'Problem';

  @override
  String get feedbackKindIdea => 'Feature idea';

  @override
  String get feedbackAreaLabel => 'What is it about?';

  @override
  String get feedbackAreaNotifications => 'Notifications';

  @override
  String get feedbackAreaReplies => 'Replies';

  @override
  String get feedbackAreaPairing => 'Pairing';

  @override
  String get feedbackAreaAlerts => 'Alerts';

  @override
  String get feedbackAreaSync => 'Sync';

  @override
  String get feedbackAreaDesign => 'Look and feel';

  @override
  String get feedbackAreaOther => 'Something else';

  @override
  String get feedbackMessageLabel => 'Your message';

  @override
  String get feedbackProblemHint => 'What happened, and what did you expect? Steps to make it happen again help a lot.';

  @override
  String get feedbackIdeaHint => 'What would you like AirReply to do, and how would it help you?';

  @override
  String get feedbackTooShort => 'Write a little more (at least 10 characters).';

  @override
  String get feedbackIncludeDetails => 'Include device details';

  @override
  String get feedbackDetailsSubtitle =>
      'System, device model, app language and role. Never your notifications or keys.';

  @override
  String get feedbackSent => 'Thanks! Your email app is ready: tap send there to finish.';

  @override
  String get feedbackNoEmailApp => 'No email app is set up on this device.';
}
