// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count non lues',
      one: 'Notifications, 1 non lue',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get tabDevices => 'Appareils';

  @override
  String get tabSettings => 'Réglages';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lues',
      one: '1 non lue',
      zero: 'Tout est lu',
    );
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => 'Votre téléphone,';

  @override
  String get welcomeHeadlineSecond => 'partout.';

  @override
  String get welcomeIntro =>
      'Lisez les notifications de votre téléphone sur votre iPhone, iPad, Mac, PC ou navigateur, et répondez aux messages depuis celui-ci.';

  @override
  String get welcomeEyebrow => 'Commencer';

  @override
  String get welcomeQuestion => 'Comment allez-vous utiliser cet appareil ?';

  @override
  String get roleShareTitle => 'Partager mes notifications';

  @override
  String get roleShareDescription =>
      'Ce téléphone envoie ses notifications à vos autres appareils, et envoie les réponses que vous y écrivez.';

  @override
  String get roleShareUnavailable =>
      'Seul Android permet aux applis de lire les notifications. Utilisez un téléphone Android pour partager.';

  @override
  String get roleReceiveTitle => 'Voir et répondre ici';

  @override
  String get roleReceiveDescription =>
      'Consultez les notifications de votre téléphone sur cet appareil et répondez aux messages sans le prendre en main.';

  @override
  String get errorOffline => 'Vous semblez hors ligne. Vérifiez votre connexion et réessayez.';

  @override
  String get errorServerUnreachable => 'Impossible de joindre les serveurs AirReply. Vérifiez votre connexion.';

  @override
  String get errorSignInRefused =>
      'La connexion a été refusée. La connexion anonyme est-elle activée dans le projet Firebase ?';

  @override
  String get errorSignInFailed => 'Échec de la connexion.';

  @override
  String get errorSyncFailed => 'Échec de la synchronisation avec votre appareil associé.';

  @override
  String get errorPairingCodeNotCreated => 'Impossible de créer un code d\'association. Veuillez réessayer.';

  @override
  String get errorSessionNotConfirmable => 'Cette session ne peut pas être confirmée.';

  @override
  String get errorCodeUnavailable => 'Ce code n\'est plus disponible. Créez-en un nouveau sur l\'autre téléphone.';

  @override
  String get errorCannotPairWithItself => 'Un appareil ne peut pas s\'associer à lui-même.';

  @override
  String get errorCodeAlreadyUsed => 'Ce code a déjà été utilisé.';

  @override
  String get errorNoDeviceJoined => 'Aucun appareil ne s\'est encore connecté.';

  @override
  String get errorCodeFormat => 'Saisissez le code à 6 chiffres affiché sur le téléphone.';

  @override
  String get errorNotAPairingCode => 'Ce n\'est pas un code d\'association AirReply.';

  @override
  String get errorCodeNotFound => 'Aucun code de ce type. Vérifiez le code sur l\'autre téléphone.';

  @override
  String get errorCodeExpired => 'Ce code a expiré. Créez-en un nouveau.';

  @override
  String get errorQrMismatch =>
      'Le code QR ne correspond pas à cette session. L\'association a été arrêtée pour votre sécurité.';

  @override
  String get errorNotConfirmedYet => 'L\'autre téléphone n\'a pas encore confirmé.';

  @override
  String get errorPairingCancelledOnPhone => 'L\'association a été annulée sur l\'autre téléphone.';

  @override
  String get errorPairingCancelled => 'L\'association a été annulée. Créez un nouveau code pour réessayer.';

  @override
  String get errorPairingNotAvailable => 'Cette session d\'association n\'est pas disponible pour cet appareil.';

  @override
  String get errorPairingServerFailed => 'Le serveur n\'a pas pu terminer l\'association.';

  @override
  String get errorPairingOffInDemo => 'L\'association est désactivée en mode démo.';

  @override
  String get errorNotPaired => 'Cet appareil n\'est pas encore associé.';

  @override
  String get errorInvalidPeerKey => 'L\'autre appareil a envoyé une clé non valide.';

  @override
  String get errorUnsafePeerKey => 'L\'autre appareil a envoyé une clé non sécurisée.';

  @override
  String get errorEncryptFailed => 'Impossible de chiffrer la notification.';

  @override
  String get errorDecryptFailed => 'Impossible de déchiffrer la notification.';

  @override
  String get errorPayloadUnknown => 'Cette notification est dans un format inconnu.';

  @override
  String get errorPayloadForeign =>
      'Cette notification n\'a pas été créée avec la clé de cette association, ou elle a été modifiée.';

  @override
  String get errorNativeServiceFailed => 'Le service de notifications Android a échoué.';

  @override
  String get errorNativeServiceUnavailable => 'Le service de notifications Android n\'est pas disponible.';

  @override
  String get errorReplyEmpty => 'Écrivez d\'abord une réponse.';

  @override
  String get errorReplyTooLong => 'Cette réponse est trop longue.';

  @override
  String get errorReplyNotPossible => 'Impossible de répondre à cette notification.';

  @override
  String get errorReplyDismissed =>
      'Cette notification a été effacée sur votre téléphone : il n\'est plus possible d\'y répondre.';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impossible de joindre $count des $total appareils associés.',
      one: 'Impossible de joindre 1 des $total appareils associés.',
    );
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message ($detail)';
  }

  @override
  String get errorUnknown => 'Un problème est survenu. Veuillez réessayer.';

  @override
  String get errorSharingAndroidOnly => 'Le partage des notifications n\'est disponible que sur Android.';

  @override
  String get timeNow => 'maintenant';

  @override
  String timeMinutesShort(int n) {
    return '$n min';
  }

  @override
  String timeHoursShort(int n) {
    return '$n h';
  }

  @override
  String get timeToday => 'Aujourd\'hui';

  @override
  String get timeYesterday => 'Hier';

  @override
  String timeAt(String day, String time) {
    return '$day à $time';
  }

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'il y a $n min', one: 'il y a 1 min');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'il y a $n h', one: 'il y a 1 h');
    return '$_temp0';
  }

  @override
  String get actionUndo => 'Annuler';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get searchHint => 'Rechercher';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get splashFailed => 'AirReply n\'a pas pu démarrer';

  @override
  String get actionTryAgain => 'Réessayer';

  @override
  String get splashStarting => 'AirReply démarre';

  @override
  String get firebaseSetupEyebrow => 'Configuration requise';

  @override
  String get firebaseSetupTitle => 'Connecter Firebase';

  @override
  String get firebaseSetupBody =>
      'AirReply synchronise vos appareils via votre propre projet Firebase. Exécutez ceci dans le dossier du projet, puis recompilez l\'appli.';

  @override
  String get actionCopyCommand => 'Copier la commande';

  @override
  String get firebaseSetupDetails => 'Détails';

  @override
  String get deviceConnected => 'Connecté';

  @override
  String get deviceOffline => 'Hors ligne';

  @override
  String get deviceConnecting => 'Connexion';

  @override
  String get deviceNeedsAccess => 'Accès requis';

  @override
  String get devicePaused => 'En pause';

  @override
  String get deviceNotReceiving => 'Ne reçoit rien';

  @override
  String get deviceReceivingDetail => 'Les nouvelles notifications arrivent en temps réel.';

  @override
  String get deviceSharingDetail => 'Les nouvelles notifications sont partagées dès leur arrivée.';

  @override
  String get deviceOfflineDetail =>
      'Affichage des notifications enregistrées jusqu\'au retour en ligne de cet appareil.';

  @override
  String get deviceConnectingDetail => 'Connexion au serveur…';

  @override
  String get deviceNeedsAccessDetail => 'L\'accès aux notifications est désactivé : rien ne peut être partagé.';

  @override
  String get devicePausedDetail => 'Le partage est désactivé. Activez-le pour envoyer des notifications.';

  @override
  String get deviceNotReceivingDetail => 'Android a arrêté l\'écouteur de notifications d\'AirReply.';

  @override
  String get settingsAccessEyebrow => 'Accès';

  @override
  String get settingsPermissionsTitle => 'Autorisations';

  @override
  String get settingsFilterEyebrow => 'Filtre';

  @override
  String get settingsAppsTitle => 'Applis';

  @override
  String get settingsPrivacyEyebrow => 'Confidentialité';

  @override
  String get settingsPrivacyTitle => 'Recopie et confidentialité';

  @override
  String get settingsConnectionEyebrow => 'Connexion';

  @override
  String get settingsSyncTitle => 'Synchronisation';

  @override
  String get settingsAppearanceEyebrow => 'Apparence';

  @override
  String get settingsAppearanceTitle => 'Apparence et accessibilité';

  @override
  String get settingsDataEyebrow => 'Données';

  @override
  String get settingsDataTitle => 'Vos données';

  @override
  String get settingsHelpEyebrow => 'Aide';

  @override
  String get settingsHelpTitle => 'Aide et à propos';

  @override
  String get permissionOn => 'Activé';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionAllow => 'Autoriser';

  @override
  String get permissionAccessTitle => 'Accès aux notifications';

  @override
  String get permissionAccessSubtitle => 'Nécessaire pour lire et partager les notifications';

  @override
  String get permissionStatusTitle => 'Notification d\'état';

  @override
  String get permissionStatusSubtitle => 'Affiche « Synchronisation des notifications active » avec un bouton Pause';

  @override
  String get permissionBatteryTitle => 'Optimisation de la batterie';

  @override
  String get permissionBatteryOk => 'Non restreinte : Android ne mettra pas le partage en pause';

  @override
  String get permissionBatteryFix =>
      'Choisissez « Non restreinte » pour qu\'Android ne mette jamais le partage en pause';

  @override
  String get permissionAlertsTitle => 'Alertes';

  @override
  String get permissionAlertsBrowser => 'Permet à ce navigateur d\'afficher les nouvelles notifications';

  @override
  String get permissionAlertsDevice => 'Permet à cet appareil de vous alerter des nouvelles notifications';

  @override
  String get loading => 'Chargement…';

  @override
  String get appsAllShared => 'Toutes les applis sont partagées';

  @override
  String get appsNoneShared => 'Aucune appli sélectionnée : rien n\'est partagé';

  @override
  String get appsToShareTitle => 'Applis à partager';

  @override
  String get appsMutedTitle => 'Applis en sourdine';

  @override
  String get encryptionTitle => 'Chiffrement de bout en bout';

  @override
  String get encryptionDetail =>
      'Chaque association a sa propre clé, convenue entre les deux appareils (X25519). Les notifications et les réponses sont scellées avec AES-256-GCM. L\'historique reste sur vos appareils : le serveur ne fait que relayer le texte chiffré et supprime chaque message dès sa livraison.';

  @override
  String get shareNotificationsTitle => 'Partager les notifications';

  @override
  String get shareNeedsAccess => 'Activez d\'abord l\'accès aux notifications';

  @override
  String get alertTextTitle => 'Afficher le texte des messages dans les alertes';

  @override
  String get alertTextSubtitle =>
      'Désactivé : les alertes n\'indiquent que l\'appli, pour les écrans verrouillés et partagés';

  @override
  String get alertsBrowserTitle => 'Alertes dans ce navigateur';

  @override
  String get alertsComputerTitle => 'Alertes sur cet ordinateur';

  @override
  String get alertsWhileOpen =>
      'Les nouvelles notifications vous alertent tant qu\'AirReply est ouvert. Gardez-le ouvert (sur Mac, il continue de fonctionner quand vous fermez la fenêtre).';

  @override
  String get syncNoDevices => 'Aucun appareil associé';

  @override
  String get syncStatusTitle => 'État de la synchronisation';

  @override
  String get syncChecking => 'Vérification de la connexion…';

  @override
  String get actionRefresh => 'Actualiser';

  @override
  String get listenerTitle => 'Écouteur de notifications';

  @override
  String get listenerSubtitle =>
      'Demander à Android de reconnecter l\'écouteur d\'AirReply si les appareils ne reçoivent plus rien';

  @override
  String get actionReconnect => 'Reconnecter';

  @override
  String get themeTitle => 'Thème';

  @override
  String get themeSubtitle => 'Système suit cet appareil';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get hapticsTitle => 'Retour haptique';

  @override
  String get hapticsSubtitle => 'Une légère vibration quand vous envoyez, basculez ou confirmez';

  @override
  String get textSizeTitle => 'Taille du texte';

  @override
  String get textSizeSubtitle => 'AirReply suit la taille du texte et le texte en gras définis sur cet appareil';

  @override
  String get removeAllConfirmTitle => 'Retirer tous les appareils ?';

  @override
  String get actionRemoveAll => 'Tout retirer';

  @override
  String get markAllReadTitle => 'Tout marquer comme lu';

  @override
  String get markedAllRead => 'Tout est marqué comme lu';

  @override
  String get restoreHiddenTitle => 'Restaurer les notifications masquées';

  @override
  String get hiddenRestored => 'Notifications masquées restaurées';

  @override
  String get removeAllTitle => 'Retirer tous les appareils';

  @override
  String get removeAllSubtitle => 'Met fin à toutes les associations ; leur historique reste dans Appareils précédents';

  @override
  String get troubleshootingTitle => 'Dépannage';

  @override
  String get troubleshootingSubtitle => 'Que vérifier quand les notifications ou les réponses n\'arrivent pas';

  @override
  String get diagnosticsTitle => 'Diagnostic';

  @override
  String get diagnosticsSubtitle =>
      'Détails de connexion, d\'autorisations et de synchronisation à vérifier ou partager';

  @override
  String get licencesTitle => 'Licences open source';

  @override
  String get appTagline => 'Les notifications de votre téléphone, sur tous vos écrans.';

  @override
  String get syncSharing => 'Partage';

  @override
  String get syncStarting => 'Démarrage';

  @override
  String get permissionAutostartTitle => 'Démarrage automatique';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return 'Nécessaire sur les téléphones $vendor. Android ne peut pas l\'indiquer : vérifiez-le dans les réglages.';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seulement $count applis sélectionnées',
      one: 'Seulement 1 appli sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en sourdine : arrivent sans alerte',
      one: '1 en sourdine : arrive sans alerte',
      zero: 'Toutes les applis peuvent vous alerter',
    );
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state. En direct.';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state. Dernière synchro : $ago.';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state. $detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return 'La synchronisation avec $name s\'arrête. Son historique reste sur cet appareil dans Appareils précédents, et revient si vous l\'associez de nouveau.';
  }

  @override
  String removeAllConfirmMany(int count) {
    return 'La synchronisation avec les $count appareils s\'arrête. Leur historique reste sur cet appareil dans Appareils précédents, et revient si vous les associez de nouveau.';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count non lues',
      one: '1 non lue',
      zero: 'Rien de non lu',
    );
    return '$_temp0';
  }

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count masquées sur cet appareil',
      one: '1 masquée sur cet appareil',
      zero: 'Rien de masqué',
    );
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => 'L\'accès aux notifications est désactivé';

  @override
  String get noticeAccessOffMessage =>
      'AirReply ne peut pas voir les nouvelles notifications tant que vous ne le réactivez pas.';

  @override
  String get actionOpenSettings => 'Ouvrir les réglages';

  @override
  String get noticePausedTitle => 'Le partage est en pause';

  @override
  String get noticePausedMessage => 'Les notifications de ce téléphone ne sont pas envoyées à vos appareils.';

  @override
  String get actionResumeSharing => 'Reprendre le partage';

  @override
  String get noticeNotReceivingTitle => 'Aucune notification reçue';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android a arrêté l\'écouteur d\'AirReply. Reconnectez-le et activez le démarrage automatique d\'AirReply sur les téléphones $vendor pour que cela ne se reproduise pas.';
  }

  @override
  String get noticeNotReceivingMessage =>
      'Android a arrêté l\'écouteur de notifications d\'AirReply. Reconnectez-le pour reprendre.';

  @override
  String get noticeBatteryTitle => 'L\'optimisation de la batterie est activée';

  @override
  String get noticeBatteryMessage =>
      'Android peut mettre le partage en pause pour économiser la batterie. Réglez AirReply sur « Non restreinte ».';

  @override
  String get actionBatterySettings => 'Réglages de la batterie';

  @override
  String get noticeAlertsOffTitle => 'Les alertes sont désactivées sur cet appareil';

  @override
  String get noticeAlertsOffMessage =>
      'Les nouvelles notifications s\'affichent toujours ici, mais cet appareil ne vous alertera pas.';

  @override
  String get actionAllowAlerts => 'Autoriser les alertes';

  @override
  String noticeOneOffline(String name) {
    return '$name est hors ligne';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count appareils sont hors ligne';
  }

  @override
  String get noticeOfflineMessage =>
      'Affichage des notifications enregistrées. Les nouvelles arriveront dès que cet appareil sera de nouveau en ligne.';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get setupTitle => 'Configurer';

  @override
  String get disclosureEyebrow => 'Avant de commencer';

  @override
  String get disclosureTitle => 'AirReply a besoin d\'accéder à vos notifications';

  @override
  String get disclosureIntro =>
      'Pour partager les notifications de ce téléphone avec vos appareils associés, AirReply utilise l\'autorisation Android d\'accès aux notifications.';

  @override
  String get disclosureWhatTitle => 'Ce qui est consulté';

  @override
  String get disclosureWhatBody =>
      'Les notifications affichées sur ce téléphone : nom de l\'appli, titre, texte, heure et action de réponse des messageries. Cela fonctionne en arrière-plan, même quand AirReply est fermé.';

  @override
  String get disclosureWhyTitle => 'Pourquoi';

  @override
  String get disclosureWhyBody =>
      'Uniquement pour afficher ces notifications sur les appareils que vous associez, et pour envoyer les réponses que vous y écrivez via l\'appli d\'origine sur ce téléphone.';

  @override
  String get disclosureHowTitle => 'Comment c\'est protégé';

  @override
  String get disclosureHowBody =>
      'Chaque notification est chiffrée sur ce téléphone avec AES-256-GCM, avec une clé que seuls ce téléphone et l\'appareil associé détiennent. Nos serveurs relaient un texte chiffré qu\'ils ne peuvent pas lire, et le suppriment après livraison : l\'historique n\'est conservé que sur vos appareils.';

  @override
  String get disclosureControlTitle => 'Vous gardez le contrôle';

  @override
  String get disclosureControlBody =>
      'Choisissez les applis partagées, mettez en pause à tout moment depuis la notification d\'état, ou retirez un appareil pour arrêter le partage ; supprimez son historique quand vous voulez. Le contenu des notifications n\'est jamais vendu, partagé avec des tiers, ni utilisé pour la publicité ou l\'analyse.';

  @override
  String get actionAgreeAndContinue => 'Accepter et continuer';

  @override
  String get actionNoThanks => 'Non merci';

  @override
  String setupProgress(int done, int total) {
    return '$done étape(s) obligatoire(s) sur $total terminée(s)';
  }

  @override
  String get setupPhoneTitle => 'Configurer ce téléphone';

  @override
  String get setupPhoneSubtitle =>
      'Deux autorisations permettent à AirReply de partager les notifications et de continuer à fonctionner en arrière-plan.';

  @override
  String get setupAccessSubtitle => 'Obligatoire. Trouvez AirReply dans la liste et activez-le.';

  @override
  String get setupStatusSubtitle =>
      'Affiche « Synchronisation des notifications active » avec un bouton Pause pendant le partage.';

  @override
  String setupAutostartSubtitle(String vendor) {
    return 'Obligatoire sur $vendor. Sans cela, le téléphone empêche AirReply d\'écouter une fois l\'appli fermée. Trouvez AirReply et activez le démarrage automatique.';
  }

  @override
  String get setupBatterySubtitle =>
      'Recommandé. Réglez AirReply sur « Non restreinte » pour qu\'Android ne mette jamais le partage en pause.';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get setupNeedsAccess => 'Activez l\'accès aux notifications pour continuer';

  @override
  String get stepDone => 'Terminé';

  @override
  String get pairADevice => 'Associer un appareil';

  @override
  String get pairTitle => 'Associer';

  @override
  String get pairAddADevice => 'Ajouter un appareil';

  @override
  String pairPairedWith(String name) {
    return 'Associé à $name';
  }

  @override
  String pairStep(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get pairStopped => 'Association arrêtée';

  @override
  String get actionMakeNewCode => 'Créer un nouveau code';

  @override
  String get pairShowCodeIntro =>
      'Sur votre iPhone, iPad, Mac, PC, navigateur ou autre Android, ouvrez AirReply, choisissez « Voir et répondre ici », puis scannez ce code ou saisissez les chiffres.';

  @override
  String get pairQrLabel => 'Code QR d\'association';

  @override
  String get pairOrTypeCode => 'OU SAISISSEZ CE CODE';

  @override
  String pairCodeCopied(String code) {
    return 'Code $code copié';
  }

  @override
  String get actionCopyCode => 'Copier le code';

  @override
  String get actionNewCode => 'Nouveau code';

  @override
  String get pairCodesMatchQuestion => 'Les codes correspondent-ils ?';

  @override
  String pairVerifyWarning(String name) {
    return '$name souhaite s\'associer. Il doit afficher exactement ce code. Sinon, quelqu\'un d\'autre essaie peut-être de se connecter.';
  }

  @override
  String get actionCodesMatch => 'Ils correspondent, associer';

  @override
  String get actionCodesDoNotMatch => 'Ils ne correspondent pas';

  @override
  String get pairAddAnotherPhone => 'Ajouter un autre téléphone';

  @override
  String get pairWithYourPhone => 'Associer à votre téléphone';

  @override
  String get pairEnterCodeIntro =>
      'Sur le téléphone Android que vous voulez voir ici, ouvrez AirReply et choisissez « Partager mes notifications » (ou « Ajouter un appareil » s\'il partage déjà). Il affiche un code QR et six chiffres.';

  @override
  String get pairMethodScan => 'Scanner';

  @override
  String get pairMethodType => 'Saisir le code';

  @override
  String get pairCodeLabel => 'CODE D\'ASSOCIATION';

  @override
  String get pairStartsOnLastDigit => 'L\'association démarre dès que vous saisissez le dernier chiffre.';

  @override
  String get pairConnecting => 'Connexion…';

  @override
  String get pairPointCamera => 'Dirigez l\'appareil photo vers le code QR affiché sur votre téléphone.';

  @override
  String get cameraDenied =>
      'AirReply a besoin de l\'appareil photo pour scanner. Autorisez-le dans les réglages du téléphone, ou saisissez le code.';

  @override
  String get cameraNotStarted => 'L\'appareil photo n\'a pas démarré.';

  @override
  String pairConfirmOn(String name) {
    return 'Confirmez sur $name';
  }

  @override
  String get pairConfirmHint =>
      'Vérifiez que votre téléphone affiche le même code, puis touchez « Ils correspondent » sur celui-ci.';

  @override
  String get pairWaitingForPhone => 'En attente de votre téléphone…';

  @override
  String get pairCodeExpired => 'Code expiré, création d\'un nouveau';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return 'Expire dans $minutes:$seconds';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return 'Étape $current sur $total : $name';
  }

  @override
  String get pairCouldNotPair => 'Association impossible';

  @override
  String get stepShowCode => 'Afficher le code';

  @override
  String get stepVerify => 'Vérifier';

  @override
  String get stepEnterCode => 'Saisir le code';

  @override
  String get notYet => 'Pas encore';

  @override
  String get factStatus => 'État';

  @override
  String get factLive => 'En direct';

  @override
  String get factLastSynced => 'Dernière synchro';

  @override
  String get factNow => 'Maintenant';

  @override
  String get lastShared => 'Dernier partage';

  @override
  String get lastNotification => 'Dernière notification';

  @override
  String get factPaired => 'Associé';

  @override
  String get factEncryption => 'Chiffrement';

  @override
  String get factEncryptionValue => 'De bout en bout, AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String removeDeviceMessage(String name) {
    return 'La synchronisation avec $name s\'arrête sur les deux appareils. Son historique reste sur cet appareil dans Appareils → Appareils précédents jusqu\'à ce que vous le supprimiez. Les autres appareils ne sont pas concernés.';
  }

  @override
  String get actionRemove => 'Retirer';

  @override
  String deviceRemoved(String name) {
    return '$name retiré';
  }

  @override
  String get actionTurnOnAccess => 'Activer l\'accès aux notifications';

  @override
  String get browseShared => 'Parcourir ce que vous avez partagé';

  @override
  String get browseHistory => 'Parcourir l\'historique des notifications';

  @override
  String get actionRemoveDevice => 'Retirer l\'appareil';

  @override
  String get addAPhone => 'Ajouter un téléphone';

  @override
  String factWithTime(String label, String time) {
    return '$label : $time';
  }

  @override
  String pairedAgo(String time) {
    return 'Associé : $time';
  }

  @override
  String devicesPaired(int count) {
    return '$count associé(s)';
  }

  @override
  String get devicesIntroSender => 'Ce téléphone partage ses notifications avec ces appareils.';

  @override
  String get devicesIntroReceiver => 'Cet appareil affiche les notifications de ces téléphones.';

  @override
  String get devicesNone => 'Aucun appareil';

  @override
  String get devicesNoneHint => 'Associez un appareil pour commencer.';

  @override
  String get helpNotArrivingQ => 'Les notifications n\'arrivent pas';

  @override
  String get helpNotArrivingA =>
      'Sur le téléphone, ouvrez AirReply et vérifiez que « Partager les notifications » est activé et que l\'appli peut fonctionner en arrière-plan. Les deux appareils doivent être connectés à internet. Puis réessayez ici.';

  @override
  String get actionRetrySync => 'Relancer la synchro';

  @override
  String get helpNoAlertsQ => 'Aucune alerte sur cet appareil';

  @override
  String get helpNoAlertsA =>
      'Les nouvelles notifications arrivent toujours dans l\'onglet Notifications. Pour être aussi alerté, autorisez les notifications d\'AirReply et vérifiez que l\'appli n\'est pas en sourdine dans Réglages → Applis en sourdine.';

  @override
  String get helpExpiredQ => 'Une réponse indique « Expirée sur le téléphone »';

  @override
  String get helpExpiredA =>
      'Les réponses sont envoyées via la notification sur le téléphone. Une fois qu\'elle y est effacée, ou que l\'appli l\'a remplacée, il n\'est plus possible d\'y répondre. Répondez à une notification plus récente, ou depuis le téléphone.';

  @override
  String get helpNotReceivingQ => 'Les appareils ne reçoivent pas de notifications';

  @override
  String get helpNotReceivingA =>
      'Vérifiez que l\'accès aux notifications est activé et que le partage n\'est pas en pause. Si Android a arrêté l\'écouteur d\'AirReply, reconnectez-le.';

  @override
  String get actionReconnectListener => 'Reconnecter l\'écouteur';

  @override
  String get helpStopsQ => 'Le partage s\'arrête au bout d\'un moment';

  @override
  String helpStopsAutostartA(String vendor) {
    return 'Sur les téléphones $vendor, activez le démarrage automatique d\'AirReply et réglez son utilisation de la batterie sur « Non restreinte », sinon le téléphone l\'arrête en arrière-plan.';
  }

  @override
  String get helpStopsA =>
      'Réglez l\'utilisation de la batterie d\'AirReply sur « Non restreinte » pour qu\'Android ne le mette pas en pause en arrière-plan.';

  @override
  String get helpRepliesQ => 'Les réponses ne sont pas livrées';

  @override
  String get helpRepliesA =>
      'Une réponse est envoyée via la notification à laquelle elle répond : cette notification doit donc toujours être dans la barre d\'état de ce téléphone. Les messageries qui proposent « Répondre » dans leurs notifications fonctionnent le mieux.';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historySharedWithIt => 'Partagé avec lui';

  @override
  String get emptyNothingYet => 'Rien pour l\'instant';

  @override
  String historyEmptySender(String name) {
    return 'Les notifications que ce téléphone partage avec $name s\'affichent ici.';
  }

  @override
  String historyEmptyReceiver(String name) {
    return 'Les notifications de $name s\'affichent ici.';
  }

  @override
  String get thisPhone => 'ce téléphone';

  @override
  String get itDevice => 'cet appareil';

  @override
  String get homeHeadlineSender => 'partagé.';

  @override
  String get homeIntroSender =>
      'Les notifications de ce téléphone arrivent sur vos autres appareils, et leurs réponses reviennent.';

  @override
  String get homeIntroReceiver =>
      'Les notifications de votre téléphone arrivent ici. Lisez-les, et répondez sans le prendre en main.';

  @override
  String get searchNotificationsHint => 'Rechercher des notifications';

  @override
  String get homeTodayEyebrow => 'Aujourd\'hui';

  @override
  String get homeGlanceTitle => 'En un coup d\'œil';

  @override
  String get homeRecentEyebrow => 'Activité récente';

  @override
  String get homeLatestTitle => 'Dernières notifications';

  @override
  String get actionSeeAll => 'Tout voir';

  @override
  String get homeRecentEmptySender =>
      'Rien de partagé pour l\'instant. Les nouvelles notifications de ce téléphone s\'afficheront ici.';

  @override
  String get homeRecentEmptyReceiver =>
      'Rien pour l\'instant. Les nouvelles notifications de votre téléphone s\'afficheront ici.';

  @override
  String get homeRecentFailed => 'Impossible de charger les notifications récentes.';

  @override
  String get homeSharingEyebrow => 'Partage';

  @override
  String get homeThisPhoneTitle => 'Ce téléphone';

  @override
  String get howItWorksEyebrow => 'Fonctionnement';

  @override
  String get howItWorksSenderTitle => 'Partagez une fois. Répondez de partout.';

  @override
  String get howItWorksReceiverTitle => 'Trois étapes. Tous les écrans.';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $count non lues',
      one: 'Notifications, 1 non lue',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get statToday => 'Aujourd\'hui';

  @override
  String get statUnread => 'Non lues';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Appareils', one: 'Appareil');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Aucun résultat';

  @override
  String searchNoMatchesDetail(String query) {
    return 'Aucune notification ni aucun appareil ne mentionne « $query ».';
  }

  @override
  String get searchEyebrow => 'Recherche';

  @override
  String get stepShareTitle => 'Partagez depuis votre téléphone';

  @override
  String get stepShareText =>
      'Sur votre téléphone Android, AirReply envoie ici chaque notification, chiffrée de bout en bout.';

  @override
  String get stepReadTitle => 'Lisez-les ici';

  @override
  String get stepReadText => 'Les notifications arrivent en quelques secondes, regroupées par appli et par personne.';

  @override
  String get stepReplyTitle => 'Répondez de partout';

  @override
  String get stepReplyText => 'Écrivez une réponse ici ; votre téléphone l\'envoie via l\'appli d\'où elle vient.';

  @override
  String get stepPickTitle => 'Choisissez ce que vous partagez';

  @override
  String get stepPickText => 'Toutes les applis, ou seulement celles que vous voulez sur vos autres appareils.';

  @override
  String get stepPairTitle => 'Associez vos appareils';

  @override
  String get stepPairText => 'Un Mac, PC, iPhone, iPad ou navigateur scanne un code une fois, et ils restent associés.';

  @override
  String get stepReplySenderText =>
      'Les réponses écrites là-bas sont envoyées depuis ce téléphone, via l\'appli concernée.';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count applis sélectionnées',
      one: '1 appli sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get actionChooseApps => 'Choisir les applis →';

  @override
  String get pairDeviceKinds => 'iPhone, iPad, Mac, PC, navigateur ou Android';

  @override
  String get actionPairArrow => 'Associer →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count téléphones', one: '1 téléphone');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count appareils', one: '1 appareil');
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return 'Réception depuis $names.';
  }

  @override
  String statusConnectingTo(String names) {
    return 'Connexion à $names…';
  }

  @override
  String statusShowingSaved(String names) {
    return 'Affichage des notifications enregistrées de $names.';
  }

  @override
  String get statusLive => 'En direct. Les nouvelles notifications apparaissent en quelques secondes.';

  @override
  String statusLastSynced(String ago) {
    return 'Dernière synchro : $ago.';
  }

  @override
  String get statusNeedsAccess => 'Le partage nécessite l\'accès aux notifications.';

  @override
  String get statusPaused => 'Le partage est en pause.';

  @override
  String statusSharingWith(String names) {
    return 'Partage avec $names.';
  }

  @override
  String get statusNotWorking => 'Le partage ne fonctionne pas pour le moment.';

  @override
  String get statusEncryptedDetail =>
      'Les notifications sont chiffrées de bout en bout sur ce téléphone avant de le quitter.';

  @override
  String get statusOffDetail => 'Rien de ce téléphone n\'atteint vos appareils tant que le partage n\'est pas activé.';

  @override
  String get encrypted => 'Chiffré';

  @override
  String get periodAnyTime => 'N\'importe quand';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get periodWeek => '7 derniers jours';

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
      other: '$count nouvelles notifications',
      one: '1 nouvelle notification',
    );
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label, $count non lue(s)';
  }

  @override
  String get nothingHereNow => 'Rien ici pour le moment';

  @override
  String get goneDetail =>
      'Ces notifications ont été masquées, supprimées, ou proviennent d\'un appareil qui n\'est plus associé.';

  @override
  String get actionBackToNotifications => 'Retour aux notifications';

  @override
  String get searchConversationsHint => 'Rechercher des noms, numéros et messages';

  @override
  String get conversationsEyebrow => 'Conversations';

  @override
  String conversationsEyebrowCount(int count) {
    return 'Conversations · $count';
  }

  @override
  String get peopleAndGroups => 'Personnes et groupes';

  @override
  String otherNotificationsCount(int count) {
    return 'Autres notifications · $count';
  }

  @override
  String fromApp(String app) {
    return 'De $app';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'Rien ne correspond à « $query ».';
  }

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get notificationGoneDetail =>
      'Cette notification a été supprimée, masquée, ou appartient à un appareil qui n\'est plus associé.';

  @override
  String get markAsUnread => 'Marquer comme non lue';

  @override
  String get markAsRead => 'Marquer comme lue';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get hideFromDevice => 'Masquer sur cet appareil';

  @override
  String get actionHide => 'Masquer';

  @override
  String hideCount(int count) {
    return 'Masquer $count notifications';
  }

  @override
  String get you => 'Vous';

  @override
  String youSaid(String text) {
    return 'Vous : $text';
  }

  @override
  String get sentFromPhone => 'Envoyé depuis votre téléphone';

  @override
  String get clearedOnPhone => 'Effacée sur le téléphone';

  @override
  String get canReply => 'Réponse possible';

  @override
  String get canBeAnswered => 'Peut recevoir une réponse';

  @override
  String get noRepliesInApp => 'Pas de réponse dans cette appli';

  @override
  String get replySending => 'Envoi';

  @override
  String get replyDelivered => 'Livrée';

  @override
  String get replySent => 'Envoyée';

  @override
  String get replyExpired => 'Expirée sur le téléphone';

  @override
  String get replyNotDelivered => 'Non livrée';

  @override
  String get replySendingPrefixed => 'Réponse en cours d\'envoi';

  @override
  String get replyDeliveredPrefixed => 'Réponse livrée';

  @override
  String get replySentPrefixed => 'Réponse envoyée';

  @override
  String get replyExpiredPrefixed => 'Réponse expirée sur le téléphone';

  @override
  String get replyNotDeliveredPrefixed => 'Réponse non livrée';

  @override
  String get yourReply => 'Votre réponse';

  @override
  String yourReplyAsShown(String app) {
    return 'Votre réponse, telle que $app l\'affiche';
  }

  @override
  String get allMarkedRead => 'Tout est marqué comme lu';

  @override
  String sharedWith(String name) {
    return 'Partagé avec $name';
  }

  @override
  String sharedWithDevices(int count) {
    return 'Partagé avec $count appareils';
  }

  @override
  String fromDevice(String name) {
    return 'De $name';
  }

  @override
  String fromPhones(int count) {
    return 'De $count téléphones';
  }

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filtres, $count actifs',
      one: 'Filtres, 1 actif',
      zero: 'Filtres',
    );
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => 'Rien ne correspond à cette recherche ou à ce filtre.';

  @override
  String get actionClearSearchAndFilters => 'Effacer la recherche et les filtres';

  @override
  String get allCaughtUp => 'Vous êtes à jour';

  @override
  String get inboxEmptySender =>
      'Les notifications partagées par ce téléphone s\'affichent ici, avec les réponses envoyées depuis vos appareils.';

  @override
  String get inboxEmptyReceiver => 'Les notifications de votre téléphone s\'affichent ici dès leur arrivée.';

  @override
  String get inboxAllHidden => 'Toutes les notifications sont masquées. Restaurez-les depuis les Réglages.';

  @override
  String get notificationsLoadFailed => 'Impossible de charger les notifications';

  @override
  String get removeFilter => 'Retirer le filtre';

  @override
  String get filterUnread => 'Non lues';

  @override
  String get device => 'Appareil';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared =>
      'Ces notifications ont été effacées sur votre téléphone : il n\'est plus possible d\'y répondre d\'ici.';

  @override
  String footnoteNoReplies(String app) {
    return '$app n\'accepte pas de réponse pour cette conversation.';
  }

  @override
  String get unknownSender => 'Expéditeur inconnu';

  @override
  String get dividerNew => 'Nouveau';

  @override
  String notificationHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications masquées',
      one: 'Notification masquée',
    );
    return '$_temp0';
  }

  @override
  String get copied => 'Copié';

  @override
  String get dismissedOnPhone => 'Effacée sur le téléphone';

  @override
  String get moreActions => 'Plus d\'actions';

  @override
  String get hideConversations => 'Masquer les conversations';

  @override
  String get showConversations => 'Afficher les conversations';

  @override
  String unmuteApp(String app) {
    return 'Réactiver les alertes de $app';
  }

  @override
  String muteApp(String app) {
    return 'Mettre en sourdine les alertes de $app';
  }

  @override
  String get threadChat => 'Discussion';

  @override
  String get threadGroup => 'Groupe';

  @override
  String get threadNotification => 'Notification';

  @override
  String get replyHint => 'Répondre';

  @override
  String replyToHint(String name) {
    return 'Répondre à $name';
  }

  @override
  String get sendWithEnter => 'Envoyer (Entrée)';

  @override
  String get actionSend => 'Envoyer';

  @override
  String get filterTitle => 'Filtrer';

  @override
  String get actionClearAll => 'Tout effacer';

  @override
  String get filterShow => 'Afficher';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterUnreadOnly => 'Non lues uniquement';

  @override
  String get filterWhen => 'Quand';

  @override
  String get filterSharedWith => 'Partagé avec';

  @override
  String get filterPhone => 'Téléphone';

  @override
  String get filterApp => 'Appli';

  @override
  String get filterAllApps => 'Toutes les applis';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Afficher $count notifications',
      one: 'Afficher 1 notification',
    );
    return '$_temp0';
  }

  @override
  String get actionShowMore => 'Afficher plus';

  @override
  String get browseSharedWithIt => 'Parcourir ce que vous avez partagé avec lui';

  @override
  String get browseItsHistory => 'Parcourir son historique de notifications';

  @override
  String get swipeUnread => 'Non lue';

  @override
  String get swipeRead => 'Lue';

  @override
  String get diagnosticsIntro => 'Rien ici n\'inclut le texte des notifications ni les clés de chiffrement.';

  @override
  String get reportCopied => 'Rapport copié';

  @override
  String get actionCopyReport => 'Copier le rapport';

  @override
  String get checkingAgain => 'Nouvelle vérification…';

  @override
  String get actionCheckAgain => 'Vérifier à nouveau';

  @override
  String get diagnosticsReportNote =>
      'Le rapport lui-même reste en anglais, pour que la personne qui vous aide puisse le lire.';

  @override
  String get welcomeEncryption =>
      'Chiffré de bout en bout avec une clé que seuls vos appareils détiennent. Le serveur relaie un texte chiffré qu\'il ne peut pas lire.';

  @override
  String get theOtherDevice => 'L\'autre appareil';

  @override
  String get appsShareIntro =>
      'Choisissez ce qui arrive sur vos appareils. Cela s\'applique même quand AirReply est fermé.';

  @override
  String get appsOnlySelected => 'Sélection uniquement';

  @override
  String get searchApps => 'Rechercher des applis';

  @override
  String get appsNothingSelected => 'Aucune sélection : aucune notification n\'est partagée';

  @override
  String appsSelected(int count) {
    return '$count sélectionnée(s)';
  }

  @override
  String get appsOnlySelectedHint =>
      'Choisissez « Sélection uniquement » pour indiquer quelles applis arrivent sur vos appareils.';

  @override
  String get appsChoiceLoadFailed => 'Impossible de charger votre choix';

  @override
  String get appsMutedIntro =>
      'Les applis en sourdine arrivent toujours dans Notifications, mais ne vous alertent jamais sur cet appareil.';

  @override
  String get appsNoneYet => 'Aucune appli pour l\'instant';

  @override
  String get appsNoneYetHint =>
      'Les applis s\'affichent ici dès que votre téléphone a envoyé une de leurs notifications.';

  @override
  String get appMuted => 'En sourdine';

  @override
  String get appAlertsOn => 'Alertes activées';

  @override
  String get appsNoMatch => 'Aucune appli ne correspond';

  @override
  String get appsListFailed => 'Impossible de lister les applis';

  @override
  String get appsReading => 'Lecture des applis installées…';

  @override
  String get alertChannelName => 'Notifications recopiées';

  @override
  String get alertChannelDescription => 'Notifications recopiées depuis votre téléphone associé';

  @override
  String get alertReply => 'Répondre';

  @override
  String get alertReplyHint => 'Répondre…';

  @override
  String get alertOpenApp => 'Ouvrir AirReply';

  @override
  String get alertNewNotification => 'Nouvelle notification';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSystem => 'Comme cet appareil';

  @override
  String languageSystemCurrent(String language) {
    return 'Comme cet appareil ($language)';
  }

  @override
  String get previousDevicesTitle => 'Appareils précédents';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils retirés, historique conservé',
      one: '1 appareil retiré, historique conservé',
      zero: 'L\'historique des appareils retirés est conservé ici',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro =>
      'Quand vous retirez un appareil, son historique reste sur cet appareil. Associez de nouveau le même appareil pour reprendre là où vous en étiez, ou supprimez l\'historique ici.';

  @override
  String get previousDevicesNone => 'Aucun appareil précédent';

  @override
  String get previousDevicesNoneHint => 'L\'historique des appareils que vous retirez s\'affiche ici.';

  @override
  String previousDeviceSummary(String date, String count) {
    return 'Retiré : $date · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return 'Retiré : $date';
  }

  @override
  String previousDeviceContinue(String name) {
    return 'Associez de nouveau $name pour retrouver cet historique dans vos notifications.';
  }

  @override
  String get actionDeleteHistory => 'Supprimer l\'historique';

  @override
  String deleteHistoryTitle(String name) {
    return 'Supprimer l\'historique de $name ?';
  }

  @override
  String get deleteHistoryMessage =>
      'Ses notifications et réponses sont supprimées de cet appareil. Cette action est irréversible.';

  @override
  String historyDeleted(String name) {
    return 'Historique de $name supprimé';
  }

  @override
  String get actionDeleteAll => 'Tout supprimer';

  @override
  String get deleteAllHistoryTitle => 'Supprimer tout l\'historique précédent ?';

  @override
  String get deleteAllHistoryMessage =>
      'L\'historique de chaque appareil retiré est supprimé de cet appareil. Cette action est irréversible.';

  @override
  String get allHistoryDeleted => 'Historique précédent supprimé';

  @override
  String get feedbackReportTitle => 'Signaler un problème';

  @override
  String get feedbackReportSubtitle => 'Quelque chose ne marche pas ? Dites-nous ce qui s\'est passé';

  @override
  String get feedbackIdeaTitle => 'Proposer une fonctionnalité';

  @override
  String get feedbackIdeaSubtitle => 'Une idée pour améliorer AirReply';

  @override
  String get feedbackKindLabel => 'Type';

  @override
  String get feedbackKindProblem => 'Problème';

  @override
  String get feedbackKindIdea => 'Idée de fonctionnalité';

  @override
  String get feedbackAreaLabel => 'De quoi s\'agit-il ?';

  @override
  String get feedbackAreaNotifications => 'Notifications';

  @override
  String get feedbackAreaReplies => 'Réponses';

  @override
  String get feedbackAreaPairing => 'Association';

  @override
  String get feedbackAreaAlerts => 'Alertes';

  @override
  String get feedbackAreaSync => 'Synchronisation';

  @override
  String get feedbackAreaDesign => 'Apparence';

  @override
  String get feedbackAreaOther => 'Autre chose';

  @override
  String get feedbackMessageLabel => 'Votre message';

  @override
  String get feedbackProblemHint =>
      'Que s\'est-il passé, et qu\'attendiez-vous ? Les étapes pour reproduire le problème aident beaucoup.';

  @override
  String get feedbackIdeaHint => 'Que voudriez-vous qu\'AirReply fasse, et en quoi cela vous aiderait-il ?';

  @override
  String get feedbackTooShort => 'Écrivez-en un peu plus (au moins 10 caractères).';

  @override
  String get feedbackIncludeDetails => 'Joindre les détails de l\'appareil';

  @override
  String get feedbackDetailsSubtitle =>
      'Système, modèle, langue de l\'appli et rôle. Jamais vos notifications ni vos clés.';

  @override
  String get feedbackSent => 'Merci ! Votre appli de messagerie est prête : touchez Envoyer pour terminer.';

  @override
  String get feedbackNoEmailApp => 'Aucune appli de messagerie n\'est configurée sur cet appareil.';

  @override
  String get alertChannelPopUp => 'Alertes contextuelles';

  @override
  String get alertChannelSilent => 'Notifications silencieuses';

  @override
  String get alertStatusChannelName => 'État des réponses';

  @override
  String get alertStatusChannelDescription =>
      'Vous prévient quand une réponse écrite dans une notification n\'a pas pu être envoyée';

  @override
  String alertReplyNotSent(String name) {
    return 'Réponse à $name non envoyée';
  }

  @override
  String get alertStyleTitle => 'Affichage des alertes';

  @override
  String alertStyleSummary(String messages, String others) {
    return 'Messages : $messages · Autres : $others';
  }

  @override
  String get alertStyleIntro =>
      'Choisissez comment les notifications de votre téléphone vous alertent sur cet appareil. Quel que soit votre choix, elles arrivent toujours dans Notifications.';

  @override
  String get alertStyleMessages => 'Messages';

  @override
  String get alertStyleOthers => 'Autres notifications';

  @override
  String get alertModePopUp => 'Contextuelle';

  @override
  String get alertModePopUpHint => 'À l\'écran, avec son';

  @override
  String get alertModeNormal => 'Dans la liste';

  @override
  String get alertModeNormalHint => 'Avec son, sans couvrir l\'écran';

  @override
  String get alertModeSilent => 'Silencieuse';

  @override
  String get alertModeSilentHint => 'Dans la liste seulement : ni son ni vibration';

  @override
  String get alertModeOff => 'Désactivée';

  @override
  String get alertModeOffHint => 'Pas d\'alerte : seulement dans Notifications';

  @override
  String get alertStyleSoundTitle => 'Son et vibration';

  @override
  String get alertStyleSound => 'Son';

  @override
  String get alertStyleVibration => 'Vibration';

  @override
  String get alertStyleSoundHint => 'Pour les alertes contextuelles ou dans la liste';

  @override
  String get alertStyleLockScreen => 'Sur l\'écran verrouillé';

  @override
  String get lockScreenShow => 'Tout afficher';

  @override
  String get lockScreenHideContent => 'Masquer le contenu du message';

  @override
  String get lockScreenHide => 'Ne rien afficher avant le déverrouillage';

  @override
  String get alertStyleTest => 'Envoyer une alerte de test';

  @override
  String get alertStyleTestHint => 'Elle utilise les choix faits ci-dessus pour les messages.';

  @override
  String get alertStyleTestTitle => 'AirReply';

  @override
  String get alertStyleTestText => 'Voici comment un message vous alertera.';

  @override
  String pairFinishingOn(String name) {
    return 'Finalisation sur $name…';
  }

  @override
  String pairFinishingHint(String name) {
    return 'Gardez AirReply ouvert sur $name. L\'association est terminée une fois enregistrée sur les deux appareils.';
  }

  @override
  String pairUnconfirmedTitle(String name) {
    return '$name n\'a pas terminé l\'association';
  }

  @override
  String pairUnconfirmedHint(String name) {
    return 'Vérifiez qu\'AirReply est ouvert sur $name et connecté. S\'il indique déjà que l\'association est faite, continuez.';
  }

  @override
  String get actionKeepWaiting => 'Attendre encore';

  @override
  String get actionPairedThere => 'C\'est associé là-bas';

  @override
  String get actionCancelPairing => 'Annuler l\'association';

  @override
  String get setupAssistantTitle => 'Assistant de configuration';

  @override
  String setupAssistantProgress(int done, int total) {
    return '$done sur $total terminé(s)';
  }

  @override
  String get setupAssistantIntroTitle => 'Garder AirReply en marche';

  @override
  String get setupAssistantIntro =>
      'Tout ce dont cet appareil a besoin pour partager ou afficher les notifications de façon fiable, même en arrière-plan. Se met à jour quand vous changez les réglages.';

  @override
  String get setupNeeded => 'Nécessaire';

  @override
  String get setupRecommended => 'Recommandé';

  @override
  String get setupAllDone => 'Tout est prêt';

  @override
  String get setupAllDoneHint => 'Tout est en place. AirReply continue de fonctionner en arrière-plan.';

  @override
  String get setupCardTitle => 'Terminer la configuration';

  @override
  String get actionNotNow => 'Plus tard';

  @override
  String get actionTurnOn => 'Activer';

  @override
  String get actionAutostartDone => 'Je l\'ai activé';

  @override
  String get taskAccessText =>
      'Permet à AirReply de lire les notifications qu\'il partage. Trouvez AirReply dans la liste et activez-le.';

  @override
  String get taskSharingText => 'Le partage est désactivé : rien n\'arrive sur vos appareils.';

  @override
  String get taskListenerText =>
      'Android a arrêté l\'écouteur de notifications d\'AirReply. Reconnectez-le pour recevoir de nouveau.';

  @override
  String get taskBackgroundTitle => 'Activité en arrière-plan';

  @override
  String get taskBackgroundText =>
      '« Restreindre l\'utilisation en arrière-plan » est activé pour AirReply : Android arrête le partage peu après l\'extinction de l\'écran. Dans les réglages d\'AirReply, ouvrez Batterie et choisissez Non restreinte.';

  @override
  String get taskBatterySamsung =>
      'Sur Samsung, ajoutez aussi AirReply aux applications jamais en veille : Paramètres → Batterie → Limites d\'utilisation en arrière-plan.';

  @override
  String get taskAutostartXiaomi =>
      'Ouvrez Sécurité → Autorisations → Démarrage automatique et activez AirReply. Sans cela, le téléphone arrête AirReply une fois l\'appli fermée.';

  @override
  String get taskAutostartOppo =>
      'Ouvrez Paramètres → Batterie → Gestion de la batterie des applis, choisissez AirReply et autorisez le démarrage automatique et l\'exécution en arrière-plan.';

  @override
  String get taskAutostartVivo =>
      'Ouvrez i Manager → Gestionnaire d\'applis → Démarrage automatique et activez AirReply.';

  @override
  String get taskAutostartHuawei =>
      'Ouvrez Gestionnaire du téléphone → Lancement d\'applis, trouvez AirReply, choisissez Gérer manuellement et activez les trois interrupteurs.';

  @override
  String get taskAlertsText =>
      'Permet à cet appareil de vous alerter à l\'arrivée d\'une notification. Sans cela, les notifications s\'affichent quand même dans l\'appli.';

  @override
  String get taskPairSender => 'Associez un appareil avec lequel partager les notifications de ce téléphone.';

  @override
  String get taskPairReceiver => 'Associez le téléphone dont vous voulez voir les notifications ici.';

  @override
  String get eraseEverythingTitle => 'Tout effacer';

  @override
  String get eraseEverythingSubtitle =>
      'Supprime de cet appareil tous les appareils, l\'historique, les clés et les réglages, et son compte du serveur';

  @override
  String get eraseEverythingConfirmTitle => 'Tout effacer ?';

  @override
  String get eraseEverythingConfirmMessage =>
      'Tous les appareils sont retirés, tout l\'historique (y compris celui conservé) est supprimé, et AirReply repart comme fraîchement installé. Cette action est irréversible.';

  @override
  String get actionErase => 'Effacer';

  @override
  String get receiveWhenClosedTitle => 'Recevoir quand AirReply est fermée';

  @override
  String get receiveWhenClosedText =>
      'Pour les téléphones qui retiennent les alertes une fois AirReply fermée : la garde aussi en réception en arrière-plan. Pendant ce temps, Android affiche une petite notification d’état.';
}
