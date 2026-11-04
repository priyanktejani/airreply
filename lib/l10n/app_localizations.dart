import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('zh'),
  ];

  /// The app's name: window title, task switcher.
  ///
  /// In en, this message translates to:
  /// **'AirReply'**
  String get appTitle;

  /// Navigation tab: the start screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Navigation tab: every mirrored notification.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// Screen reader label of the Notifications tab, with how many are unread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Notifications} =1{Notifications, 1 unread} other{Notifications, {count} unread}}'**
  String tabNotificationsUnread(int count);

  /// Navigation tab: the paired devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get tabDevices;

  /// Navigation tab: settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Above the notifications list: how many are unread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All read} other{{count} unread}}'**
  String inboxUnread(int count);

  /// Welcome headline, first line.
  ///
  /// In en, this message translates to:
  /// **'Your phone,'**
  String get welcomeHeadlineFirst;

  /// Welcome headline, second (underlined, accent) line.
  ///
  /// In en, this message translates to:
  /// **'Everywhere.'**
  String get welcomeHeadlineSecond;

  /// Welcome screen, under the headline.
  ///
  /// In en, this message translates to:
  /// **'Read your phone\'s notifications on your iPhone, iPad, Mac, PC or browser, and reply to messages from there.'**
  String get welcomeIntro;

  /// Small label above the role question.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeEyebrow;

  /// Welcome screen: choose sharing or receiving.
  ///
  /// In en, this message translates to:
  /// **'How will you use this device?'**
  String get welcomeQuestion;

  /// Role option: this Android phone sends its notifications.
  ///
  /// In en, this message translates to:
  /// **'Share my notifications'**
  String get roleShareTitle;

  /// Role option description, on Android.
  ///
  /// In en, this message translates to:
  /// **'This phone sends its notifications to your other devices, and sends the replies you write there.'**
  String get roleShareDescription;

  /// Role option description where sharing is impossible (not Android).
  ///
  /// In en, this message translates to:
  /// **'Only Android lets apps read notifications. Use an Android phone to share.'**
  String get roleShareUnavailable;

  /// Role option: this device shows another phone's notifications.
  ///
  /// In en, this message translates to:
  /// **'View and reply here'**
  String get roleReceiveTitle;

  /// Role option description.
  ///
  /// In en, this message translates to:
  /// **'See your phone\'s notifications on this device and answer messages without picking it up.'**
  String get roleReceiveDescription;

  /// Error shown to the person: offline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorOffline;

  /// Error shown to the person: serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach AirReply servers. Check your connection.'**
  String get errorServerUnreachable;

  /// Error shown to the person: signInRefused.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was refused. Is Anonymous sign-in enabled in the Firebase project?'**
  String get errorSignInRefused;

  /// Error shown to the person: signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed.'**
  String get errorSignInFailed;

  /// Error shown to the person: syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync with your paired device failed.'**
  String get errorSyncFailed;

  /// Error shown to the person: pairingCodeNotCreated.
  ///
  /// In en, this message translates to:
  /// **'Could not create a pairing code. Please try again.'**
  String get errorPairingCodeNotCreated;

  /// Error shown to the person: sessionNotConfirmable.
  ///
  /// In en, this message translates to:
  /// **'This session cannot be confirmed.'**
  String get errorSessionNotConfirmable;

  /// Error shown to the person: codeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This code is no longer available. Make a new one on the other phone.'**
  String get errorCodeUnavailable;

  /// Error shown to the person: cannotPairWithItself.
  ///
  /// In en, this message translates to:
  /// **'A device cannot pair with itself.'**
  String get errorCannotPairWithItself;

  /// Error shown to the person: codeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This code was already used.'**
  String get errorCodeAlreadyUsed;

  /// Error shown to the person: noDeviceJoined.
  ///
  /// In en, this message translates to:
  /// **'No device has joined yet.'**
  String get errorNoDeviceJoined;

  /// Error shown to the person: codeFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code shown on the phone.'**
  String get errorCodeFormat;

  /// Error shown to the person: notAPairingCode.
  ///
  /// In en, this message translates to:
  /// **'That is not an AirReply pairing code.'**
  String get errorNotAPairingCode;

  /// Error shown to the person: codeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No pairing code like that. Check the code on the other phone.'**
  String get errorCodeNotFound;

  /// Error shown to the person: codeExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Make a new one.'**
  String get errorCodeExpired;

  /// Error shown to the person: qrMismatch.
  ///
  /// In en, this message translates to:
  /// **'The QR code does not match this session. Pairing stopped for your safety.'**
  String get errorQrMismatch;

  /// Error shown to the person: notConfirmedYet.
  ///
  /// In en, this message translates to:
  /// **'The other phone has not confirmed yet.'**
  String get errorNotConfirmedYet;

  /// Error shown to the person: pairingCancelledOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Pairing was cancelled on the other phone.'**
  String get errorPairingCancelledOnPhone;

  /// Error shown to the person: pairingCancelled.
  ///
  /// In en, this message translates to:
  /// **'The pairing was cancelled. Make a new code to try again.'**
  String get errorPairingCancelled;

  /// Error shown to the person: pairingNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This pairing session is not available to this device.'**
  String get errorPairingNotAvailable;

  /// Error shown to the person: pairingServerFailed.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete pairing.'**
  String get errorPairingServerFailed;

  /// Error shown to the person: pairingOffInDemo.
  ///
  /// In en, this message translates to:
  /// **'Pairing is turned off in demo mode.'**
  String get errorPairingOffInDemo;

  /// Error shown to the person: notPaired.
  ///
  /// In en, this message translates to:
  /// **'This device is not paired yet.'**
  String get errorNotPaired;

  /// Error shown to the person: invalidPeerKey.
  ///
  /// In en, this message translates to:
  /// **'The other device sent an invalid key.'**
  String get errorInvalidPeerKey;

  /// Error shown to the person: unsafePeerKey.
  ///
  /// In en, this message translates to:
  /// **'The other device sent an unsafe key.'**
  String get errorUnsafePeerKey;

  /// Error shown to the person: encryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not encrypt the notification.'**
  String get errorEncryptFailed;

  /// Error shown to the person: decryptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decrypt the notification.'**
  String get errorDecryptFailed;

  /// Error shown to the person: payloadUnknown.
  ///
  /// In en, this message translates to:
  /// **'This notification is in an unknown format.'**
  String get errorPayloadUnknown;

  /// Error shown to the person: payloadForeign.
  ///
  /// In en, this message translates to:
  /// **'This notification was not made with this pair\'s key, or it was altered.'**
  String get errorPayloadForeign;

  /// Error shown to the person: nativeServiceFailed.
  ///
  /// In en, this message translates to:
  /// **'The Android notification service failed.'**
  String get errorNativeServiceFailed;

  /// Error shown to the person: nativeServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Android notification service is not available.'**
  String get errorNativeServiceUnavailable;

  /// Error shown to the person: replyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type a reply first.'**
  String get errorReplyEmpty;

  /// Error shown to the person: replyTooLong.
  ///
  /// In en, this message translates to:
  /// **'That reply is too long.'**
  String get errorReplyTooLong;

  /// Error shown to the person: replyNotPossible.
  ///
  /// In en, this message translates to:
  /// **'This notification cannot be answered.'**
  String get errorReplyNotPossible;

  /// Error shown to the person: replyDismissed.
  ///
  /// In en, this message translates to:
  /// **'This notification was dismissed on your phone, so it can no longer be answered.'**
  String get errorReplyDismissed;

  /// Error: some paired devices could not be reached.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Could not reach 1 of {total} paired devices.} other{Could not reach {count} of {total} paired devices.}}'**
  String errorDevicesUnreachable(int count, int total);

  /// An error sentence followed by a technical code in brackets.
  ///
  /// In en, this message translates to:
  /// **'{message} ({detail})'**
  String errorWithDetail(String message, String detail);

  /// Error with no known cause.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Error: sharing tried on a platform that is not Android.
  ///
  /// In en, this message translates to:
  /// **'Sharing notifications is only available on Android.'**
  String get errorSharingAndroidOnly;

  /// Compact time: under a minute ago.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// Compact time: minutes ago, e.g. "5m".
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String timeMinutesShort(int n);

  /// Compact time: hours ago, e.g. "3h".
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String timeHoursShort(int n);

  /// A day heading: today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeToday;

  /// A day heading or time: yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// A full timestamp: day heading and clock time.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String timeAt(String day, String time);

  /// How long ago: under a minute.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// How long ago, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 min ago} other{{n} min ago}}'**
  String timeMinutesAgo(int n);

  /// How long ago, in hours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 h ago} other{{n} h ago}}'**
  String timeHoursAgo(int n);

  /// Button: undo the last action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// Button: cancel and close.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Placeholder of a search box.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// Tooltip: empty the search box.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// Start-up failed.
  ///
  /// In en, this message translates to:
  /// **'AirReply could not start'**
  String get splashFailed;

  /// Button: retry what failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Screen reader label of the start-up screen.
  ///
  /// In en, this message translates to:
  /// **'AirReply is starting'**
  String get splashStarting;

  /// Eyebrow: the app needs setting up.
  ///
  /// In en, this message translates to:
  /// **'Setup required'**
  String get firebaseSetupEyebrow;

  /// Title of the Firebase setup screen.
  ///
  /// In en, this message translates to:
  /// **'Connect Firebase'**
  String get firebaseSetupTitle;

  /// Firebase setup instructions.
  ///
  /// In en, this message translates to:
  /// **'AirReply syncs your devices through your own Firebase project. Run this in the project folder, then rebuild the app.'**
  String get firebaseSetupBody;

  /// Button: copy the shown command.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get actionCopyCommand;

  /// Eyebrow above the technical error.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get firebaseSetupDetails;

  /// Device state: connected and live.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// Device state: no connection.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get deviceOffline;

  /// Device state: reaching the server.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get deviceConnecting;

  /// Device state: the phone needs notification access.
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get deviceNeedsAccess;

  /// Device state: sharing is paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get devicePaused;

  /// Device state: Android stopped the listener.
  ///
  /// In en, this message translates to:
  /// **'Not receiving'**
  String get deviceNotReceiving;

  /// Explains the connected state on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'New notifications arrive as they happen.'**
  String get deviceReceivingDetail;

  /// Explains the connected state on the sharing phone.
  ///
  /// In en, this message translates to:
  /// **'New notifications are shared as they arrive.'**
  String get deviceSharingDetail;

  /// Explains the offline state.
  ///
  /// In en, this message translates to:
  /// **'Showing saved notifications until this device is back online.'**
  String get deviceOfflineDetail;

  /// Explains the connecting state.
  ///
  /// In en, this message translates to:
  /// **'Reaching the server…'**
  String get deviceConnectingDetail;

  /// Explains the needs-access state.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off, so nothing can be shared.'**
  String get deviceNeedsAccessDetail;

  /// Explains the paused state.
  ///
  /// In en, this message translates to:
  /// **'Sharing is off. Turn it on to send notifications.'**
  String get devicePausedDetail;

  /// Explains the not-receiving state.
  ///
  /// In en, this message translates to:
  /// **'Android stopped AirReply\'s notification listener.'**
  String get deviceNotReceivingDetail;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get settingsAccessEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsPermissionsTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get settingsFilterEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get settingsAppsTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Mirroring and privacy'**
  String get settingsPrivacyTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSyncTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Appearance and accessibility'**
  String get settingsAppearanceTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsDataTitle;

  /// Settings section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelpEyebrow;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'Help and about'**
  String get settingsHelpTitle;

  /// A permission that is granted.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get permissionOn;

  /// Button: open the system setting.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// Button: grant a permission.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get actionAllow;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Notification access'**
  String get permissionAccessTitle;

  /// Permission row.
  ///
  /// In en, this message translates to:
  /// **'Required to read and share notifications'**
  String get permissionAccessSubtitle;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Status notification'**
  String get permissionStatusTitle;

  /// Permission row: the sharing notification on the phone.
  ///
  /// In en, this message translates to:
  /// **'Shows \"Notification Sync Active\" with a Pause button'**
  String get permissionStatusSubtitle;

  /// Permission row title.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation'**
  String get permissionBatteryTitle;

  /// Battery setting is right.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted: Android will not pause sharing'**
  String get permissionBatteryOk;

  /// Battery setting needs changing.
  ///
  /// In en, this message translates to:
  /// **'Set to \"Unrestricted\" so Android never pauses sharing'**
  String get permissionBatteryFix;

  /// Permission row title: system notifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get permissionAlertsTitle;

  /// Alerts permission on the web.
  ///
  /// In en, this message translates to:
  /// **'Lets this browser show new notifications'**
  String get permissionAlertsBrowser;

  /// Alerts permission.
  ///
  /// In en, this message translates to:
  /// **'Lets this device alert you to new notifications'**
  String get permissionAlertsDevice;

  /// Something is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// App filter: all apps.
  ///
  /// In en, this message translates to:
  /// **'Every app is shared'**
  String get appsAllShared;

  /// App filter: none.
  ///
  /// In en, this message translates to:
  /// **'No apps selected: nothing is shared'**
  String get appsNoneShared;

  /// Settings row: choose shared apps.
  ///
  /// In en, this message translates to:
  /// **'Apps to share'**
  String get appsToShareTitle;

  /// Settings row: apps without alerts.
  ///
  /// In en, this message translates to:
  /// **'Muted apps'**
  String get appsMutedTitle;

  /// Privacy row title.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get encryptionTitle;

  /// Explains the encryption.
  ///
  /// In en, this message translates to:
  /// **'Each pair has its own key, agreed between the two devices (X25519). Notifications and replies are sealed with AES-256-GCM. History stays on your devices: the server only relays ciphertext and deletes each message once it is delivered.'**
  String get encryptionDetail;

  /// Switch: share this phone's notifications.
  ///
  /// In en, this message translates to:
  /// **'Share notifications'**
  String get shareNotificationsTitle;

  /// Sharing cannot start yet.
  ///
  /// In en, this message translates to:
  /// **'Turn on notification access first'**
  String get shareNeedsAccess;

  /// Switch title.
  ///
  /// In en, this message translates to:
  /// **'Show message text in alerts'**
  String get alertTextTitle;

  /// Switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'Off: alerts only name the app, for lock screens and shared displays'**
  String get alertTextSubtitle;

  /// Row title on the web.
  ///
  /// In en, this message translates to:
  /// **'Alerts in this browser'**
  String get alertsBrowserTitle;

  /// Row title on desktop.
  ///
  /// In en, this message translates to:
  /// **'Alerts on this computer'**
  String get alertsComputerTitle;

  /// Desktop alerts explanation.
  ///
  /// In en, this message translates to:
  /// **'New notifications alert you while AirReply is running. Keep it open (on Mac it keeps running when you close the window).'**
  String get alertsWhileOpen;

  /// Sync status with nothing paired.
  ///
  /// In en, this message translates to:
  /// **'No paired devices'**
  String get syncNoDevices;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatusTitle;

  /// Message while refreshing.
  ///
  /// In en, this message translates to:
  /// **'Checking the connection…'**
  String get syncChecking;

  /// Button: check again.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Notification listener'**
  String get listenerTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Android to connect AirReply\'s listener again if devices stop receiving'**
  String get listenerSubtitle;

  /// Button: reconnect the listener.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get actionReconnect;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'System follows this device'**
  String get themeSubtitle;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme choice.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Switch title.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticsTitle;

  /// Switch subtitle.
  ///
  /// In en, this message translates to:
  /// **'A light tap when you send, toggle or confirm'**
  String get hapticsSubtitle;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSizeTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'AirReply follows the text size and bold text set on this device'**
  String get textSizeSubtitle;

  /// Confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Remove all devices?'**
  String get removeAllConfirmTitle;

  /// Button: remove every device.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get actionRemoveAll;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllReadTitle;

  /// Message after marking all read.
  ///
  /// In en, this message translates to:
  /// **'All marked as read'**
  String get markedAllRead;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Restore hidden notifications'**
  String get restoreHiddenTitle;

  /// Message after restoring.
  ///
  /// In en, this message translates to:
  /// **'Hidden notifications restored'**
  String get hiddenRestored;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Remove all devices'**
  String get removeAllTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Ends every pair; their history stays under Previous devices'**
  String get removeAllSubtitle;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshootingTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'What to check when notifications or replies do not arrive'**
  String get troubleshootingSubtitle;

  /// Settings row and screen title.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connection, permission and sync details to check or share'**
  String get diagnosticsSubtitle;

  /// Settings row title.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licencesTitle;

  /// The app's one-line description.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s notifications, on every screen.'**
  String get appTagline;

  /// Sharing state.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get syncSharing;

  /// Sharing state: starting up.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get syncStarting;

  /// Permission row title (phone makers' autostart switch).
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get permissionAutostartTitle;

  /// Autostart row.
  ///
  /// In en, this message translates to:
  /// **'Required on {vendor} phones. Android cannot report it, so check it there.'**
  String permissionAutostartSubtitle(String vendor);

  /// App filter: some apps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only 1 selected app} other{Only {count} selected apps}}'**
  String appsSomeShared(int count);

  /// Muted apps summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Every app can alert you} other{{count} muted: they arrive silently}}'**
  String appsMuted(int count);

  /// Sync status: connected.
  ///
  /// In en, this message translates to:
  /// **'{state}. Live now.'**
  String syncLive(String state);

  /// Sync status with when it last synced.
  ///
  /// In en, this message translates to:
  /// **'{state}. Last synced {ago}.'**
  String syncLastSynced(String state, String ago);

  /// Sync status with its explanation.
  ///
  /// In en, this message translates to:
  /// **'{state}. {detail}'**
  String syncStateDetail(String state, String detail);

  /// Confirm removing the only device.
  ///
  /// In en, this message translates to:
  /// **'Syncing with {name} stops. Its history stays on this device under Previous devices, and comes back if you pair it again.'**
  String removeAllConfirmOne(String name);

  /// Confirm removing every device.
  ///
  /// In en, this message translates to:
  /// **'Syncing with all {count} devices stops. Their history stays on this device under Previous devices, and comes back if you pair them again.'**
  String removeAllConfirmMany(int count);

  /// How many notifications are unread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing unread} other{{count} unread}}'**
  String unreadCount(int count);

  /// How many notifications are hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing hidden} other{{count} hidden on this device}}'**
  String hiddenCount(int count);

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off'**
  String get noticeAccessOffTitle;

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'AirReply cannot see new notifications until you turn it back on.'**
  String get noticeAccessOffMessage;

  /// Button: open the system settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Sharing is paused'**
  String get noticePausedTitle;

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this phone are not being sent to your devices.'**
  String get noticePausedMessage;

  /// Button: turn sharing back on.
  ///
  /// In en, this message translates to:
  /// **'Resume sharing'**
  String get actionResumeSharing;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Not receiving notifications'**
  String get noticeNotReceivingTitle;

  /// Notice message on phones with an Autostart switch.
  ///
  /// In en, this message translates to:
  /// **'Android stopped AirReply\'s listener. Reconnect, and turn on Autostart for AirReply on {vendor} phones so it does not happen again.'**
  String noticeNotReceivingAutostart(String vendor);

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'Android stopped AirReply\'s notification listener. Reconnect to start again.'**
  String get noticeNotReceivingMessage;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation is on'**
  String get noticeBatteryTitle;

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'Android may pause sharing to save battery. Set AirReply to \"Unrestricted\".'**
  String get noticeBatteryMessage;

  /// Button: open battery settings.
  ///
  /// In en, this message translates to:
  /// **'Battery settings'**
  String get actionBatterySettings;

  /// Notice title.
  ///
  /// In en, this message translates to:
  /// **'Alerts are off on this device'**
  String get noticeAlertsOffTitle;

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'New notifications still appear here, but this device will not alert you.'**
  String get noticeAlertsOffMessage;

  /// Button: allow system notifications.
  ///
  /// In en, this message translates to:
  /// **'Allow alerts'**
  String get actionAllowAlerts;

  /// Notice title: one device offline.
  ///
  /// In en, this message translates to:
  /// **'{name} is offline'**
  String noticeOneOffline(String name);

  /// Notice title: several devices offline.
  ///
  /// In en, this message translates to:
  /// **'{count} devices are offline'**
  String noticeManyOffline(int count);

  /// Notice message.
  ///
  /// In en, this message translates to:
  /// **'Showing saved notifications. New ones arrive once this device is back online.'**
  String get noticeOfflineMessage;

  /// Button: try again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Setup screen title.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setupTitle;

  /// Privacy disclosure eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get disclosureEyebrow;

  /// Privacy disclosure title.
  ///
  /// In en, this message translates to:
  /// **'AirReply needs access to your notifications'**
  String get disclosureTitle;

  /// Privacy disclosure.
  ///
  /// In en, this message translates to:
  /// **'To share this phone\'s notifications with your paired devices, AirReply uses Android\'s Notification Access permission.'**
  String get disclosureIntro;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'What is accessed'**
  String get disclosureWhatTitle;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'The notifications shown on this phone: app name, title, text, time, and the reply action of messaging apps. This works in the background, even when AirReply is closed.'**
  String get disclosureWhatBody;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get disclosureWhyTitle;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'Only to show those notifications on the devices you pair, and to send the replies you type there through the original app on this phone.'**
  String get disclosureWhyBody;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'How it is protected'**
  String get disclosureHowTitle;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'Each notification is encrypted on this phone with AES-256-GCM, using a key that only this phone and the paired device hold. Our servers relay ciphertext they cannot read, and delete it once delivered: history is kept only on your devices.'**
  String get disclosureHowBody;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'You stay in control'**
  String get disclosureControlTitle;

  /// Privacy disclosure point.
  ///
  /// In en, this message translates to:
  /// **'Choose which apps are shared, pause from the status notification at any time, or remove a device to stop sharing; delete its history whenever you like. Notification content is never sold, shared with third parties, or used for ads or analytics.'**
  String get disclosureControlBody;

  /// Button: accept the disclosure.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get actionAgreeAndContinue;

  /// Button: decline.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get actionNoThanks;

  /// Setup progress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} required steps done'**
  String setupProgress(int done, int total);

  /// Setup checklist title.
  ///
  /// In en, this message translates to:
  /// **'Set up this phone'**
  String get setupPhoneTitle;

  /// Setup checklist subtitle.
  ///
  /// In en, this message translates to:
  /// **'Two permissions let AirReply share notifications and keep running in the background.'**
  String get setupPhoneSubtitle;

  /// Setup step.
  ///
  /// In en, this message translates to:
  /// **'Required. Find AirReply in the list and switch it on.'**
  String get setupAccessSubtitle;

  /// Setup step.
  ///
  /// In en, this message translates to:
  /// **'Shows \"Notification Sync Active\" with a Pause button while sharing is on.'**
  String get setupStatusSubtitle;

  /// Setup step.
  ///
  /// In en, this message translates to:
  /// **'Required on {vendor}. Without it the phone stops AirReply from listening once the app is closed. Find AirReply and switch Autostart on.'**
  String setupAutostartSubtitle(String vendor);

  /// Setup step.
  ///
  /// In en, this message translates to:
  /// **'Recommended. Set AirReply to \"Unrestricted\" so Android never pauses sharing.'**
  String get setupBatterySubtitle;

  /// Button: go on.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Button label while a step is missing.
  ///
  /// In en, this message translates to:
  /// **'Turn on notification access to continue'**
  String get setupNeedsAccess;

  /// A finished step.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepDone;

  /// Pairing screen title.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get pairADevice;

  /// Pairing screen title before anything is paired.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairTitle;

  /// Pairing screen title on the phone when already sharing.
  ///
  /// In en, this message translates to:
  /// **'Add a device'**
  String get pairAddADevice;

  /// Message once paired.
  ///
  /// In en, this message translates to:
  /// **'Paired with {name}'**
  String pairPairedWith(String name);

  /// Pairing progress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String pairStep(int current, int total);

  /// Pairing failed: title.
  ///
  /// In en, this message translates to:
  /// **'Pairing stopped'**
  String get pairStopped;

  /// Button: new pairing code.
  ///
  /// In en, this message translates to:
  /// **'Make a new code'**
  String get actionMakeNewCode;

  /// Pairing instructions on the phone.
  ///
  /// In en, this message translates to:
  /// **'On your iPhone, iPad, Mac, PC, browser or other Android, open AirReply, choose \"View and reply here\", then scan this code or type the digits.'**
  String get pairShowCodeIntro;

  /// Screen reader label of the QR code.
  ///
  /// In en, this message translates to:
  /// **'Pairing QR code'**
  String get pairQrLabel;

  /// Label above the six digits (uppercase style).
  ///
  /// In en, this message translates to:
  /// **'OR TYPE THIS CODE'**
  String get pairOrTypeCode;

  /// Message after copying the code.
  ///
  /// In en, this message translates to:
  /// **'Code {code} copied'**
  String pairCodeCopied(String code);

  /// Button: copy the code.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get actionCopyCode;

  /// Button: make another code.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get actionNewCode;

  /// Verification title.
  ///
  /// In en, this message translates to:
  /// **'Do the codes match?'**
  String get pairCodesMatchQuestion;

  /// Verification warning.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to pair. It must show exactly this code. If it does not, someone else may be trying to connect.'**
  String pairVerifyWarning(String name);

  /// Button: confirm pairing.
  ///
  /// In en, this message translates to:
  /// **'Codes match, pair'**
  String get actionCodesMatch;

  /// Button: reject pairing.
  ///
  /// In en, this message translates to:
  /// **'They do not match'**
  String get actionCodesDoNotMatch;

  /// Pairing title on a device already receiving.
  ///
  /// In en, this message translates to:
  /// **'Add another phone'**
  String get pairAddAnotherPhone;

  /// Pairing title on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Pair with your phone'**
  String get pairWithYourPhone;

  /// Pairing instructions on the receiving device.
  ///
  /// In en, this message translates to:
  /// **'On the Android phone you want to see here, open AirReply and choose \"Share my notifications\" (or \"Add a device\" if it already shares). It shows a QR code and six digits.'**
  String get pairEnterCodeIntro;

  /// Pairing method: scan the QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get pairMethodScan;

  /// Pairing method: type the digits.
  ///
  /// In en, this message translates to:
  /// **'Type code'**
  String get pairMethodType;

  /// Label above the code field (uppercase style).
  ///
  /// In en, this message translates to:
  /// **'PAIRING CODE'**
  String get pairCodeLabel;

  /// Hint under the code field.
  ///
  /// In en, this message translates to:
  /// **'Pairing starts as soon as you type the last digit.'**
  String get pairStartsOnLastDigit;

  /// Pairing in progress.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get pairConnecting;

  /// Scanner hint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on your phone.'**
  String get pairPointCamera;

  /// Camera permission refused.
  ///
  /// In en, this message translates to:
  /// **'AirReply needs the camera to scan. Allow it in your phone\'s settings, or type the code instead.'**
  String get cameraDenied;

  /// Camera failed to start.
  ///
  /// In en, this message translates to:
  /// **'The camera did not start.'**
  String get cameraNotStarted;

  /// Title while waiting for the phone.
  ///
  /// In en, this message translates to:
  /// **'Confirm on {name}'**
  String pairConfirmOn(String name);

  /// Waiting for the phone: what to do.
  ///
  /// In en, this message translates to:
  /// **'Check that your phone shows the same code, then tap \"Codes match\" there.'**
  String get pairConfirmHint;

  /// Waiting for the phone to confirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your phone…'**
  String get pairWaitingForPhone;

  /// The pairing code ran out.
  ///
  /// In en, this message translates to:
  /// **'Code expired, making a new one'**
  String get pairCodeExpired;

  /// Pairing code countdown.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}:{seconds}'**
  String pairExpiresIn(int minutes, String seconds);

  /// Screen reader label of the pairing steps.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {name}'**
  String pairStepNamed(int current, int total, String name);

  /// Error notice title on the pairing screen.
  ///
  /// In en, this message translates to:
  /// **'Could not pair'**
  String get pairCouldNotPair;

  /// Pairing step.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get stepShowCode;

  /// Pairing step.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get stepVerify;

  /// Pairing step.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get stepEnterCode;

  /// A time that has not happened yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// Device fact label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get factStatus;

  /// Device fact: live connection.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get factLive;

  /// Device fact label.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get factLastSynced;

  /// Device fact: right now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get factNow;

  /// When the phone last shared a notification.
  ///
  /// In en, this message translates to:
  /// **'Last shared'**
  String get lastShared;

  /// When the last notification arrived.
  ///
  /// In en, this message translates to:
  /// **'Last notification'**
  String get lastNotification;

  /// Device fact: when it was paired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get factPaired;

  /// Device fact label.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get factEncryption;

  /// Device fact value.
  ///
  /// In en, this message translates to:
  /// **'End-to-end, AES-256-GCM'**
  String get factEncryptionValue;

  /// Confirm removing a device: title.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeDeviceTitle(String name);

  /// Confirm removing a device.
  ///
  /// In en, this message translates to:
  /// **'Syncing with {name} stops on both devices. Its history stays on this device under Settings → Previous devices until you delete it. Other devices are not affected.'**
  String removeDeviceMessage(String name);

  /// Button: remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Message after removing a device.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String deviceRemoved(String name);

  /// Button: open notification access.
  ///
  /// In en, this message translates to:
  /// **'Turn on notification access'**
  String get actionTurnOnAccess;

  /// Button: open what this phone shared with a device.
  ///
  /// In en, this message translates to:
  /// **'Browse what you shared'**
  String get browseShared;

  /// Button: open a phone's history.
  ///
  /// In en, this message translates to:
  /// **'Browse notification history'**
  String get browseHistory;

  /// Button: unpair a device.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get actionRemoveDevice;

  /// Tooltip: pair a phone.
  ///
  /// In en, this message translates to:
  /// **'Add a phone'**
  String get addAPhone;

  /// A label followed by a time, e.g. "Last shared 5 min ago".
  ///
  /// In en, this message translates to:
  /// **'{label} {time}'**
  String factWithTime(String label, String time);

  /// When a device was paired.
  ///
  /// In en, this message translates to:
  /// **'Paired {time}'**
  String pairedAgo(String time);

  /// How many devices are paired.
  ///
  /// In en, this message translates to:
  /// **'{count} paired'**
  String devicesPaired(int count);

  /// Devices screen intro on the phone.
  ///
  /// In en, this message translates to:
  /// **'This phone shares its notifications with these devices.'**
  String get devicesIntroSender;

  /// Devices screen intro on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'This device shows notifications from these phones.'**
  String get devicesIntroReceiver;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get devicesNone;

  /// Empty state description.
  ///
  /// In en, this message translates to:
  /// **'Pair a device to start.'**
  String get devicesNoneHint;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not arriving'**
  String get helpNotArrivingQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'On the phone, open AirReply and check that \"Share notifications\" is on and the app is allowed to run in the background. Both devices need an internet connection. Then retry here.'**
  String get helpNotArrivingA;

  /// Button: sync again.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get actionRetrySync;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'No alerts on this device'**
  String get helpNoAlertsQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'New notifications always reach the Notifications tab. To be alerted too, allow notifications for AirReply, and check that the app is not muted in Settings → Muted apps.'**
  String get helpNoAlertsA;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'A reply says \"Expired on phone\"'**
  String get helpExpiredQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'Replies are sent through the notification on the phone. Once it is cleared there, or the app replaced it, it can no longer be answered. Reply to a newer notification, or from the phone.'**
  String get helpExpiredA;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'Devices are not receiving notifications'**
  String get helpNotReceivingQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'Check that notification access is on and sharing is not paused. If Android stopped AirReply\'s listener, reconnect it.'**
  String get helpNotReceivingA;

  /// Button: reconnect the notification listener.
  ///
  /// In en, this message translates to:
  /// **'Reconnect listener'**
  String get actionReconnectListener;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'Sharing stops after a while'**
  String get helpStopsQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'On {vendor} phones, turn on Autostart for AirReply and set its battery use to \"Unrestricted\", or the phone stops it in the background.'**
  String helpStopsAutostartA(String vendor);

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'Set AirReply\'s battery use to \"Unrestricted\" so Android does not pause it in the background.'**
  String get helpStopsA;

  /// Troubleshooting question.
  ///
  /// In en, this message translates to:
  /// **'Replies are not delivered'**
  String get helpRepliesQ;

  /// Troubleshooting answer.
  ///
  /// In en, this message translates to:
  /// **'A reply is sent through the notification it answers, so that notification must still be in this phone\'s status bar. Messaging apps that offer \"Reply\" in their notifications work best.'**
  String get helpRepliesA;

  /// Title of a device's history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Eyebrow: what this phone shared with a device.
  ///
  /// In en, this message translates to:
  /// **'Shared with it'**
  String get historySharedWithIt;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyNothingYet;

  /// Empty device history on the phone.
  ///
  /// In en, this message translates to:
  /// **'Notifications this phone shares with {name} appear here.'**
  String historyEmptySender(String name);

  /// Empty device history on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Notifications from {name} appear here.'**
  String historyEmptyReceiver(String name);

  /// Stands in for a phone name that is not known.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get thisPhone;

  /// Stands in for a device name that is not known.
  ///
  /// In en, this message translates to:
  /// **'it'**
  String get itDevice;

  /// Second line of the phone's home headline, after "Your phone,".
  ///
  /// In en, this message translates to:
  /// **'Shared.'**
  String get homeHeadlineSender;

  /// Home intro on the phone.
  ///
  /// In en, this message translates to:
  /// **'Notifications from this phone reach your other devices, and their replies come back.'**
  String get homeIntroSender;

  /// Home intro on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Your phone’s notifications arrive here. Read them, and reply without picking it up.'**
  String get homeIntroReceiver;

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get searchNotificationsHint;

  /// Eyebrow above the day's figures.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayEyebrow;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get homeGlanceTitle;

  /// Section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get homeRecentEyebrow;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Latest notifications'**
  String get homeLatestTitle;

  /// Button: see everything.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// Empty recent list on the phone.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared yet. New notifications on this phone will appear here.'**
  String get homeRecentEmptySender;

  /// Empty recent list on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. New notifications from your phone will appear here.'**
  String get homeRecentEmptyReceiver;

  /// Error loading recent notifications.
  ///
  /// In en, this message translates to:
  /// **'Recent notifications could not be loaded.'**
  String get homeRecentFailed;

  /// Section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get homeSharingEyebrow;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get homeThisPhoneTitle;

  /// Section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorksEyebrow;

  /// Section title on the phone.
  ///
  /// In en, this message translates to:
  /// **'Share once. Reply anywhere.'**
  String get howItWorksSenderTitle;

  /// Section title on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Three steps. Every screen.'**
  String get howItWorksReceiverTitle;

  /// Bell button tooltip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Notifications} other{Notifications, {count} unread}}'**
  String bellUnread(int count);

  /// Figure label: notifications today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// Figure label: unread notifications.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get statUnread;

  /// Figure label: paired devices.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Device} other{Devices}}'**
  String statDevices(int count);

  /// Search empty state title.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// Search empty state.
  ///
  /// In en, this message translates to:
  /// **'No notification or device mentions “{query}”.'**
  String searchNoMatchesDetail(String query);

  /// Eyebrow above search results.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchEyebrow;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Share from your phone'**
  String get stepShareTitle;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'On your Android phone, AirReply sends each notification here, end-to-end encrypted.'**
  String get stepShareText;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Read it here'**
  String get stepReadTitle;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Notifications arrive within seconds, grouped by app and by person.'**
  String get stepReadText;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Reply from anywhere'**
  String get stepReplyTitle;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Write an answer here; your phone sends it through the app it came from.'**
  String get stepReplyText;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Pick what to share'**
  String get stepPickTitle;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Choose every app, or only the ones you want on your other devices.'**
  String get stepPickText;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Pair your devices'**
  String get stepPairTitle;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'A Mac, PC, iPhone, iPad or browser scans a code once, and they stay paired.'**
  String get stepPairText;

  /// How it works step.
  ///
  /// In en, this message translates to:
  /// **'Replies written there are sent from this phone, through the app they belong to.'**
  String get stepReplySenderText;

  /// How many apps are shared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected app} other{{count} selected apps}}'**
  String appsSelectedCount(int count);

  /// Shortcut action.
  ///
  /// In en, this message translates to:
  /// **'Choose apps →'**
  String get actionChooseApps;

  /// Devices that can be paired.
  ///
  /// In en, this message translates to:
  /// **'iPhone, iPad, Mac, PC, browser or Android'**
  String get pairDeviceKinds;

  /// Shortcut action.
  ///
  /// In en, this message translates to:
  /// **'Pair →'**
  String get actionPairArrow;

  /// Several phones, by number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 phone} other{{count} phones}}'**
  String phonesCount(int count);

  /// Several devices, by number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String devicesCount(int count);

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Receiving from {names}.'**
  String statusReceivingFrom(String names);

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {names}…'**
  String statusConnectingTo(String names);

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Showing saved notifications from {names}.'**
  String statusShowingSaved(String names);

  /// Status detail.
  ///
  /// In en, this message translates to:
  /// **'Live. New notifications appear within seconds.'**
  String get statusLive;

  /// Status detail.
  ///
  /// In en, this message translates to:
  /// **'Last synced {ago}.'**
  String statusLastSynced(String ago);

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Sharing needs notification access.'**
  String get statusNeedsAccess;

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Sharing is paused.'**
  String get statusPaused;

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Sharing with {names}.'**
  String statusSharingWith(String names);

  /// Status headline.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not working right now.'**
  String get statusNotWorking;

  /// Status detail.
  ///
  /// In en, this message translates to:
  /// **'Notifications are end-to-end encrypted on this phone before they leave it.'**
  String get statusEncryptedDetail;

  /// Status detail.
  ///
  /// In en, this message translates to:
  /// **'Nothing from this phone reaches your devices until sharing is on.'**
  String get statusOffDetail;

  /// Short label: end-to-end encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get encrypted;

  /// Filter: no time limit.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get periodAnyTime;

  /// Filter: today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// Filter: the last week.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get periodWeek;

  /// A number of notifications.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification} other{{count} notifications}}'**
  String notificationsCount(int count);

  /// A number of conversations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conversation} other{{count} conversations}}'**
  String conversationsCount(int count);

  /// A number of messages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String messagesCount(int count);

  /// Pill: notifications that arrived meanwhile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new notification} other{{count} new notifications}}'**
  String newNotificationsCount(int count);

  /// A label followed by its unread count, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} unread'**
  String withUnread(String label, int count);

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing here now'**
  String get nothingHereNow;

  /// Empty state: the notifications are gone.
  ///
  /// In en, this message translates to:
  /// **'These notifications were hidden, removed, or came from a device that is no longer paired.'**
  String get goneDetail;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Back to notifications'**
  String get actionBackToNotifications;

  /// Search hint on an app's screen.
  ///
  /// In en, this message translates to:
  /// **'Search names, numbers and messages'**
  String get searchConversationsHint;

  /// Section eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversationsEyebrow;

  /// Section eyebrow with a count.
  ///
  /// In en, this message translates to:
  /// **'Conversations · {count}'**
  String conversationsEyebrowCount(int count);

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'People and groups'**
  String get peopleAndGroups;

  /// Section eyebrow with a count.
  ///
  /// In en, this message translates to:
  /// **'Other notifications · {count}'**
  String otherNotificationsCount(int count);

  /// Section title: notifications from an app.
  ///
  /// In en, this message translates to:
  /// **'From {app}'**
  String fromApp(String app);

  /// Search found nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String nothingMatchesQuery(String query);

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'This notification was removed, hidden, or belongs to a device that is no longer paired.'**
  String get notificationGoneDetail;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markAsUnread;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Hide from this device'**
  String get hideFromDevice;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get actionHide;

  /// Action: hide several notifications.
  ///
  /// In en, this message translates to:
  /// **'Hide {count} notifications'**
  String hideCount(int count);

  /// The person using the app, as a message sender.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// A message the person sent, in a preview.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String youSaid(String text);

  /// Badge: written on the phone.
  ///
  /// In en, this message translates to:
  /// **'Sent from your phone'**
  String get sentFromPhone;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Cleared on phone'**
  String get clearedOnPhone;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Can reply'**
  String get canReply;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Can be answered'**
  String get canBeAnswered;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'No replies in this app'**
  String get noRepliesInApp;

  /// Reply status.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get replySending;

  /// Reply status.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get replyDelivered;

  /// Reply status.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get replySent;

  /// Reply status.
  ///
  /// In en, this message translates to:
  /// **'Expired on phone'**
  String get replyExpired;

  /// Reply status.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get replyNotDelivered;

  /// Reply status, where the reply is not shown.
  ///
  /// In en, this message translates to:
  /// **'Reply sending'**
  String get replySendingPrefixed;

  /// Reply status, where the reply is not shown.
  ///
  /// In en, this message translates to:
  /// **'Reply delivered'**
  String get replyDeliveredPrefixed;

  /// Reply status, where the reply is not shown.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get replySentPrefixed;

  /// Reply status, where the reply is not shown.
  ///
  /// In en, this message translates to:
  /// **'Reply expired on phone'**
  String get replyExpiredPrefixed;

  /// Reply status, where the reply is not shown.
  ///
  /// In en, this message translates to:
  /// **'Reply not delivered'**
  String get replyNotDeliveredPrefixed;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get yourReply;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Your reply, as {app} shows it'**
  String yourReplyAsShown(String app);

  /// Message.
  ///
  /// In en, this message translates to:
  /// **'All marked as read'**
  String get allMarkedRead;

  /// Inbox source line on the phone.
  ///
  /// In en, this message translates to:
  /// **'Shared with {name}'**
  String sharedWith(String name);

  /// Inbox source line on the phone.
  ///
  /// In en, this message translates to:
  /// **'Shared with {count} devices'**
  String sharedWithDevices(int count);

  /// Inbox source line.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromDevice(String name);

  /// Inbox source line.
  ///
  /// In en, this message translates to:
  /// **'From {count} phones'**
  String fromPhones(int count);

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// Filters button tooltip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Filters} other{Filters, {count} on}}'**
  String filtersOn(int count);

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this search or filter.'**
  String get nothingMatchesFilter;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get actionClearSearchAndFilters;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// Empty inbox on the phone.
  ///
  /// In en, this message translates to:
  /// **'Notifications this phone shares appear here, with the replies sent from your devices.'**
  String get inboxEmptySender;

  /// Empty inbox on a receiving device.
  ///
  /// In en, this message translates to:
  /// **'Notifications from your phone appear here the moment they arrive.'**
  String get inboxEmptyReceiver;

  /// Empty inbox.
  ///
  /// In en, this message translates to:
  /// **'Every notification is hidden. Restore them from Settings.'**
  String get inboxAllHidden;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationsLoadFailed;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove filter'**
  String get removeFilter;

  /// Filter chip.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// A device whose name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// App name and message count.
  ///
  /// In en, this message translates to:
  /// **'{app} · {messages}'**
  String messageCountSubtitle(String app, String messages);

  /// Footnote.
  ///
  /// In en, this message translates to:
  /// **'These notifications were cleared on your phone, so they can no longer be answered from here.'**
  String get footnoteCleared;

  /// Footnote.
  ///
  /// In en, this message translates to:
  /// **'{app} does not accept replies for this conversation.'**
  String footnoteNoReplies(String app);

  /// A group message whose sender is not known.
  ///
  /// In en, this message translates to:
  /// **'Unknown sender'**
  String get unknownSender;

  /// Divider above unread messages.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get dividerNew;

  /// Message after hiding.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Notification hidden} other{{count} notifications hidden}}'**
  String notificationHidden(int count);

  /// Message.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Badge.
  ///
  /// In en, this message translates to:
  /// **'Dismissed on phone'**
  String get dismissedOnPhone;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide conversations'**
  String get hideConversations;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Show conversations'**
  String get showConversations;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Unmute alerts from {app}'**
  String unmuteApp(String app);

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Mute alerts from {app}'**
  String muteApp(String app);

  /// Kind of conversation.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get threadChat;

  /// Kind of conversation.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get threadGroup;

  /// Kind of conversation.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get threadNotification;

  /// Reply field hint.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyHint;

  /// Reply field hint.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyToHint(String name);

  /// Send button tooltip with its shortcut.
  ///
  /// In en, this message translates to:
  /// **'Send (Enter)'**
  String get sendWithEnter;

  /// Send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// Filter sheet title.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get actionClearAll;

  /// Filter label.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filterShow;

  /// Filter choice.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter choice.
  ///
  /// In en, this message translates to:
  /// **'Unread only'**
  String get filterUnreadOnly;

  /// Filter label.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get filterWhen;

  /// Filter label.
  ///
  /// In en, this message translates to:
  /// **'Shared with'**
  String get filterSharedWith;

  /// Filter label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get filterPhone;

  /// Filter label.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get filterApp;

  /// Filter choice.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get filterAllApps;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 notification} other{Show {count} notifications}}'**
  String showNotificationsCount(int count);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get actionShowMore;

  /// Device result subtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse what you shared with it'**
  String get browseSharedWithIt;

  /// Device result subtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse its notification history'**
  String get browseItsHistory;

  /// Swipe action.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get swipeUnread;

  /// Swipe action.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get swipeRead;

  /// Diagnostics screen intro.
  ///
  /// In en, this message translates to:
  /// **'Nothing here includes notification text or encryption keys.'**
  String get diagnosticsIntro;

  /// Message.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get reportCopied;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get actionCopyReport;

  /// Message.
  ///
  /// In en, this message translates to:
  /// **'Checking again…'**
  String get checkingAgain;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get actionCheckAgain;

  /// Diagnostics: why the report is in English.
  ///
  /// In en, this message translates to:
  /// **'The report itself stays in English, so whoever helps you can read it.'**
  String get diagnosticsReportNote;

  /// Welcome screen: how notifications are protected.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted with a key only your devices hold. The server relays ciphertext it cannot read.'**
  String get welcomeEncryption;

  /// Stands in for a device name that is not known.
  ///
  /// In en, this message translates to:
  /// **'The other device'**
  String get theOtherDevice;

  /// Apps to share: intro.
  ///
  /// In en, this message translates to:
  /// **'Choose what reaches your devices. This applies even while AirReply is closed.'**
  String get appsShareIntro;

  /// Choice: share only selected apps.
  ///
  /// In en, this message translates to:
  /// **'Only selected'**
  String get appsOnlySelected;

  /// Search hint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get searchApps;

  /// Warning.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected: no notifications are shared'**
  String get appsNothingSelected;

  /// How many apps are selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String appsSelected(int count);

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'Choose \"Only selected\" to pick which apps reach your devices.'**
  String get appsOnlySelectedHint;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Could not load your choice'**
  String get appsChoiceLoadFailed;

  /// Muted apps: intro.
  ///
  /// In en, this message translates to:
  /// **'Muted apps still arrive in Notifications, but never alert you on this device.'**
  String get appsMutedIntro;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'No apps yet'**
  String get appsNoneYet;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'Apps appear here once your phone has sent a notification from them.'**
  String get appsNoneYetHint;

  /// App row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get appMuted;

  /// App row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts on'**
  String get appAlertsOn;

  /// Empty search.
  ///
  /// In en, this message translates to:
  /// **'No apps match'**
  String get appsNoMatch;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Could not list apps'**
  String get appsListFailed;

  /// Loading message.
  ///
  /// In en, this message translates to:
  /// **'Reading installed apps…'**
  String get appsReading;

  /// Android notification channel name.
  ///
  /// In en, this message translates to:
  /// **'Mirrored notifications'**
  String get alertChannelName;

  /// Android notification channel description.
  ///
  /// In en, this message translates to:
  /// **'Notifications mirrored from your paired phone'**
  String get alertChannelDescription;

  /// Alert action.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get alertReply;

  /// Alert reply field hint.
  ///
  /// In en, this message translates to:
  /// **'Reply…'**
  String get alertReplyHint;

  /// Alert default action (Linux).
  ///
  /// In en, this message translates to:
  /// **'Open AirReply'**
  String get alertOpenApp;

  /// Alert text when message text is hidden.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get alertNewNotification;

  /// Settings row and sheet title: the app's language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Language choice: follow the device's language.
  ///
  /// In en, this message translates to:
  /// **'Same as this device'**
  String get languageSystem;

  /// The language setting when it follows the device, with the language that gives.
  ///
  /// In en, this message translates to:
  /// **'Same as this device ({language})'**
  String languageSystemCurrent(String language);

  /// Settings row and screen: removed devices whose history is kept.
  ///
  /// In en, this message translates to:
  /// **'Previous devices'**
  String get previousDevicesTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{History of removed devices stays here} =1{1 removed device, history kept} other{{count} removed devices, history kept}}'**
  String previousDevicesSubtitle(int count);

  /// Previous devices screen intro.
  ///
  /// In en, this message translates to:
  /// **'When you remove a device, its history stays on this device. Pair the same device again to continue where you left off, or delete the history here.'**
  String get previousDevicesIntro;

  /// Empty state title.
  ///
  /// In en, this message translates to:
  /// **'No previous devices'**
  String get previousDevicesNone;

  /// Empty state description.
  ///
  /// In en, this message translates to:
  /// **'The history of devices you remove appears here.'**
  String get previousDevicesNoneHint;

  /// A removed device: when, and how much history is kept.
  ///
  /// In en, this message translates to:
  /// **'Removed {date} · {count}'**
  String previousDeviceSummary(String date, String count);

  /// When a device was removed.
  ///
  /// In en, this message translates to:
  /// **'Removed {date}'**
  String previousDeviceRemoved(String date);

  /// Previous device history: how to get it back.
  ///
  /// In en, this message translates to:
  /// **'Pair {name} again to continue this history in your inbox.'**
  String previousDeviceContinue(String name);

  /// Button: delete a removed device's history.
  ///
  /// In en, this message translates to:
  /// **'Delete history'**
  String get actionDeleteHistory;

  /// Confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete the history of {name}?'**
  String deleteHistoryTitle(String name);

  /// Confirm message.
  ///
  /// In en, this message translates to:
  /// **'Its notifications and replies are deleted from this device. This cannot be undone.'**
  String get deleteHistoryMessage;

  /// Message after deleting.
  ///
  /// In en, this message translates to:
  /// **'History of {name} deleted'**
  String historyDeleted(String name);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get actionDeleteAll;

  /// Confirm title.
  ///
  /// In en, this message translates to:
  /// **'Delete all previous history?'**
  String get deleteAllHistoryTitle;

  /// Confirm message.
  ///
  /// In en, this message translates to:
  /// **'The history of every removed device is deleted from this device. This cannot be undone.'**
  String get deleteAllHistoryMessage;

  /// Message after deleting all.
  ///
  /// In en, this message translates to:
  /// **'Previous history deleted'**
  String get allHistoryDeleted;

  /// Settings row and form title.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get feedbackReportTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Something not working? Tell us what happened'**
  String get feedbackReportSubtitle;

  /// Settings row and form title.
  ///
  /// In en, this message translates to:
  /// **'Suggest a feature'**
  String get feedbackIdeaTitle;

  /// Settings row subtitle.
  ///
  /// In en, this message translates to:
  /// **'An idea that would make AirReply better'**
  String get feedbackIdeaSubtitle;

  /// Feedback form: problem or idea.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get feedbackKindLabel;

  /// Feedback type.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get feedbackKindProblem;

  /// Feedback type.
  ///
  /// In en, this message translates to:
  /// **'Feature idea'**
  String get feedbackKindIdea;

  /// Feedback form: area of the app.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get feedbackAreaLabel;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get feedbackAreaNotifications;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get feedbackAreaReplies;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Pairing'**
  String get feedbackAreaPairing;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get feedbackAreaAlerts;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get feedbackAreaSync;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Look and feel'**
  String get feedbackAreaDesign;

  /// Feedback area.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get feedbackAreaOther;

  /// Feedback form field label.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get feedbackMessageLabel;

  /// Feedback field hint for a problem.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what did you expect? Steps to make it happen again help a lot.'**
  String get feedbackProblemHint;

  /// Feedback field hint for an idea.
  ///
  /// In en, this message translates to:
  /// **'What would you like AirReply to do, and how would it help you?'**
  String get feedbackIdeaHint;

  /// Feedback validation.
  ///
  /// In en, this message translates to:
  /// **'Write a little more (at least 10 characters).'**
  String get feedbackTooShort;

  /// Feedback form switch.
  ///
  /// In en, this message translates to:
  /// **'Include device details'**
  String get feedbackIncludeDetails;

  /// What device details include.
  ///
  /// In en, this message translates to:
  /// **'System, device model, app language and role. Never your notifications or keys.'**
  String get feedbackDetailsSubtitle;

  /// After the form opened the email app.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your email app is ready: tap send there to finish.'**
  String get feedbackSent;

  /// The email app could not be opened.
  ///
  /// In en, this message translates to:
  /// **'No email app is set up on this device.'**
  String get feedbackNoEmailApp;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'hi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
