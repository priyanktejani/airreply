// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => 'Start';

  @override
  String get tabNotifications => 'Mitteilungen';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mitteilungen, $count ungelesen',
      one: 'Mitteilungen, 1 ungelesen',
      zero: 'Mitteilungen',
    );
    return '$_temp0';
  }

  @override
  String get tabDevices => 'Geräte';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ungelesen', zero: 'Alles gelesen');
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => 'Dein Handy,';

  @override
  String get welcomeHeadlineSecond => 'überall.';

  @override
  String get welcomeIntro =>
      'Lies die Mitteilungen deines Handys auf iPhone, iPad, Mac, PC oder im Browser und antworte direkt von dort auf Nachrichten.';

  @override
  String get welcomeEyebrow => 'Los geht\'s';

  @override
  String get welcomeQuestion => 'Wie möchtest du dieses Gerät nutzen?';

  @override
  String get roleShareTitle => 'Meine Mitteilungen teilen';

  @override
  String get roleShareDescription =>
      'Dieses Handy sendet seine Mitteilungen an deine anderen Geräte und verschickt die Antworten, die du dort schreibst.';

  @override
  String get roleShareUnavailable =>
      'Nur Android erlaubt Apps, Mitteilungen zu lesen. Nutze zum Teilen ein Android-Handy.';

  @override
  String get roleReceiveTitle => 'Hier ansehen und antworten';

  @override
  String get roleReceiveDescription =>
      'Sieh die Mitteilungen deines Handys auf diesem Gerät und beantworte Nachrichten, ohne es in die Hand zu nehmen.';

  @override
  String get errorOffline => 'Du scheinst offline zu sein. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get errorServerUnreachable => 'Die AirReply-Server sind nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get errorSignInRefused =>
      'Die Anmeldung wurde abgelehnt. Ist die anonyme Anmeldung im Firebase-Projekt aktiviert?';

  @override
  String get errorSignInFailed => 'Anmeldung fehlgeschlagen.';

  @override
  String get errorSyncFailed => 'Die Synchronisierung mit deinem gekoppelten Gerät ist fehlgeschlagen.';

  @override
  String get errorPairingCodeNotCreated => 'Es konnte kein Kopplungscode erstellt werden. Bitte versuche es erneut.';

  @override
  String get errorSessionNotConfirmable => 'Diese Sitzung kann nicht bestätigt werden.';

  @override
  String get errorCodeUnavailable =>
      'Dieser Code ist nicht mehr verfügbar. Erstelle auf dem anderen Handy einen neuen.';

  @override
  String get errorCannotPairWithItself => 'Ein Gerät kann nicht mit sich selbst gekoppelt werden.';

  @override
  String get errorCodeAlreadyUsed => 'Dieser Code wurde bereits verwendet.';

  @override
  String get errorNoDeviceJoined => 'Es ist noch kein Gerät beigetreten.';

  @override
  String get errorCodeFormat => 'Gib den 6-stelligen Code ein, der auf dem Handy angezeigt wird.';

  @override
  String get errorNotAPairingCode => 'Das ist kein AirReply-Kopplungscode.';

  @override
  String get errorCodeNotFound => 'Diesen Code gibt es nicht. Prüfe den Code auf dem anderen Handy.';

  @override
  String get errorCodeExpired => 'Dieser Code ist abgelaufen. Erstelle einen neuen.';

  @override
  String get errorQrMismatch =>
      'Der QR-Code passt nicht zu dieser Sitzung. Die Kopplung wurde zu deiner Sicherheit abgebrochen.';

  @override
  String get errorNotConfirmedYet => 'Das andere Handy hat noch nicht bestätigt.';

  @override
  String get errorPairingCancelledOnPhone => 'Die Kopplung wurde auf dem anderen Handy abgebrochen.';

  @override
  String get errorPairingCancelled =>
      'Die Kopplung wurde abgebrochen. Erstelle einen neuen Code, um es erneut zu versuchen.';

  @override
  String get errorPairingNotAvailable => 'Diese Kopplungssitzung ist für dieses Gerät nicht verfügbar.';

  @override
  String get errorPairingServerFailed => 'Der Server konnte die Kopplung nicht abschließen.';

  @override
  String get errorPairingOffInDemo => 'Im Demomodus ist die Kopplung deaktiviert.';

  @override
  String get errorNotPaired => 'Dieses Gerät ist noch nicht gekoppelt.';

  @override
  String get errorInvalidPeerKey => 'Das andere Gerät hat einen ungültigen Schlüssel gesendet.';

  @override
  String get errorUnsafePeerKey => 'Das andere Gerät hat einen unsicheren Schlüssel gesendet.';

  @override
  String get errorEncryptFailed => 'Die Mitteilung konnte nicht verschlüsselt werden.';

  @override
  String get errorDecryptFailed => 'Die Mitteilung konnte nicht entschlüsselt werden.';

  @override
  String get errorPayloadUnknown => 'Diese Mitteilung hat ein unbekanntes Format.';

  @override
  String get errorPayloadForeign =>
      'Diese Mitteilung wurde nicht mit dem Schlüssel dieser Kopplung erstellt oder wurde verändert.';

  @override
  String get errorNativeServiceFailed => 'Der Android-Mitteilungsdienst ist fehlgeschlagen.';

  @override
  String get errorNativeServiceUnavailable => 'Der Android-Mitteilungsdienst ist nicht verfügbar.';

  @override
  String get errorReplyEmpty => 'Schreib zuerst eine Antwort.';

  @override
  String get errorReplyTooLong => 'Diese Antwort ist zu lang.';

  @override
  String get errorReplyNotPossible => 'Auf diese Mitteilung kann nicht geantwortet werden.';

  @override
  String get errorReplyDismissed =>
      'Diese Mitteilung wurde auf deinem Handy geschlossen und kann nicht mehr beantwortet werden.';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count von $total gekoppelten Geräten waren nicht erreichbar.',
      one: '1 von $total gekoppelten Geräten war nicht erreichbar.',
    );
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message ($detail)';
  }

  @override
  String get errorUnknown => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorSharingAndroidOnly => 'Mitteilungen teilen ist nur auf Android verfügbar.';

  @override
  String get timeNow => 'jetzt';

  @override
  String timeMinutesShort(int n) {
    return '$n Min.';
  }

  @override
  String timeHoursShort(int n) {
    return '$n Std.';
  }

  @override
  String get timeToday => 'Heute';

  @override
  String get timeYesterday => 'Gestern';

  @override
  String timeAt(String day, String time) {
    return '$day um $time';
  }

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'vor $n Min.', one: 'vor 1 Min.');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'vor $n Std.', one: 'vor 1 Std.');
    return '$_temp0';
  }

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get searchHint => 'Suchen';

  @override
  String get searchClear => 'Suche löschen';

  @override
  String get splashFailed => 'AirReply konnte nicht starten';

  @override
  String get actionTryAgain => 'Erneut versuchen';

  @override
  String get splashStarting => 'AirReply startet';

  @override
  String get firebaseSetupEyebrow => 'Einrichtung erforderlich';

  @override
  String get firebaseSetupTitle => 'Firebase verbinden';

  @override
  String get firebaseSetupBody =>
      'AirReply synchronisiert deine Geräte über dein eigenes Firebase-Projekt. Führe dies im Projektordner aus und baue die App dann neu.';

  @override
  String get actionCopyCommand => 'Befehl kopieren';

  @override
  String get firebaseSetupDetails => 'Details';

  @override
  String get deviceConnected => 'Verbunden';

  @override
  String get deviceOffline => 'Offline';

  @override
  String get deviceConnecting => 'Verbindet';

  @override
  String get deviceNeedsAccess => 'Zugriff nötig';

  @override
  String get devicePaused => 'Pausiert';

  @override
  String get deviceNotReceiving => 'Empfängt nichts';

  @override
  String get deviceReceivingDetail => 'Neue Mitteilungen kommen sofort an.';

  @override
  String get deviceSharingDetail => 'Neue Mitteilungen werden geteilt, sobald sie eintreffen.';

  @override
  String get deviceOfflineDetail => 'Gespeicherte Mitteilungen werden angezeigt, bis dieses Gerät wieder online ist.';

  @override
  String get deviceConnectingDetail => 'Server wird erreicht…';

  @override
  String get deviceNeedsAccessDetail => 'Der Mitteilungszugriff ist aus, daher kann nichts geteilt werden.';

  @override
  String get devicePausedDetail => 'Teilen ist aus. Schalte es ein, um Mitteilungen zu senden.';

  @override
  String get deviceNotReceivingDetail => 'Android hat den Mitteilungs-Listener von AirReply beendet.';

  @override
  String get settingsAccessEyebrow => 'Zugriff';

  @override
  String get settingsPermissionsTitle => 'Berechtigungen';

  @override
  String get settingsPrivacyEyebrow => 'Datenschutz';

  @override
  String get settingsConnectionEyebrow => 'Verbindung';

  @override
  String get settingsSyncTitle => 'Synchronisierung';

  @override
  String get settingsAppearanceEyebrow => 'Darstellung';

  @override
  String get settingsAppearanceTitle => 'Darstellung und Bedienungshilfen';

  @override
  String get settingsDataTitle => 'Datenschutz und Daten';

  @override
  String get settingsHelpEyebrow => 'Hilfe';

  @override
  String get settingsHelpTitle => 'Hilfe und Info';

  @override
  String get permissionOn => 'An';

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get actionAllow => 'Erlauben';

  @override
  String get permissionAccessTitle => 'Mitteilungszugriff';

  @override
  String get permissionAccessSubtitle => 'Nötig, um Mitteilungen zu lesen und zu teilen';

  @override
  String get permissionStatusTitle => 'Statusmitteilung';

  @override
  String get permissionStatusSubtitle => 'Zeigt „Benachrichtigungs-Sync aktiv“ mit einer Pausieren-Taste';

  @override
  String get permissionBatteryTitle => 'Akkuoptimierung';

  @override
  String get permissionBatteryOk => 'Nicht eingeschränkt: Android pausiert das Teilen nicht';

  @override
  String get permissionBatteryFix => 'Auf „Nicht eingeschränkt“ stellen, damit Android das Teilen nie pausiert';

  @override
  String get permissionAlertsTitle => 'Hinweise';

  @override
  String get permissionAlertsBrowser => 'Lässt diesen Browser neue Mitteilungen anzeigen';

  @override
  String get loading => 'Wird geladen…';

  @override
  String get appsAllShared => 'Alle Apps werden geteilt';

  @override
  String get appsNoneShared => 'Keine Apps ausgewählt: Nichts wird geteilt';

  @override
  String get appsToShareTitle => 'Zu teilende Apps';

  @override
  String get appsMutedTitle => 'Stummgeschaltete Apps';

  @override
  String get encryptionTitle => 'Ende-zu-Ende-verschlüsselt';

  @override
  String get encryptionDetail =>
      'Jede Kopplung hat ihren eigenen Schlüssel, den die beiden Geräte untereinander vereinbaren (X25519). Mitteilungen und Antworten werden mit AES-256-GCM versiegelt. Der Verlauf bleibt auf deinen Geräten: Der Server leitet nur Geheimtext weiter und löscht jede Nachricht, sobald sie zugestellt ist.';

  @override
  String get shareNotificationsTitle => 'Mitteilungen teilen';

  @override
  String get shareNeedsAccess => 'Schalte zuerst den Mitteilungszugriff ein';

  @override
  String get alertTextTitle => 'Nachrichtentext in Hinweisen zeigen';

  @override
  String get alertTextSubtitle => 'Aus: Hinweise nennen nur die App, für Sperrbildschirme und geteilte Bildschirme';

  @override
  String get alertsBrowserTitle => 'Hinweise in diesem Browser';

  @override
  String get alertsComputerTitle => 'Hinweise auf diesem Computer';

  @override
  String get alertsWhileOpen =>
      'Neue Mitteilungen weisen dich hin, solange AirReply läuft. Lass es geöffnet (auf dem Mac läuft es weiter, wenn du das Fenster schließt).';

  @override
  String get syncNoDevices => 'Keine gekoppelten Geräte';

  @override
  String get syncStatusTitle => 'Sync-Status';

  @override
  String get syncChecking => 'Verbindung wird geprüft…';

  @override
  String get actionRefresh => 'Aktualisieren';

  @override
  String get listenerTitle => 'Mitteilungs-Listener';

  @override
  String get listenerSubtitle =>
      'Android bitten, den Listener von AirReply neu zu verbinden, wenn Geräte nichts mehr empfangen';

  @override
  String get actionReconnect => 'Neu verbinden';

  @override
  String get themeTitle => 'Design';

  @override
  String get themeSubtitle => 'System folgt diesem Gerät';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get hapticsTitle => 'Haptisches Feedback';

  @override
  String get hapticsSubtitle => 'Eine leichte Vibration beim Senden, Umschalten oder Bestätigen';

  @override
  String get textSizeTitle => 'Textgröße';

  @override
  String get textSizeSubtitle =>
      'AirReply folgt der Textgröße und dem fetten Text, die auf diesem Gerät eingestellt sind';

  @override
  String get removeAllConfirmTitle => 'Alle Geräte entfernen?';

  @override
  String get actionRemoveAll => 'Alle entfernen';

  @override
  String get markAllReadTitle => 'Alle als gelesen markieren';

  @override
  String get markedAllRead => 'Alle als gelesen markiert';

  @override
  String get removeAllTitle => 'Alle Geräte entfernen';

  @override
  String get removeAllSubtitle => 'Beendet jede Kopplung; ihr Verlauf bleibt unter Frühere Geräte';

  @override
  String get troubleshootingTitle => 'Fehlerbehebung';

  @override
  String get troubleshootingSubtitle => 'Was du prüfen kannst, wenn Mitteilungen oder Antworten nicht ankommen';

  @override
  String get diagnosticsTitle => 'Diagnose';

  @override
  String get diagnosticsSubtitle => 'Details zu Verbindung, Berechtigungen und Synchronisierung zum Prüfen oder Teilen';

  @override
  String get licencesTitle => 'Open-Source-Lizenzen';

  @override
  String get appTagline => 'Die Mitteilungen deines Handys, auf jedem Bildschirm.';

  @override
  String get syncSharing => 'Teilt';

  @override
  String get syncStarting => 'Startet';

  @override
  String get permissionAutostartTitle => 'Autostart';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return 'Auf $vendor-Handys nötig. Android kann das nicht melden, prüfe es daher dort.';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nur $count ausgewählte Apps',
      one: 'Nur 1 ausgewählte App',
    );
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stummgeschaltet: Sie kommen lautlos an',
      zero: 'Alle Apps dürfen dich hinweisen',
    );
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state. Jetzt live.';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state. Zuletzt synchronisiert $ago.';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state. $detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return 'Die Synchronisierung mit $name endet. Der Verlauf bleibt auf diesem Gerät unter Frühere Geräte und kommt zurück, wenn du es erneut koppelst.';
  }

  @override
  String removeAllConfirmMany(int count) {
    return 'Die Synchronisierung mit allen $count Geräten endet. Ihr Verlauf bleibt auf diesem Gerät unter Frühere Geräte und kommt zurück, wenn du sie erneut koppelst.';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesen',
      zero: 'Nichts ungelesen',
    );
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => 'Der Mitteilungszugriff ist aus';

  @override
  String get noticeAccessOffMessage => 'AirReply sieht keine neuen Mitteilungen, bis du ihn wieder einschaltest.';

  @override
  String get actionOpenSettings => 'Einstellungen öffnen';

  @override
  String get noticePausedTitle => 'Teilen ist pausiert';

  @override
  String get noticePausedMessage => 'Mitteilungen auf diesem Handy werden nicht an deine Geräte gesendet.';

  @override
  String get actionResumeSharing => 'Teilen fortsetzen';

  @override
  String get noticeNotReceivingTitle => 'Keine Mitteilungen empfangen';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android hat den Listener von AirReply beendet. Verbinde neu und schalte auf $vendor-Handys Autostart für AirReply ein, damit es nicht wieder passiert.';
  }

  @override
  String get noticeNotReceivingMessage =>
      'Android hat den Mitteilungs-Listener von AirReply beendet. Verbinde neu, um wieder zu starten.';

  @override
  String get noticeBatteryTitle => 'Akkuoptimierung ist an';

  @override
  String get noticeBatteryMessage =>
      'Android pausiert das Teilen möglicherweise, um Akku zu sparen. Stelle AirReply auf „Nicht eingeschränkt“.';

  @override
  String get actionBatterySettings => 'Akkueinstellungen';

  @override
  String get noticeAlertsOffTitle => 'Hinweise sind auf diesem Gerät aus';

  @override
  String get noticeAlertsOffMessage =>
      'Neue Mitteilungen erscheinen weiterhin hier, aber dieses Gerät weist dich nicht darauf hin.';

  @override
  String get actionAllowAlerts => 'Hinweise erlauben';

  @override
  String noticeOneOffline(String name) {
    return '$name ist offline';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count Geräte sind offline';
  }

  @override
  String get noticeOfflineMessage =>
      'Gespeicherte Mitteilungen werden angezeigt. Neue kommen an, sobald dieses Gerät wieder online ist.';

  @override
  String get actionRetry => 'Wiederholen';

  @override
  String get setupTitle => 'Einrichten';

  @override
  String get disclosureEyebrow => 'Bevor du beginnst';

  @override
  String get disclosureTitle => 'AirReply braucht Zugriff auf deine Mitteilungen';

  @override
  String get disclosureIntro =>
      'Um die Mitteilungen dieses Handys mit deinen gekoppelten Geräten zu teilen, nutzt AirReply die Android-Berechtigung für den Mitteilungszugriff.';

  @override
  String get disclosureWhatTitle => 'Worauf zugegriffen wird';

  @override
  String get disclosureWhatBody =>
      'Die auf diesem Handy angezeigten Mitteilungen: App-Name, Titel, Text, Uhrzeit und die Antwortaktion von Messenger-Apps. Das funktioniert im Hintergrund, auch wenn AirReply geschlossen ist.';

  @override
  String get disclosureWhyTitle => 'Warum';

  @override
  String get disclosureWhyBody =>
      'Nur, um diese Mitteilungen auf den Geräten anzuzeigen, die du koppelst, und um die Antworten, die du dort schreibst, über die ursprüngliche App auf diesem Handy zu senden.';

  @override
  String get disclosureHowTitle => 'Wie es geschützt ist';

  @override
  String get disclosureHowBody =>
      'Jede Mitteilung wird auf diesem Handy mit AES-256-GCM verschlüsselt, mit einem Schlüssel, den nur dieses Handy und das gekoppelte Gerät besitzen. Unsere Server leiten Geheimtext weiter, den sie nicht lesen können, und löschen ihn nach der Zustellung: Der Verlauf liegt nur auf deinen Geräten.';

  @override
  String get disclosureControlTitle => 'Du behältst die Kontrolle';

  @override
  String get disclosureControlBody =>
      'Wähle, welche Apps geteilt werden, pausiere jederzeit über die Statusmitteilung oder entferne ein Gerät, um das Teilen zu beenden; seinen Verlauf löschst du, wann du willst. Mitteilungsinhalte werden nie verkauft, an Dritte weitergegeben oder für Werbung oder Analysen genutzt.';

  @override
  String get actionAgreeAndContinue => 'Zustimmen und weiter';

  @override
  String get actionNoThanks => 'Nein, danke';

  @override
  String setupProgress(int done, int total) {
    return '$done von $total erforderlichen Schritten erledigt';
  }

  @override
  String get setupPhoneTitle => 'Dieses Handy einrichten';

  @override
  String get setupPhoneSubtitle =>
      'Zwei Berechtigungen lassen AirReply Mitteilungen teilen und im Hintergrund weiterlaufen.';

  @override
  String get setupAccessSubtitle => 'Erforderlich. Suche AirReply in der Liste und schalte es ein.';

  @override
  String get setupStatusSubtitle =>
      'Zeigt „Benachrichtigungs-Sync aktiv“ mit einer Pausieren-Taste, solange geteilt wird.';

  @override
  String setupAutostartSubtitle(String vendor) {
    return 'Auf $vendor erforderlich. Ohne Autostart hindert das Handy AirReply am Mithören, sobald die App geschlossen ist. Suche AirReply und schalte Autostart ein.';
  }

  @override
  String get setupBatterySubtitle =>
      'Empfohlen. Stelle AirReply auf „Nicht eingeschränkt“, damit Android das Teilen nie pausiert.';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get setupNeedsAccess => 'Schalte den Mitteilungszugriff ein, um fortzufahren';

  @override
  String get stepDone => 'Erledigt';

  @override
  String get pairADevice => 'Gerät koppeln';

  @override
  String get pairTitle => 'Koppeln';

  @override
  String get pairAddADevice => 'Gerät hinzufügen';

  @override
  String pairPairedWith(String name) {
    return 'Gekoppelt mit $name';
  }

  @override
  String pairStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get pairStopped => 'Kopplung beendet';

  @override
  String get actionMakeNewCode => 'Neuen Code erstellen';

  @override
  String get pairShowCodeIntro =>
      'Öffne auf deinem iPhone, iPad, Mac, PC, Browser oder einem anderen Android AirReply, wähle „Hier ansehen und antworten“ und scanne dann diesen Code oder gib die Ziffern ein.';

  @override
  String get pairQrLabel => 'Kopplungs-QR-Code';

  @override
  String get pairOrTypeCode => 'ODER DIESEN CODE EINGEBEN';

  @override
  String pairCodeCopied(String code) {
    return 'Code $code kopiert';
  }

  @override
  String get actionCopyCode => 'Code kopieren';

  @override
  String get actionNewCode => 'Neuer Code';

  @override
  String get pairCodesMatchQuestion => 'Stimmen die Codes überein?';

  @override
  String pairVerifyWarning(String name) {
    return '$name möchte sich koppeln. Es muss genau diesen Code anzeigen. Wenn nicht, versucht möglicherweise jemand anderes, sich zu verbinden.';
  }

  @override
  String get actionCodesMatch => 'Codes stimmen, koppeln';

  @override
  String get actionCodesDoNotMatch => 'Sie stimmen nicht überein';

  @override
  String get pairAddAnotherPhone => 'Weiteres Handy hinzufügen';

  @override
  String get pairWithYourPhone => 'Mit deinem Handy koppeln';

  @override
  String get pairEnterCodeIntro =>
      'Öffne auf dem Android-Handy, das du hier sehen möchtest, AirReply und wähle „Meine Mitteilungen teilen“ (oder „Gerät hinzufügen“, wenn es bereits teilt). Es zeigt einen QR-Code und sechs Ziffern.';

  @override
  String get pairMethodScan => 'Scannen';

  @override
  String get pairMethodType => 'Code eingeben';

  @override
  String get pairCodeLabel => 'KOPPLUNGSCODE';

  @override
  String get pairStartsOnLastDigit => 'Die Kopplung beginnt, sobald du die letzte Ziffer eingibst.';

  @override
  String get pairConnecting => 'Verbindet…';

  @override
  String get pairPointCamera => 'Richte die Kamera auf den QR-Code auf deinem Handy.';

  @override
  String get cameraDenied =>
      'AirReply braucht die Kamera zum Scannen. Erlaube sie in den Einstellungen deines Handys oder gib stattdessen den Code ein.';

  @override
  String get cameraNotStarted => 'Die Kamera ist nicht gestartet.';

  @override
  String pairConfirmOn(String name) {
    return 'Auf $name bestätigen';
  }

  @override
  String get pairConfirmHint => 'Prüfe, ob dein Handy denselben Code zeigt, und tippe dort auf „Codes stimmen“.';

  @override
  String get pairWaitingForPhone => 'Warte auf dein Handy…';

  @override
  String get pairCodeExpired => 'Code abgelaufen, neuer wird erstellt';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return 'Läuft ab in $minutes:$seconds';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return 'Schritt $current von $total: $name';
  }

  @override
  String get pairCouldNotPair => 'Kopplung fehlgeschlagen';

  @override
  String get stepShowCode => 'Code zeigen';

  @override
  String get stepVerify => 'Prüfen';

  @override
  String get stepEnterCode => 'Code eingeben';

  @override
  String get notYet => 'Noch nicht';

  @override
  String get factStatus => 'Status';

  @override
  String get factLive => 'Live';

  @override
  String get factLastSynced => 'Zuletzt synchronisiert';

  @override
  String get factNow => 'Jetzt';

  @override
  String get lastShared => 'Zuletzt geteilt';

  @override
  String get lastNotification => 'Letzte Mitteilung';

  @override
  String get factPaired => 'Gekoppelt';

  @override
  String get factEncryption => 'Verschlüsselung';

  @override
  String get factEncryptionValue => 'Ende-zu-Ende, AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String removeDeviceMessage(String name) {
    return 'Die Synchronisierung mit $name endet auf beiden Geräten. Der Verlauf bleibt auf diesem Gerät unter Geräte → Frühere Geräte, bis du ihn löschst. Andere Geräte sind nicht betroffen.';
  }

  @override
  String get actionRemove => 'Entfernen';

  @override
  String deviceRemoved(String name) {
    return '$name entfernt';
  }

  @override
  String get actionTurnOnAccess => 'Mitteilungszugriff einschalten';

  @override
  String get browseShared => 'Durchsuchen, was du geteilt hast';

  @override
  String get browseHistory => 'Mitteilungsverlauf durchsuchen';

  @override
  String get actionRemoveDevice => 'Gerät entfernen';

  @override
  String get addAPhone => 'Handy hinzufügen';

  @override
  String factWithTime(String label, String time) {
    return '$label: $time';
  }

  @override
  String pairedAgo(String time) {
    return 'Gekoppelt: $time';
  }

  @override
  String devicesPaired(int count) {
    return '$count gekoppelt';
  }

  @override
  String get devicesIntroSender => 'Dieses Handy teilt seine Mitteilungen mit diesen Geräten.';

  @override
  String get devicesIntroReceiver => 'Dieses Gerät zeigt Mitteilungen von diesen Handys.';

  @override
  String get devicesNone => 'Keine Geräte';

  @override
  String get devicesNoneHint => 'Kopple ein Gerät, um zu beginnen.';

  @override
  String get helpNotArrivingQ => 'Mitteilungen kommen nicht an';

  @override
  String get helpNotArrivingA =>
      'Öffne auf dem Handy AirReply und prüfe, ob „Mitteilungen teilen“ an ist und die App im Hintergrund laufen darf. Beide Geräte brauchen eine Internetverbindung. Versuche es dann hier erneut.';

  @override
  String get actionRetrySync => 'Sync wiederholen';

  @override
  String get helpNoAlertsQ => 'Keine Hinweise auf diesem Gerät';

  @override
  String get helpNoAlertsA =>
      'Neue Mitteilungen kommen immer im Tab „Mitteilungen“ an. Um auch hingewiesen zu werden, erlaube Mitteilungen für AirReply und prüfe, ob die App unter Einstellungen → Stummgeschaltete Apps stummgeschaltet ist.';

  @override
  String get helpExpiredQ => 'Eine Antwort zeigt „Auf dem Handy abgelaufen“';

  @override
  String get helpExpiredA =>
      'Antworten werden über die Mitteilung auf dem Handy gesendet. Sobald sie dort geschlossen oder von der App ersetzt wurde, kann sie nicht mehr beantwortet werden. Antworte auf eine neuere Mitteilung oder direkt auf dem Handy.';

  @override
  String get helpNotReceivingQ => 'Geräte empfangen keine Mitteilungen';

  @override
  String get helpNotReceivingA =>
      'Prüfe, ob der Mitteilungszugriff an ist und das Teilen nicht pausiert ist. Wenn Android den Listener von AirReply beendet hat, verbinde ihn neu.';

  @override
  String get actionReconnectListener => 'Listener neu verbinden';

  @override
  String get helpStopsQ => 'Das Teilen hört nach einer Weile auf';

  @override
  String helpStopsAutostartA(String vendor) {
    return 'Schalte auf $vendor-Handys Autostart für AirReply ein und stelle die Akkunutzung auf „Nicht eingeschränkt“, sonst beendet das Handy es im Hintergrund.';
  }

  @override
  String get helpStopsA =>
      'Stelle die Akkunutzung von AirReply auf „Nicht eingeschränkt“, damit Android es im Hintergrund nicht pausiert.';

  @override
  String get helpRepliesQ => 'Antworten werden nicht zugestellt';

  @override
  String get helpRepliesA =>
      'Eine Antwort wird über die Mitteilung gesendet, auf die sie antwortet. Diese Mitteilung muss also noch in der Statusleiste dieses Handys sein. Messenger-Apps, die in ihren Mitteilungen „Antworten“ anbieten, funktionieren am besten.';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historySharedWithIt => 'Damit geteilt';

  @override
  String get emptyNothingYet => 'Noch nichts hier';

  @override
  String historyEmptySender(String name) {
    return 'Mitteilungen, die dieses Handy mit $name teilt, erscheinen hier.';
  }

  @override
  String historyEmptyReceiver(String name) {
    return 'Mitteilungen von $name erscheinen hier.';
  }

  @override
  String get thisPhone => 'diesem Handy';

  @override
  String get itDevice => 'diesem Gerät';

  @override
  String get homeHeadlineSender => 'geteilt.';

  @override
  String get homeIntroSender =>
      'Mitteilungen von diesem Handy erreichen deine anderen Geräte, und ihre Antworten kommen zurück.';

  @override
  String get homeIntroReceiver =>
      'Die Mitteilungen deines Handys kommen hier an. Lies sie und antworte, ohne es in die Hand zu nehmen.';

  @override
  String get searchNotificationsHint => 'Mitteilungen durchsuchen';

  @override
  String get homeTodayEyebrow => 'Heute';

  @override
  String get homeGlanceTitle => 'Auf einen Blick';

  @override
  String get homeRecentEyebrow => 'Letzte Aktivität';

  @override
  String get homeLatestTitle => 'Neueste Mitteilungen';

  @override
  String get actionSeeAll => 'Alle ansehen';

  @override
  String get homeRecentEmptySender => 'Noch nichts geteilt. Neue Mitteilungen auf diesem Handy erscheinen hier.';

  @override
  String get homeRecentEmptyReceiver => 'Noch nichts da. Neue Mitteilungen von deinem Handy erscheinen hier.';

  @override
  String get homeRecentFailed => 'Die letzten Mitteilungen konnten nicht geladen werden.';

  @override
  String get homeSharingEyebrow => 'Teilen';

  @override
  String get homeThisPhoneTitle => 'Dieses Handy';

  @override
  String get howItWorksEyebrow => 'So funktioniert\'s';

  @override
  String get howItWorksSenderTitle => 'Einmal teilen. Überall antworten.';

  @override
  String get howItWorksReceiverTitle => 'Drei Schritte. Jeder Bildschirm.';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mitteilungen, $count ungelesen',
      zero: 'Mitteilungen',
    );
    return '$_temp0';
  }

  @override
  String get statToday => 'Heute';

  @override
  String get statUnread => 'Ungelesen';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Geräte', one: 'Gerät');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Keine Treffer';

  @override
  String searchNoMatchesDetail(String query) {
    return 'Keine Mitteilung und kein Gerät enthält „$query“.';
  }

  @override
  String get searchEyebrow => 'Suche';

  @override
  String get stepShareTitle => 'Von deinem Handy teilen';

  @override
  String get stepShareText =>
      'Auf deinem Android-Handy sendet AirReply jede Mitteilung Ende-zu-Ende-verschlüsselt hierher.';

  @override
  String get stepReadTitle => 'Hier lesen';

  @override
  String get stepReadText => 'Mitteilungen kommen innerhalb von Sekunden an, nach App und Person gruppiert.';

  @override
  String get stepReplyTitle => 'Von überall antworten';

  @override
  String get stepReplyText => 'Schreib hier eine Antwort; dein Handy sendet sie über die App, aus der sie kam.';

  @override
  String get stepPickTitle => 'Wähle, was geteilt wird';

  @override
  String get stepPickText => 'Alle Apps oder nur die, die du auf deinen anderen Geräten sehen möchtest.';

  @override
  String get stepPairTitle => 'Kopple deine Geräte';

  @override
  String get stepPairText => 'Ein Mac, PC, iPhone, iPad oder Browser scannt einmal einen Code und bleibt gekoppelt.';

  @override
  String get stepReplySenderText =>
      'Dort geschriebene Antworten werden von diesem Handy über die zugehörige App gesendet.';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählte Apps',
      one: '1 ausgewählte App',
    );
    return '$_temp0';
  }

  @override
  String get actionChooseApps => 'Apps wählen →';

  @override
  String get pairDeviceKinds => 'iPhone, iPad, Mac, PC, Browser oder Android';

  @override
  String get actionPairArrow => 'Koppeln →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Handys', one: '1 Handy');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Geräte', one: '1 Gerät');
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return 'Empfängt von $names.';
  }

  @override
  String statusConnectingTo(String names) {
    return 'Verbindet mit $names…';
  }

  @override
  String statusShowingSaved(String names) {
    return 'Gespeicherte Mitteilungen von $names werden angezeigt.';
  }

  @override
  String get statusLive => 'Live. Neue Mitteilungen erscheinen innerhalb von Sekunden.';

  @override
  String statusLastSynced(String ago) {
    return 'Zuletzt synchronisiert $ago.';
  }

  @override
  String get statusNeedsAccess => 'Zum Teilen ist Mitteilungszugriff nötig.';

  @override
  String get statusPaused => 'Teilen ist pausiert.';

  @override
  String statusSharingWith(String names) {
    return 'Teilt mit $names.';
  }

  @override
  String get statusNotWorking => 'Das Teilen funktioniert gerade nicht.';

  @override
  String get statusEncryptedDetail =>
      'Mitteilungen werden auf diesem Handy Ende-zu-Ende verschlüsselt, bevor sie es verlassen.';

  @override
  String get statusOffDetail => 'Nichts von diesem Handy erreicht deine Geräte, bis das Teilen eingeschaltet ist.';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get periodAnyTime => 'Beliebige Zeit';

  @override
  String get periodToday => 'Heute';

  @override
  String get periodWeek => 'Letzte 7 Tage';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Mitteilungen', one: '1 Mitteilung');
    return '$_temp0';
  }

  @override
  String conversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Unterhaltungen',
      one: '1 Unterhaltung',
    );
    return '$_temp0';
  }

  @override
  String messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Nachrichten', one: '1 Nachricht');
    return '$_temp0';
  }

  @override
  String newNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Mitteilungen',
      one: '1 neue Mitteilung',
    );
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label, $count ungelesen';
  }

  @override
  String get nothingHereNow => 'Gerade nichts hier';

  @override
  String get goneDetail =>
      'Diese Mitteilungen wurden ausgeblendet, entfernt oder stammen von einem Gerät, das nicht mehr gekoppelt ist.';

  @override
  String get actionBackToNotifications => 'Zurück zu den Mitteilungen';

  @override
  String get searchConversationsHint => 'Namen, Nummern und Nachrichten suchen';

  @override
  String get conversationsEyebrow => 'Unterhaltungen';

  @override
  String conversationsEyebrowCount(int count) {
    return 'Unterhaltungen · $count';
  }

  @override
  String get peopleAndGroups => 'Personen und Gruppen';

  @override
  String otherNotificationsCount(int count) {
    return 'Weitere Mitteilungen · $count';
  }

  @override
  String fromApp(String app) {
    return 'Von $app';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'Nichts passt zu „$query“.';
  }

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get notificationGoneDetail =>
      'Diese Mitteilung wurde entfernt, ausgeblendet oder gehört zu einem Gerät, das nicht mehr gekoppelt ist.';

  @override
  String get markAsUnread => 'Als ungelesen markieren';

  @override
  String get markAsRead => 'Als gelesen markieren';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get you => 'Du';

  @override
  String youSaid(String text) {
    return 'Du: $text';
  }

  @override
  String get sentFromPhone => 'Von deinem Handy gesendet';

  @override
  String get clearedOnPhone => 'Auf dem Handy entfernt';

  @override
  String get canReply => 'Antworten möglich';

  @override
  String get canBeAnswered => 'Kann beantwortet werden';

  @override
  String get noRepliesInApp => 'Keine Antworten in dieser App';

  @override
  String get replySending => 'Wird gesendet';

  @override
  String get replyDelivered => 'Zugestellt';

  @override
  String get replySent => 'Gesendet';

  @override
  String get replyExpired => 'Auf dem Handy abgelaufen';

  @override
  String get replyNotDelivered => 'Nicht zugestellt';

  @override
  String get replySendingPrefixed => 'Antwort wird gesendet';

  @override
  String get replyDeliveredPrefixed => 'Antwort zugestellt';

  @override
  String get replySentPrefixed => 'Antwort gesendet';

  @override
  String get replyExpiredPrefixed => 'Antwort auf dem Handy abgelaufen';

  @override
  String get replyNotDeliveredPrefixed => 'Antwort nicht zugestellt';

  @override
  String get yourReply => 'Deine Antwort';

  @override
  String yourReplyAsShown(String app) {
    return 'Deine Antwort, wie $app sie zeigt';
  }

  @override
  String get allMarkedRead => 'Alle als gelesen markiert';

  @override
  String sharedWith(String name) {
    return 'Geteilt mit $name';
  }

  @override
  String sharedWithDevices(int count) {
    return 'Geteilt mit $count Geräten';
  }

  @override
  String fromDevice(String name) {
    return 'Von $name';
  }

  @override
  String fromPhones(int count) {
    return 'Von $count Handys';
  }

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Filter, $count aktiv', zero: 'Filter');
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => 'Nichts passt zu dieser Suche oder diesem Filter.';

  @override
  String get actionClearSearchAndFilters => 'Suche und Filter löschen';

  @override
  String get allCaughtUp => 'Alles erledigt';

  @override
  String get inboxEmptySender =>
      'Mitteilungen, die dieses Handy teilt, erscheinen hier, zusammen mit den Antworten von deinen Geräten.';

  @override
  String get inboxEmptyReceiver => 'Mitteilungen von deinem Handy erscheinen hier, sobald sie eintreffen.';

  @override
  String get notificationsLoadFailed => 'Mitteilungen konnten nicht geladen werden';

  @override
  String get removeFilter => 'Filter entfernen';

  @override
  String get filterUnread => 'Ungelesen';

  @override
  String get device => 'Gerät';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared =>
      'Diese Mitteilungen wurden auf deinem Handy entfernt und können von hier nicht mehr beantwortet werden.';

  @override
  String footnoteNoReplies(String app) {
    return '$app nimmt für diese Unterhaltung keine Antworten an.';
  }

  @override
  String get unknownSender => 'Unbekannter Absender';

  @override
  String get dividerNew => 'Neu';

  @override
  String get copied => 'Kopiert';

  @override
  String get dismissedOnPhone => 'Auf dem Handy geschlossen';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get hideConversations => 'Unterhaltungen ausblenden';

  @override
  String get showConversations => 'Unterhaltungen anzeigen';

  @override
  String unmuteApp(String app) {
    return 'Hinweise von $app einschalten';
  }

  @override
  String muteApp(String app) {
    return 'Hinweise von $app stummschalten';
  }

  @override
  String get threadChat => 'Chat';

  @override
  String get threadGroup => 'Gruppe';

  @override
  String get threadNotification => 'Mitteilung';

  @override
  String get replyHint => 'Antworten';

  @override
  String replyToHint(String name) {
    return '$name antworten';
  }

  @override
  String get sendWithEnter => 'Senden (Eingabe)';

  @override
  String get actionSend => 'Senden';

  @override
  String get filterTitle => 'Filter';

  @override
  String get actionClearAll => 'Alle löschen';

  @override
  String get filterShow => 'Anzeigen';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnreadOnly => 'Nur ungelesene';

  @override
  String get filterWhen => 'Wann';

  @override
  String get filterSharedWith => 'Geteilt mit';

  @override
  String get filterPhone => 'Handy';

  @override
  String get filterApp => 'App';

  @override
  String get filterAllApps => 'Alle Apps';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitteilungen anzeigen',
      one: '1 Mitteilung anzeigen',
    );
    return '$_temp0';
  }

  @override
  String get actionShowMore => 'Mehr anzeigen';

  @override
  String get browseSharedWithIt => 'Durchsuchen, was du damit geteilt hast';

  @override
  String get browseItsHistory => 'Seinen Mitteilungsverlauf durchsuchen';

  @override
  String get swipeUnread => 'Ungelesen';

  @override
  String get swipeRead => 'Gelesen';

  @override
  String get diagnosticsIntro => 'Nichts hiervon enthält Mitteilungstext oder Verschlüsselungsschlüssel.';

  @override
  String get reportCopied => 'Bericht kopiert';

  @override
  String get actionCopyReport => 'Bericht kopieren';

  @override
  String get checkingAgain => 'Wird erneut geprüft…';

  @override
  String get actionCheckAgain => 'Erneut prüfen';

  @override
  String get diagnosticsReportNote => 'Der Bericht selbst bleibt auf Englisch, damit ihn lesen kann, wer dir hilft.';

  @override
  String get welcomeEncryption =>
      'Ende-zu-Ende-verschlüsselt mit einem Schlüssel, den nur deine Geräte besitzen. Der Server leitet Geheimtext weiter, den er nicht lesen kann.';

  @override
  String get theOtherDevice => 'Das andere Gerät';

  @override
  String get appsShareIntro => 'Wähle, was deine Geräte erreicht. Das gilt auch, wenn AirReply geschlossen ist.';

  @override
  String get appsOnlySelected => 'Nur ausgewählte';

  @override
  String get searchApps => 'Apps suchen';

  @override
  String get appsNothingSelected => 'Nichts ausgewählt: Keine Mitteilungen werden geteilt';

  @override
  String appsSelected(int count) {
    return '$count ausgewählt';
  }

  @override
  String get appsOnlySelectedHint => 'Wähle „Nur ausgewählte“, um festzulegen, welche Apps deine Geräte erreichen.';

  @override
  String get appsChoiceLoadFailed => 'Deine Auswahl konnte nicht geladen werden';

  @override
  String get appsMutedIntro =>
      'Stummgeschaltete Apps kommen weiterhin unter Mitteilungen an, weisen dich auf diesem Gerät aber nie hin.';

  @override
  String get appsNoneYet => 'Noch keine Apps';

  @override
  String get appsNoneYetHint => 'Apps erscheinen hier, sobald dein Handy eine Mitteilung von ihnen gesendet hat.';

  @override
  String get appMuted => 'Stumm';

  @override
  String get appAlertsOn => 'Hinweise an';

  @override
  String get appsNoMatch => 'Keine passenden Apps';

  @override
  String get appsListFailed => 'Apps konnten nicht aufgelistet werden';

  @override
  String get appsReading => 'Installierte Apps werden gelesen…';

  @override
  String get alertChannelName => 'Andere Benachrichtigungen';

  @override
  String get alertChannelDescription => 'Von deinem gekoppelten Handy gespiegelte Mitteilungen';

  @override
  String get alertReply => 'Antworten';

  @override
  String get alertReplyHint => 'Antworten…';

  @override
  String get alertOpenApp => 'AirReply öffnen';

  @override
  String get alertNewNotification => 'Neue Mitteilung';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSystem => 'Wie dieses Gerät';

  @override
  String languageSystemCurrent(String language) {
    return 'Wie dieses Gerät ($language)';
  }

  @override
  String get previousDevicesTitle => 'Frühere Geräte';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entfernte Geräte, Verlauf behalten',
      one: '1 entferntes Gerät, Verlauf behalten',
      zero: 'Der Verlauf entfernter Geräte bleibt hier',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro =>
      'Wenn du ein Gerät entfernst, bleibt sein Verlauf auf diesem Gerät. Kopple dasselbe Gerät erneut, um dort weiterzumachen, wo du aufgehört hast, oder lösche den Verlauf hier.';

  @override
  String get previousDevicesNone => 'Keine früheren Geräte';

  @override
  String get previousDevicesNoneHint => 'Der Verlauf von Geräten, die du entfernst, erscheint hier.';

  @override
  String previousDeviceSummary(String date, String count) {
    return 'Entfernt: $date · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return 'Entfernt: $date';
  }

  @override
  String previousDeviceContinue(String name) {
    return 'Kopple $name erneut, um diesen Verlauf in deinen Mitteilungen fortzusetzen.';
  }

  @override
  String get actionDeleteHistory => 'Verlauf löschen';

  @override
  String deleteHistoryTitle(String name) {
    return 'Verlauf von $name löschen?';
  }

  @override
  String get deleteHistoryMessage =>
      'Seine Mitteilungen und Antworten werden von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String historyDeleted(String name) {
    return 'Verlauf von $name gelöscht';
  }

  @override
  String get actionDeleteAll => 'Alle löschen';

  @override
  String get deleteAllHistoryTitle => 'Gesamten früheren Verlauf löschen?';

  @override
  String get deleteAllHistoryMessage =>
      'Der Verlauf aller entfernten Geräte wird von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get allHistoryDeleted => 'Früherer Verlauf gelöscht';

  @override
  String get feedbackReportTitle => 'Problem melden';

  @override
  String get feedbackReportSubtitle => 'Funktioniert etwas nicht? Erzähl uns, was passiert ist';

  @override
  String get feedbackIdeaTitle => 'Funktion vorschlagen';

  @override
  String get feedbackIdeaSubtitle => 'Eine Idee, die AirReply besser macht';

  @override
  String get feedbackKindLabel => 'Art';

  @override
  String get feedbackKindProblem => 'Problem';

  @override
  String get feedbackKindIdea => 'Funktionsidee';

  @override
  String get feedbackAreaLabel => 'Worum geht es?';

  @override
  String get feedbackAreaNotifications => 'Mitteilungen';

  @override
  String get feedbackAreaReplies => 'Antworten';

  @override
  String get feedbackAreaPairing => 'Kopplung';

  @override
  String get feedbackAreaAlerts => 'Hinweise';

  @override
  String get feedbackAreaSync => 'Synchronisierung';

  @override
  String get feedbackAreaDesign => 'Aussehen';

  @override
  String get feedbackAreaOther => 'Etwas anderes';

  @override
  String get feedbackMessageLabel => 'Deine Nachricht';

  @override
  String get feedbackProblemHint =>
      'Was ist passiert, und was hast du erwartet? Schritte, um es nachzustellen, helfen sehr.';

  @override
  String get feedbackIdeaHint => 'Was soll AirReply können, und wie würde dir das helfen?';

  @override
  String get feedbackTooShort => 'Schreib etwas mehr (mindestens 10 Zeichen).';

  @override
  String get feedbackIncludeDetails => 'Gerätedetails mitsenden';

  @override
  String get feedbackDetailsSubtitle =>
      'System, Gerätemodell, App-Sprache und Rolle. Nie deine Mitteilungen oder Schlüssel.';

  @override
  String get feedbackSent => 'Danke! Deine E-Mail-App ist bereit: Tippe dort auf Senden, um fertig zu werden.';

  @override
  String get feedbackNoEmailApp => 'Auf diesem Gerät ist keine E-Mail-App eingerichtet.';

  @override
  String get alertChannelPopUp => 'Nachrichten';

  @override
  String get alertChannelSilent => 'Lautlose Mitteilungen';

  @override
  String get alertStatusChannelName => 'Antwortstatus';

  @override
  String get alertStatusChannelDescription =>
      'Sagt dir, wenn eine in einer Mitteilung geschriebene Antwort nicht gesendet werden konnte';

  @override
  String alertReplyNotSent(String name) {
    return 'Antwort an $name nicht gesendet';
  }

  @override
  String get alertStyleTest => 'Testhinweis senden';

  @override
  String get alertStyleTestTitle => 'AirReply';

  @override
  String get alertStyleTestText => 'So weist dich eine Nachricht hin.';

  @override
  String pairFinishingOn(String name) {
    return 'Wird auf $name abgeschlossen…';
  }

  @override
  String pairFinishingHint(String name) {
    return 'Lass AirReply auf $name geöffnet. Die Kopplung ist fertig, sobald beide Geräte sie gespeichert haben.';
  }

  @override
  String pairUnconfirmedTitle(String name) {
    return '$name hat die Kopplung nicht abgeschlossen';
  }

  @override
  String pairUnconfirmedHint(String name) {
    return 'Prüfe, ob AirReply auf $name geöffnet und online ist. Wenn dort die Kopplung schon als fertig angezeigt wird, mach weiter.';
  }

  @override
  String get actionKeepWaiting => 'Weiter warten';

  @override
  String get actionPairedThere => 'Dort ist es gekoppelt';

  @override
  String get actionCancelPairing => 'Kopplung abbrechen';

  @override
  String get setupAssistantTitle => 'Einrichtungsassistent';

  @override
  String setupAssistantProgress(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String get setupAssistantIntroTitle => 'AirReply am Laufen halten';

  @override
  String get setupAssistantIntro =>
      'Alles, was dieses Gerät braucht, um Mitteilungen zuverlässig zu teilen oder anzuzeigen, auch im Hintergrund. Es aktualisiert sich, wenn du Einstellungen änderst.';

  @override
  String get setupNeeded => 'Erforderlich';

  @override
  String get setupRecommended => 'Empfohlen';

  @override
  String get setupAllDone => 'Alles bereit';

  @override
  String get setupAllDoneHint => 'Alles ist eingerichtet. AirReply läuft im Hintergrund weiter.';

  @override
  String get setupCardTitle => 'Einrichtung abschließen';

  @override
  String get actionNotNow => 'Nicht jetzt';

  @override
  String get actionTurnOn => 'Einschalten';

  @override
  String get actionAutostartDone => 'Ich habe es eingeschaltet';

  @override
  String get taskAccessText =>
      'Erlaubt AirReply, die Mitteilungen zu lesen, die es teilt. Suche AirReply in der Liste und schalte es ein.';

  @override
  String get taskSharingText => 'Teilen ist aus, daher erreicht nichts deine Geräte.';

  @override
  String get taskListenerText =>
      'Android hat den Mitteilungs-Listener von AirReply beendet. Verbinde ihn neu, um wieder zu empfangen.';

  @override
  String get taskBackgroundTitle => 'Hintergrundaktivität';

  @override
  String get taskBackgroundText =>
      '„Hintergrundnutzung einschränken“ ist für AirReply an, daher beendet Android das Teilen kurz nachdem der Bildschirm ausgeht. Öffne in den Einstellungen von AirReply Akku und wähle Nicht eingeschränkt.';

  @override
  String get taskBatterySamsung =>
      'Füge AirReply auf Samsung auch zu den Nie-Standby-Apps hinzu: Einstellungen → Akku → Limits für Hintergrundnutzung.';

  @override
  String get taskAutostartXiaomi =>
      'Öffne Sicherheit → Berechtigungen → Autostart und schalte AirReply ein. Ohne das stoppt das Handy AirReply, sobald die App geschlossen ist.';

  @override
  String get taskAutostartOppo =>
      'Öffne Einstellungen → Akku → App-Akkuverwaltung, wähle AirReply und erlaube automatisches Starten und Ausführen im Hintergrund.';

  @override
  String get taskAutostartVivo => 'Öffne i Manager → App-Manager → Autostart und schalte AirReply ein.';

  @override
  String get taskAutostartHuawei =>
      'Öffne Telefonmanager → App-Start, suche AirReply, wähle Manuell verwalten und schalte alle drei Schalter ein.';

  @override
  String get taskAlertsText =>
      'Erlaubt diesem Gerät, dich auf neue Mitteilungen hinzuweisen. Ohne das erscheinen Mitteilungen trotzdem in der App.';

  @override
  String get taskPairSender => 'Kopple ein Gerät, mit dem dieses Handy seine Mitteilungen teilt.';

  @override
  String get taskPairReceiver => 'Kopple das Handy, dessen Mitteilungen du hier sehen möchtest.';

  @override
  String get eraseEverythingTitle => 'Alles löschen';

  @override
  String get eraseEverythingSubtitle =>
      'Entfernt alle Geräte, den Verlauf, Schlüssel und Einstellungen von diesem Gerät und sein Konto vom Server';

  @override
  String get eraseEverythingConfirmTitle => 'Alles löschen?';

  @override
  String get eraseEverythingConfirmMessage =>
      'Alle Geräte werden entfernt, der gesamte Verlauf (auch der behaltene) wird gelöscht und AirReply startet wie neu installiert. Das kann nicht rückgängig gemacht werden.';

  @override
  String get actionErase => 'Löschen';

  @override
  String get receiveWhenClosedTitle => 'Empfangen, wenn AirReply geschlossen ist';

  @override
  String get receiveWhenClosedText =>
      'Eine Absicherung für Handys, die Benachrichtigungen zurückhalten. Zeigt eine kleine Statusbenachrichtigung.';

  @override
  String get popUpsTitle => 'Benachrichtigungen einblenden';

  @override
  String get actionOpenAlertSettings => 'Benachrichtigungseinstellungen öffnen';

  @override
  String get popUpsPromptTitle => 'Benachrichtigungen einblenden';

  @override
  String get alertSoundOffTitle => 'Benachrichtigungston einschalten';

  @override
  String popUpsWhy(String maker) {
    return '$maker lässt nur wenige Apps wie WhatsApp einblenden und klingeln, bis du es erlaubst. Keine App kann das selbst einschalten; es braucht nur einen Schalter.';
  }

  @override
  String get popUpsWhyGeneric =>
      'Dieses Handy hält AirReplys Benachrichtigungen in der Liste fest, ohne Einblendung und Ton. Keine App kann das selbst einschalten; es braucht nur einen Schalter.';

  @override
  String popUpsStepsOppo(String category) {
    return 'Tippe auf Benachrichtigungseinstellungen öffnen. Schalte auf der Seite von AirReply Banner, Klingeln und Vibrieren ein. Öffne dann unter Kategorien die $category und schalte auch dort Banner ein.';
  }

  @override
  String get popUpsStepsXiaomi =>
      'Tippe auf Benachrichtigungseinstellungen öffnen, schalte Schwebende Benachrichtigungen ein, dann Ton und Vibration.';

  @override
  String get popUpsStepsSamsung =>
      'Tippe auf Benachrichtigungseinstellungen öffnen, wähle Benachrichtigen und schalte Als Pop-up anzeigen ein.';

  @override
  String get popUpsStepsGeneric =>
      'Tippe auf Benachrichtigungseinstellungen öffnen, schalte Auf dem Bildschirm einblenden ein und wähle einen Ton.';

  @override
  String get popUpsFixed => 'Erledigt: Benachrichtigungen werden jetzt eingeblendet und klingeln.';

  @override
  String get settingsAlertsEyebrow => 'Benachrichtigungen';

  @override
  String get settingsAlertsTitle => 'Hinweise';

  @override
  String get settingsSharingEyebrow => 'Handy';

  @override
  String get settingsSharingTitle => 'Teilen';

  @override
  String get systemAlertSettingsTitle => 'Benachrichtigungseinstellungen';

  @override
  String get systemAlertSettingsSubtitle => 'Pop-up, Ton, Vibration und Sperrbildschirm, eingestellt auf diesem Gerät';

  @override
  String get testAlertSubtitle => 'Sieh, wie dich eine Nachricht gerade benachrichtigt';

  @override
  String get expectAlertsOffText =>
      'Benachrichtigungen kommen weiter in AirReply an, aber dieses Gerät meldet sie nicht. Erlaube Hinweise, um davon zu erfahren.';

  @override
  String get expectMessagesPopUp => 'Nachrichten erscheinen mit Ton';

  @override
  String get expectMessagesPopUpSilent => 'Nachrichten erscheinen ohne Ton';

  @override
  String get expectMessagesList => 'Nachrichten warten in der Benachrichtigungsliste';

  @override
  String get expectMessagesQuiet => 'Nachrichten kommen lautlos an';

  @override
  String get expectMessagesOff => 'Hinweise für Nachrichten sind aus';

  @override
  String expectOthers(String how) {
    return 'Andere Benachrichtigungen: $how.';
  }

  @override
  String get expectOthersPopUp => 'erscheinen mit Ton';

  @override
  String get expectOthersPopUpSilent => 'erscheinen ohne Ton';

  @override
  String get expectOthersList => 'in der Liste, mit Ton';

  @override
  String get expectOthersQuiet => 'in der Liste, lautlos';

  @override
  String get expectOthersOff => 'kein Hinweis';

  @override
  String get expectChangeHint => 'Um etwas zu ändern, öffne unten die Benachrichtigungseinstellungen.';

  @override
  String get expectOffHelp =>
      'Sie sind in den Benachrichtigungseinstellungen dieses Geräts ausgeschaltet. Tippe auf Benachrichtigungseinstellungen öffnen und schalte sie ein.';

  @override
  String get appIconTitle => 'App-Symbol';

  @override
  String get appIconLight => 'Hell';

  @override
  String get appIconDark => 'Dunkel';

  @override
  String get appIconHint => 'Das Symbol von AirReply auf deinem Startbildschirm.';

  @override
  String get appIconChanged => 'Symbol geändert. Dein Startbildschirm zeigt es eventuell erst nach einem Moment.';

  @override
  String get actionDelete => 'Löschen';

  @override
  String deleteCount(int count) {
    return '$count Benachrichtigungen löschen';
  }

  @override
  String get deleteFromDevice => 'Von diesem Gerät löschen';

  @override
  String notificationDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Benachrichtigungen gelöscht',
      one: 'Benachrichtigung gelöscht',
    );
    return '$_temp0';
  }

  @override
  String get clearAllTitle => 'Alles löschen';

  @override
  String get clearAllConfirmTitle => 'Alle Benachrichtigungen löschen?';

  @override
  String get clearAllConfirmMessage =>
      'Alle Benachrichtigungen auf diesem Gerät werden samt Antworten gelöscht, und die Hinweise von AirReply verschwinden aus der Benachrichtigungsleiste. Das lässt sich nicht rückgängig machen. Deine gekoppelten Geräte behalten ihre eigenen.';

  @override
  String get clearAllDone => 'Alle Benachrichtigungen gelöscht';
}
