// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => 'होम';

  @override
  String get tabNotifications => 'सूचनाएँ';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'सूचनाएँ, $count अपठित',
      one: 'सूचनाएँ, 1 अपठित',
      zero: 'सूचनाएँ',
    );
    return '$_temp0';
  }

  @override
  String get tabDevices => 'डिवाइस';

  @override
  String get tabSettings => 'सेटिंग';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count अपठित', zero: 'सब पढ़ लिया');
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => 'आपका फ़ोन,';

  @override
  String get welcomeHeadlineSecond => 'हर जगह।';

  @override
  String get welcomeIntro =>
      'अपने फ़ोन की सूचनाएँ iPhone, iPad, Mac, PC या ब्राउज़र पर पढ़ें, और वहीं से संदेशों का जवाब दें।';

  @override
  String get welcomeEyebrow => 'शुरू करें';

  @override
  String get welcomeQuestion => 'आप इस डिवाइस का उपयोग कैसे करेंगे?';

  @override
  String get roleShareTitle => 'मेरी सूचनाएँ साझा करें';

  @override
  String get roleShareDescription =>
      'यह फ़ोन अपनी सूचनाएँ आपके दूसरे डिवाइस पर भेजता है, और वहाँ लिखे गए जवाब भेजता है।';

  @override
  String get roleShareUnavailable =>
      'केवल Android ऐप्स को सूचनाएँ पढ़ने देता है। साझा करने के लिए Android फ़ोन का उपयोग करें।';

  @override
  String get roleReceiveTitle => 'यहाँ देखें और जवाब दें';

  @override
  String get roleReceiveDescription => 'अपने फ़ोन की सूचनाएँ इस डिवाइस पर देखें और फ़ोन उठाए बिना संदेशों का जवाब दें।';

  @override
  String get errorOffline => 'लगता है आप ऑफ़लाइन हैं। अपना कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get errorServerUnreachable => 'AirReply सर्वर तक नहीं पहुँच सके। अपना कनेक्शन जाँचें।';

  @override
  String get errorSignInRefused => 'साइन-इन अस्वीकार किया गया। क्या Firebase प्रोजेक्ट में Anonymous साइन-इन चालू है?';

  @override
  String get errorSignInFailed => 'साइन-इन विफल रहा।';

  @override
  String get errorSyncFailed => 'जोड़े गए डिवाइस के साथ सिंक विफल रहा।';

  @override
  String get errorPairingCodeNotCreated => 'जोड़ने का कोड नहीं बन सका। कृपया फिर कोशिश करें।';

  @override
  String get errorSessionNotConfirmable => 'इस सत्र की पुष्टि नहीं की जा सकती।';

  @override
  String get errorCodeUnavailable => 'यह कोड अब उपलब्ध नहीं है। दूसरे फ़ोन पर नया कोड बनाएँ।';

  @override
  String get errorCannotPairWithItself => 'कोई डिवाइस खुद से नहीं जुड़ सकता।';

  @override
  String get errorCodeAlreadyUsed => 'यह कोड पहले ही इस्तेमाल हो चुका है।';

  @override
  String get errorNoDeviceJoined => 'अभी तक कोई डिवाइस नहीं जुड़ा है।';

  @override
  String get errorCodeFormat => 'फ़ोन पर दिखाया गया 6 अंकों का कोड दर्ज करें।';

  @override
  String get errorNotAPairingCode => 'यह AirReply का जोड़ने वाला कोड नहीं है।';

  @override
  String get errorCodeNotFound => 'ऐसा कोई कोड नहीं मिला। दूसरे फ़ोन पर कोड जाँचें।';

  @override
  String get errorCodeExpired => 'इस कोड की समय-सीमा खत्म हो गई है। नया कोड बनाएँ।';

  @override
  String get errorQrMismatch => 'QR कोड इस सत्र से मेल नहीं खाता। आपकी सुरक्षा के लिए जोड़ना रोक दिया गया।';

  @override
  String get errorNotConfirmedYet => 'दूसरे फ़ोन ने अभी तक पुष्टि नहीं की है।';

  @override
  String get errorPairingCancelledOnPhone => 'दूसरे फ़ोन पर जोड़ना रद्द कर दिया गया।';

  @override
  String get errorPairingCancelled => 'जोड़ना रद्द हो गया। फिर कोशिश करने के लिए नया कोड बनाएँ।';

  @override
  String get errorPairingNotAvailable => 'यह जोड़ने का सत्र इस डिवाइस के लिए उपलब्ध नहीं है।';

  @override
  String get errorPairingServerFailed => 'सर्वर जोड़ना पूरा नहीं कर सका।';

  @override
  String get errorPairingOffInDemo => 'डेमो मोड में जोड़ना बंद है।';

  @override
  String get errorNotPaired => 'यह डिवाइस अभी जुड़ा नहीं है।';

  @override
  String get errorInvalidPeerKey => 'दूसरे डिवाइस ने अमान्य कुंजी भेजी।';

  @override
  String get errorUnsafePeerKey => 'दूसरे डिवाइस ने असुरक्षित कुंजी भेजी।';

  @override
  String get errorEncryptFailed => 'सूचना एन्क्रिप्ट नहीं हो सकी।';

  @override
  String get errorDecryptFailed => 'सूचना डिक्रिप्ट नहीं हो सकी।';

  @override
  String get errorPayloadUnknown => 'यह सूचना किसी अज्ञात फ़ॉर्मैट में है।';

  @override
  String get errorPayloadForeign => 'यह सूचना इस जोड़ी की कुंजी से नहीं बनी, या इसे बदला गया है।';

  @override
  String get errorNativeServiceFailed => 'Android सूचना सेवा विफल रही।';

  @override
  String get errorNativeServiceUnavailable => 'Android सूचना सेवा उपलब्ध नहीं है।';

  @override
  String get errorReplyEmpty => 'पहले जवाब लिखें।';

  @override
  String get errorReplyTooLong => 'यह जवाब बहुत लंबा है।';

  @override
  String get errorReplyNotPossible => 'इस सूचना का जवाब नहीं दिया जा सकता।';

  @override
  String get errorReplyDismissed => 'यह सूचना आपके फ़ोन पर हटा दी गई थी, इसलिए अब इसका जवाब नहीं दिया जा सकता।';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$total जोड़े गए डिवाइस में से $count तक नहीं पहुँच सके।',
      one: '$total जोड़े गए डिवाइस में से 1 तक नहीं पहुँच सके।',
    );
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message ($detail)';
  }

  @override
  String get errorUnknown => 'कुछ गलत हो गया। कृपया फिर कोशिश करें।';

  @override
  String get errorSharingAndroidOnly => 'सूचनाएँ साझा करना केवल Android पर उपलब्ध है।';

  @override
  String get timeNow => 'अभी';

  @override
  String timeMinutesShort(int n) {
    return '$n मि';
  }

  @override
  String timeHoursShort(int n) {
    return '$n घं';
  }

  @override
  String get timeToday => 'आज';

  @override
  String get timeYesterday => 'कल';

  @override
  String timeAt(String day, String time) {
    return '$day, $time बजे';
  }

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n मिनट पहले', one: '1 मिनट पहले');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n घंटे पहले', one: '1 घंटा पहले');
    return '$_temp0';
  }

  @override
  String get actionUndo => 'पहले जैसा करें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get searchHint => 'खोजें';

  @override
  String get searchClear => 'खोज साफ़ करें';

  @override
  String get splashFailed => 'AirReply शुरू नहीं हो सका';

  @override
  String get actionTryAgain => 'फिर कोशिश करें';

  @override
  String get splashStarting => 'AirReply शुरू हो रहा है';

  @override
  String get firebaseSetupEyebrow => 'सेटअप ज़रूरी है';

  @override
  String get firebaseSetupTitle => 'Firebase कनेक्ट करें';

  @override
  String get firebaseSetupBody =>
      'AirReply आपके अपने Firebase प्रोजेक्ट से आपके डिवाइस सिंक करता है। इसे प्रोजेक्ट फ़ोल्डर में चलाएँ, फिर ऐप दोबारा बनाएँ।';

  @override
  String get actionCopyCommand => 'कमांड कॉपी करें';

  @override
  String get firebaseSetupDetails => 'विवरण';

  @override
  String get deviceConnected => 'कनेक्टेड';

  @override
  String get deviceOffline => 'ऑफ़लाइन';

  @override
  String get deviceConnecting => 'कनेक्ट हो रहा है';

  @override
  String get deviceNeedsAccess => 'अनुमति चाहिए';

  @override
  String get devicePaused => 'रुका हुआ';

  @override
  String get deviceNotReceiving => 'नहीं मिल रहीं';

  @override
  String get deviceReceivingDetail => 'नई सूचनाएँ आते ही यहाँ आती हैं।';

  @override
  String get deviceSharingDetail => 'नई सूचनाएँ आते ही साझा की जाती हैं।';

  @override
  String get deviceOfflineDetail => 'यह डिवाइस फिर ऑनलाइन होने तक सहेजी गई सूचनाएँ दिख रही हैं।';

  @override
  String get deviceConnectingDetail => 'सर्वर से जुड़ रहा है…';

  @override
  String get deviceNeedsAccessDetail => 'सूचना एक्सेस बंद है, इसलिए कुछ भी साझा नहीं हो सकता।';

  @override
  String get devicePausedDetail => 'साझा करना बंद है। सूचनाएँ भेजने के लिए इसे चालू करें।';

  @override
  String get deviceNotReceivingDetail => 'Android ने AirReply का सूचना लिसनर बंद कर दिया।';

  @override
  String get settingsAccessEyebrow => 'एक्सेस';

  @override
  String get settingsPermissionsTitle => 'अनुमतियाँ';

  @override
  String get settingsFilterEyebrow => 'फ़िल्टर';

  @override
  String get settingsAppsTitle => 'ऐप्स';

  @override
  String get settingsPrivacyEyebrow => 'निजता';

  @override
  String get settingsPrivacyTitle => 'मिररिंग और निजता';

  @override
  String get settingsConnectionEyebrow => 'कनेक्शन';

  @override
  String get settingsSyncTitle => 'सिंक';

  @override
  String get settingsAppearanceEyebrow => 'रूप';

  @override
  String get settingsAppearanceTitle => 'रूप और सुलभता';

  @override
  String get settingsDataEyebrow => 'डेटा';

  @override
  String get settingsDataTitle => 'आपका डेटा';

  @override
  String get settingsHelpEyebrow => 'मदद';

  @override
  String get settingsHelpTitle => 'मदद और जानकारी';

  @override
  String get permissionOn => 'चालू';

  @override
  String get actionOpen => 'खोलें';

  @override
  String get actionAllow => 'अनुमति दें';

  @override
  String get permissionAccessTitle => 'सूचना एक्सेस';

  @override
  String get permissionAccessSubtitle => 'सूचनाएँ पढ़ने और साझा करने के लिए ज़रूरी';

  @override
  String get permissionStatusTitle => 'स्थिति सूचना';

  @override
  String get permissionStatusSubtitle => 'रोकें बटन के साथ \"सूचना सिंक चालू है\" दिखाती है';

  @override
  String get permissionBatteryTitle => 'बैटरी ऑप्टिमाइज़ेशन';

  @override
  String get permissionBatteryOk => 'अप्रतिबंधित: Android साझा करना नहीं रोकेगा';

  @override
  String get permissionBatteryFix => '\"अप्रतिबंधित\" पर सेट करें ताकि Android कभी साझा करना न रोके';

  @override
  String get permissionAlertsTitle => 'अलर्ट';

  @override
  String get permissionAlertsBrowser => 'यह ब्राउज़र नई सूचनाएँ दिखा सकेगा';

  @override
  String get permissionAlertsDevice => 'यह डिवाइस आपको नई सूचनाओं के अलर्ट दे सकेगा';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get appsAllShared => 'हर ऐप साझा है';

  @override
  String get appsNoneShared => 'कोई ऐप नहीं चुना: कुछ भी साझा नहीं होता';

  @override
  String get appsToShareTitle => 'साझा करने वाले ऐप्स';

  @override
  String get appsMutedTitle => 'म्यूट किए गए ऐप्स';

  @override
  String get encryptionTitle => 'एंड-टू-एंड एन्क्रिप्टेड';

  @override
  String get encryptionDetail =>
      'हर जोड़ी की अपनी कुंजी होती है, जिस पर दोनों डिवाइस सहमत होते हैं (X25519)। सूचनाएँ और जवाब AES-256-GCM से सील किए जाते हैं। इतिहास आपके डिवाइस पर ही रहता है: सर्वर केवल सिफ़रटेक्स्ट आगे भेजता है और हर संदेश पहुँचते ही उसे मिटा देता है।';

  @override
  String get shareNotificationsTitle => 'सूचनाएँ साझा करें';

  @override
  String get shareNeedsAccess => 'पहले सूचना एक्सेस चालू करें';

  @override
  String get alertTextTitle => 'अलर्ट में संदेश का टेक्स्ट दिखाएँ';

  @override
  String get alertTextSubtitle => 'बंद: अलर्ट में केवल ऐप का नाम, लॉक स्क्रीन और साझा डिस्प्ले के लिए';

  @override
  String get alertsBrowserTitle => 'इस ब्राउज़र में अलर्ट';

  @override
  String get alertsComputerTitle => 'इस कंप्यूटर पर अलर्ट';

  @override
  String get alertsWhileOpen =>
      'AirReply चलते समय नई सूचनाओं के अलर्ट मिलते हैं। इसे खुला रखें (Mac पर विंडो बंद करने पर भी यह चलता रहता है)।';

  @override
  String get syncNoDevices => 'कोई जोड़ा गया डिवाइस नहीं';

  @override
  String get syncStatusTitle => 'सिंक की स्थिति';

  @override
  String get syncChecking => 'कनेक्शन जाँच रहे हैं…';

  @override
  String get actionRefresh => 'रीफ़्रेश करें';

  @override
  String get listenerTitle => 'सूचना लिसनर';

  @override
  String get listenerSubtitle =>
      'डिवाइस को सूचनाएँ मिलना बंद हो जाए तो Android से AirReply का लिसनर फिर जोड़ने को कहें';

  @override
  String get actionReconnect => 'फिर से जोड़ें';

  @override
  String get themeTitle => 'थीम';

  @override
  String get themeSubtitle => 'सिस्टम इस डिवाइस के अनुसार चलता है';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'हल्की';

  @override
  String get themeDark => 'गहरी';

  @override
  String get hapticsTitle => 'हैप्टिक फ़ीडबैक';

  @override
  String get hapticsSubtitle => 'भेजने, बदलने या पुष्टि करने पर हल्का कंपन';

  @override
  String get textSizeTitle => 'टेक्स्ट का आकार';

  @override
  String get textSizeSubtitle => 'AirReply इस डिवाइस पर सेट टेक्स्ट आकार और बोल्ड टेक्स्ट का पालन करता है';

  @override
  String get removeAllConfirmTitle => 'सभी डिवाइस हटाएँ?';

  @override
  String get actionRemoveAll => 'सभी हटाएँ';

  @override
  String get markAllReadTitle => 'सभी को पढ़ा हुआ चिह्नित करें';

  @override
  String get markedAllRead => 'सभी पढ़े हुए चिह्नित किए गए';

  @override
  String get restoreHiddenTitle => 'छिपी सूचनाएँ वापस लाएँ';

  @override
  String get hiddenRestored => 'छिपी सूचनाएँ वापस आ गईं';

  @override
  String get removeAllTitle => 'सभी डिवाइस हटाएँ';

  @override
  String get removeAllSubtitle => 'हर जोड़ी खत्म करता है; उनका इतिहास पिछले डिवाइस में रहता है';

  @override
  String get troubleshootingTitle => 'समस्या निवारण';

  @override
  String get troubleshootingSubtitle => 'सूचनाएँ या जवाब न पहुँचें तो क्या जाँचें';

  @override
  String get diagnosticsTitle => 'डायग्नोस्टिक्स';

  @override
  String get diagnosticsSubtitle => 'जाँचने या साझा करने के लिए कनेक्शन, अनुमति और सिंक का विवरण';

  @override
  String get licencesTitle => 'ओपन-सोर्स लाइसेंस';

  @override
  String get appTagline => 'आपके फ़ोन की सूचनाएँ, हर स्क्रीन पर।';

  @override
  String get syncSharing => 'साझा हो रहा है';

  @override
  String get syncStarting => 'शुरू हो रहा है';

  @override
  String get permissionAutostartTitle => 'ऑटोस्टार्ट';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return '$vendor फ़ोन पर ज़रूरी। Android इसकी जानकारी नहीं दे सकता, इसलिए वहीं जाँचें।';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'केवल $count चुने गए ऐप्स',
      one: 'केवल 1 चुना गया ऐप',
    );
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count म्यूट: ये बिना आवाज़ आते हैं',
      zero: 'हर ऐप आपको अलर्ट दे सकता है',
    );
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state। अभी लाइव।';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state। आखिरी सिंक $ago।';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state। $detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return '$name के साथ सिंक बंद हो जाएगा। उसका इतिहास इस डिवाइस पर पिछले डिवाइस में रहेगा, और फिर से जोड़ने पर वापस आ जाएगा।';
  }

  @override
  String removeAllConfirmMany(int count) {
    return 'सभी $count डिवाइस के साथ सिंक बंद हो जाएगा। उनका इतिहास इस डिवाइस पर पिछले डिवाइस में रहेगा, और फिर से जोड़ने पर वापस आ जाएगा।';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count अपठित', zero: 'कुछ भी अपठित नहीं');
    return '$_temp0';
  }

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस डिवाइस पर $count छिपी हुई',
      zero: 'कुछ भी छिपा नहीं',
    );
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => 'सूचना एक्सेस बंद है';

  @override
  String get noticeAccessOffMessage => 'जब तक आप इसे फिर चालू नहीं करते, AirReply नई सूचनाएँ नहीं देख सकता।';

  @override
  String get actionOpenSettings => 'सेटिंग खोलें';

  @override
  String get noticePausedTitle => 'साझा करना रुका हुआ है';

  @override
  String get noticePausedMessage => 'इस फ़ोन की सूचनाएँ आपके डिवाइस पर नहीं भेजी जा रहीं।';

  @override
  String get actionResumeSharing => 'साझा करना फिर शुरू करें';

  @override
  String get noticeNotReceivingTitle => 'सूचनाएँ नहीं मिल रहीं';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android ने AirReply का लिसनर बंद कर दिया। फिर से जोड़ें, और $vendor फ़ोन पर AirReply के लिए ऑटोस्टार्ट चालू करें ताकि ऐसा दोबारा न हो।';
  }

  @override
  String get noticeNotReceivingMessage =>
      'Android ने AirReply का सूचना लिसनर बंद कर दिया। फिर शुरू करने के लिए दोबारा जोड़ें।';

  @override
  String get noticeBatteryTitle => 'बैटरी ऑप्टिमाइज़ेशन चालू है';

  @override
  String get noticeBatteryMessage =>
      'बैटरी बचाने के लिए Android साझा करना रोक सकता है। AirReply को \"अप्रतिबंधित\" पर सेट करें।';

  @override
  String get actionBatterySettings => 'बैटरी सेटिंग';

  @override
  String get noticeAlertsOffTitle => 'इस डिवाइस पर अलर्ट बंद हैं';

  @override
  String get noticeAlertsOffMessage => 'नई सूचनाएँ यहाँ फिर भी दिखेंगी, लेकिन यह डिवाइस आपको अलर्ट नहीं देगा।';

  @override
  String get actionAllowAlerts => 'अलर्ट की अनुमति दें';

  @override
  String noticeOneOffline(String name) {
    return '$name ऑफ़लाइन है';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count डिवाइस ऑफ़लाइन हैं';
  }

  @override
  String get noticeOfflineMessage => 'सहेजी गई सूचनाएँ दिख रही हैं। यह डिवाइस ऑनलाइन होते ही नई सूचनाएँ आएँगी।';

  @override
  String get actionRetry => 'फिर कोशिश करें';

  @override
  String get setupTitle => 'सेट अप';

  @override
  String get disclosureEyebrow => 'शुरू करने से पहले';

  @override
  String get disclosureTitle => 'AirReply को आपकी सूचनाओं का एक्सेस चाहिए';

  @override
  String get disclosureIntro =>
      'इस फ़ोन की सूचनाएँ आपके जोड़े गए डिवाइस के साथ साझा करने के लिए, AirReply Android की सूचना एक्सेस अनुमति का उपयोग करता है।';

  @override
  String get disclosureWhatTitle => 'किसका एक्सेस होता है';

  @override
  String get disclosureWhatBody =>
      'इस फ़ोन पर दिखने वाली सूचनाएँ: ऐप का नाम, शीर्षक, टेक्स्ट, समय, और मैसेजिंग ऐप्स का जवाब देने वाला बटन। यह बैकग्राउंड में भी काम करता है, AirReply बंद होने पर भी।';

  @override
  String get disclosureWhyTitle => 'क्यों';

  @override
  String get disclosureWhyBody =>
      'केवल उन सूचनाओं को आपके जोड़े गए डिवाइस पर दिखाने के लिए, और वहाँ लिखे जवाबों को इस फ़ोन के मूल ऐप से भेजने के लिए।';

  @override
  String get disclosureHowTitle => 'यह कैसे सुरक्षित है';

  @override
  String get disclosureHowBody =>
      'हर सूचना इस फ़ोन पर AES-256-GCM से एन्क्रिप्ट होती है, ऐसी कुंजी से जो केवल इस फ़ोन और जोड़े गए डिवाइस के पास है। हमारे सर्वर ऐसा सिफ़रटेक्स्ट आगे भेजते हैं जिसे वे पढ़ नहीं सकते, और पहुँचते ही उसे मिटा देते हैं: इतिहास केवल आपके डिवाइस पर रहता है।';

  @override
  String get disclosureControlTitle => 'नियंत्रण आपके पास रहता है';

  @override
  String get disclosureControlBody =>
      'चुनें कि कौन से ऐप साझा हों, स्थिति सूचना से कभी भी रोकें, या साझा करना बंद करने के लिए डिवाइस हटाएँ; उसका इतिहास जब चाहें मिटाएँ। सूचनाओं की सामग्री कभी बेची नहीं जाती, तीसरे पक्ष से साझा नहीं की जाती, और विज्ञापन या एनालिटिक्स के लिए उपयोग नहीं की जाती।';

  @override
  String get actionAgreeAndContinue => 'सहमत हैं और आगे बढ़ें';

  @override
  String get actionNoThanks => 'नहीं, धन्यवाद';

  @override
  String setupProgress(int done, int total) {
    return '$total में से $done ज़रूरी चरण पूरे';
  }

  @override
  String get setupPhoneTitle => 'यह फ़ोन सेट अप करें';

  @override
  String get setupPhoneSubtitle => 'दो अनुमतियों से AirReply सूचनाएँ साझा कर पाता है और बैकग्राउंड में चलता रहता है।';

  @override
  String get setupAccessSubtitle => 'ज़रूरी। सूची में AirReply ढूँढें और इसे चालू करें।';

  @override
  String get setupStatusSubtitle => 'साझा करना चालू रहने पर रोकें बटन के साथ \"सूचना सिंक चालू है\" दिखाती है।';

  @override
  String setupAutostartSubtitle(String vendor) {
    return '$vendor पर ज़रूरी। इसके बिना ऐप बंद होते ही फ़ोन AirReply को सुनने से रोक देता है। AirReply ढूँढें और ऑटोस्टार्ट चालू करें।';
  }

  @override
  String get setupBatterySubtitle =>
      'सुझाया गया। AirReply को \"अप्रतिबंधित\" पर सेट करें ताकि Android कभी साझा करना न रोके।';

  @override
  String get actionContinue => 'आगे बढ़ें';

  @override
  String get setupNeedsAccess => 'आगे बढ़ने के लिए सूचना एक्सेस चालू करें';

  @override
  String get stepDone => 'हो गया';

  @override
  String get pairADevice => 'डिवाइस जोड़ें';

  @override
  String get pairTitle => 'जोड़ें';

  @override
  String get pairAddADevice => 'डिवाइस जोड़ें';

  @override
  String pairPairedWith(String name) {
    return '$name से जुड़ गया';
  }

  @override
  String pairStep(int current, int total) {
    return 'चरण $current/$total';
  }

  @override
  String get pairStopped => 'जोड़ना रुक गया';

  @override
  String get actionMakeNewCode => 'नया कोड बनाएँ';

  @override
  String get pairShowCodeIntro =>
      'अपने iPhone, iPad, Mac, PC, ब्राउज़र या दूसरे Android पर AirReply खोलें, \"यहाँ देखें और जवाब दें\" चुनें, फिर यह कोड स्कैन करें या अंक टाइप करें।';

  @override
  String get pairQrLabel => 'जोड़ने का QR कोड';

  @override
  String get pairOrTypeCode => 'या यह कोड टाइप करें';

  @override
  String pairCodeCopied(String code) {
    return 'कोड $code कॉपी हुआ';
  }

  @override
  String get actionCopyCode => 'कोड कॉपी करें';

  @override
  String get actionNewCode => 'नया कोड';

  @override
  String get pairCodesMatchQuestion => 'क्या कोड मेल खाते हैं?';

  @override
  String pairVerifyWarning(String name) {
    return '$name जुड़ना चाहता है। उस पर ठीक यही कोड दिखना चाहिए। अगर नहीं, तो कोई और जुड़ने की कोशिश कर रहा हो सकता है।';
  }

  @override
  String get actionCodesMatch => 'कोड मेल खाते हैं, जोड़ें';

  @override
  String get actionCodesDoNotMatch => 'मेल नहीं खाते';

  @override
  String get pairAddAnotherPhone => 'दूसरा फ़ोन जोड़ें';

  @override
  String get pairWithYourPhone => 'अपने फ़ोन से जोड़ें';

  @override
  String get pairEnterCodeIntro =>
      'जिस Android फ़ोन को आप यहाँ देखना चाहते हैं, उस पर AirReply खोलें और \"मेरी सूचनाएँ साझा करें\" चुनें (या अगर वह पहले से साझा करता है तो \"डिवाइस जोड़ें\")। वह एक QR कोड और छह अंक दिखाएगा।';

  @override
  String get pairMethodScan => 'स्कैन करें';

  @override
  String get pairMethodType => 'कोड टाइप करें';

  @override
  String get pairCodeLabel => 'जोड़ने का कोड';

  @override
  String get pairStartsOnLastDigit => 'आखिरी अंक टाइप करते ही जोड़ना शुरू हो जाता है।';

  @override
  String get pairConnecting => 'जुड़ रहा है…';

  @override
  String get pairPointCamera => 'कैमरे को अपने फ़ोन पर दिख रहे QR कोड की ओर करें।';

  @override
  String get cameraDenied =>
      'स्कैन करने के लिए AirReply को कैमरा चाहिए। फ़ोन की सेटिंग में इसकी अनुमति दें, या कोड टाइप करें।';

  @override
  String get cameraNotStarted => 'कैमरा शुरू नहीं हुआ।';

  @override
  String pairConfirmOn(String name) {
    return '$name पर पुष्टि करें';
  }

  @override
  String get pairConfirmHint => 'देखें कि आपके फ़ोन पर वही कोड दिख रहा है, फिर वहाँ \"कोड मेल खाते हैं\" पर टैप करें।';

  @override
  String get pairWaitingForPhone => 'आपके फ़ोन का इंतज़ार…';

  @override
  String get pairCodeExpired => 'कोड की समय-सीमा खत्म, नया बना रहे हैं';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return '$minutes:$seconds में समाप्त';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return 'चरण $current/$total: $name';
  }

  @override
  String get pairCouldNotPair => 'जोड़ नहीं सके';

  @override
  String get stepShowCode => 'कोड दिखाएँ';

  @override
  String get stepVerify => 'पुष्टि करें';

  @override
  String get stepEnterCode => 'कोड दर्ज करें';

  @override
  String get notYet => 'अभी नहीं';

  @override
  String get factStatus => 'स्थिति';

  @override
  String get factLive => 'लाइव';

  @override
  String get factLastSynced => 'आखिरी सिंक';

  @override
  String get factNow => 'अभी';

  @override
  String get lastShared => 'आखिरी बार साझा';

  @override
  String get lastNotification => 'आखिरी सूचना';

  @override
  String get factPaired => 'जोड़ा गया';

  @override
  String get factEncryption => 'एन्क्रिप्शन';

  @override
  String get factEncryptionValue => 'एंड-टू-एंड, AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return '$name हटाएँ?';
  }

  @override
  String removeDeviceMessage(String name) {
    return '$name के साथ सिंक दोनों डिवाइस पर बंद हो जाएगा। उसका इतिहास इस डिवाइस पर सेटिंग → पिछले डिवाइस में तब तक रहेगा जब तक आप उसे मिटा नहीं देते। दूसरे डिवाइस पर कोई असर नहीं होगा।';
  }

  @override
  String get actionRemove => 'हटाएँ';

  @override
  String deviceRemoved(String name) {
    return '$name हटाया गया';
  }

  @override
  String get actionTurnOnAccess => 'सूचना एक्सेस चालू करें';

  @override
  String get browseShared => 'आपने जो साझा किया, वह देखें';

  @override
  String get browseHistory => 'सूचनाओं का इतिहास देखें';

  @override
  String get actionRemoveDevice => 'डिवाइस हटाएँ';

  @override
  String get addAPhone => 'फ़ोन जोड़ें';

  @override
  String factWithTime(String label, String time) {
    return '$label $time';
  }

  @override
  String pairedAgo(String time) {
    return '$time जोड़ा गया';
  }

  @override
  String devicesPaired(int count) {
    return '$count जुड़े हुए';
  }

  @override
  String get devicesIntroSender => 'यह फ़ोन अपनी सूचनाएँ इन डिवाइस के साथ साझा करता है।';

  @override
  String get devicesIntroReceiver => 'यह डिवाइस इन फ़ोन की सूचनाएँ दिखाता है।';

  @override
  String get devicesNone => 'कोई डिवाइस नहीं';

  @override
  String get devicesNoneHint => 'शुरू करने के लिए डिवाइस जोड़ें।';

  @override
  String get helpNotArrivingQ => 'सूचनाएँ नहीं आ रहीं';

  @override
  String get helpNotArrivingA =>
      'फ़ोन पर AirReply खोलें और देखें कि \"सूचनाएँ साझा करें\" चालू है और ऐप को बैकग्राउंड में चलने की अनुमति है। दोनों डिवाइस में इंटरनेट होना चाहिए। फिर यहाँ दोबारा कोशिश करें।';

  @override
  String get actionRetrySync => 'फिर सिंक करें';

  @override
  String get helpNoAlertsQ => 'इस डिवाइस पर अलर्ट नहीं आते';

  @override
  String get helpNoAlertsA =>
      'नई सूचनाएँ हमेशा सूचनाएँ टैब में पहुँचती हैं। अलर्ट भी पाने के लिए AirReply को सूचनाओं की अनुमति दें, और देखें कि ऐप सेटिंग → म्यूट किए गए ऐप्स में म्यूट न हो।';

  @override
  String get helpExpiredQ => 'जवाब पर \"फ़ोन पर समाप्त\" लिखा है';

  @override
  String get helpExpiredA =>
      'जवाब फ़ोन पर मौजूद सूचना के ज़रिए भेजे जाते हैं। वहाँ से हटने के बाद, या ऐप के उसे बदल देने पर, उसका जवाब नहीं दिया जा सकता। किसी नई सूचना का जवाब दें, या फ़ोन से दें।';

  @override
  String get helpNotReceivingQ => 'डिवाइस को सूचनाएँ नहीं मिल रहीं';

  @override
  String get helpNotReceivingA =>
      'देखें कि सूचना एक्सेस चालू है और साझा करना रुका नहीं है। अगर Android ने AirReply का लिसनर बंद कर दिया है, तो उसे फिर से जोड़ें।';

  @override
  String get actionReconnectListener => 'लिसनर फिर जोड़ें';

  @override
  String get helpStopsQ => 'कुछ देर बाद साझा करना बंद हो जाता है';

  @override
  String helpStopsAutostartA(String vendor) {
    return '$vendor फ़ोन पर AirReply के लिए ऑटोस्टार्ट चालू करें और उसका बैटरी उपयोग \"अप्रतिबंधित\" पर सेट करें, वरना फ़ोन उसे बैकग्राउंड में रोक देता है।';
  }

  @override
  String get helpStopsA =>
      'AirReply का बैटरी उपयोग \"अप्रतिबंधित\" पर सेट करें ताकि Android उसे बैकग्राउंड में न रोके।';

  @override
  String get helpRepliesQ => 'जवाब नहीं पहुँचते';

  @override
  String get helpRepliesA =>
      'जवाब उसी सूचना के ज़रिए भेजा जाता है जिसका वह जवाब है, इसलिए वह सूचना इस फ़ोन के स्टेटस बार में होनी चाहिए। जो मैसेजिंग ऐप अपनी सूचनाओं में \"जवाब दें\" देते हैं, वे सबसे अच्छे चलते हैं।';

  @override
  String get historyTitle => 'इतिहास';

  @override
  String get historySharedWithIt => 'इसके साथ साझा';

  @override
  String get emptyNothingYet => 'अभी यहाँ कुछ नहीं';

  @override
  String historyEmptySender(String name) {
    return 'यह फ़ोन $name के साथ जो सूचनाएँ साझा करता है, वे यहाँ दिखेंगी।';
  }

  @override
  String historyEmptyReceiver(String name) {
    return '$name की सूचनाएँ यहाँ दिखेंगी।';
  }

  @override
  String get thisPhone => 'यह फ़ोन';

  @override
  String get itDevice => 'इस डिवाइस';

  @override
  String get homeHeadlineSender => 'साझा।';

  @override
  String get homeIntroSender => 'इस फ़ोन की सूचनाएँ आपके दूसरे डिवाइस तक पहुँचती हैं, और उनके जवाब वापस आते हैं।';

  @override
  String get homeIntroReceiver => 'आपके फ़ोन की सूचनाएँ यहाँ आती हैं। उन्हें पढ़ें, और फ़ोन उठाए बिना जवाब दें।';

  @override
  String get searchNotificationsHint => 'सूचनाएँ खोजें';

  @override
  String get homeTodayEyebrow => 'आज';

  @override
  String get homeGlanceTitle => 'एक नज़र में';

  @override
  String get homeRecentEyebrow => 'हाल की गतिविधि';

  @override
  String get homeLatestTitle => 'नई सूचनाएँ';

  @override
  String get actionSeeAll => 'सभी देखें';

  @override
  String get homeRecentEmptySender => 'अभी तक कुछ साझा नहीं हुआ। इस फ़ोन की नई सूचनाएँ यहाँ दिखेंगी।';

  @override
  String get homeRecentEmptyReceiver => 'अभी कुछ नहीं। आपके फ़ोन की नई सूचनाएँ यहाँ दिखेंगी।';

  @override
  String get homeRecentFailed => 'हाल की सूचनाएँ लोड नहीं हो सकीं।';

  @override
  String get homeSharingEyebrow => 'साझा करना';

  @override
  String get homeThisPhoneTitle => 'यह फ़ोन';

  @override
  String get howItWorksEyebrow => 'यह कैसे काम करता है';

  @override
  String get howItWorksSenderTitle => 'एक बार साझा करें। कहीं से भी जवाब दें।';

  @override
  String get howItWorksReceiverTitle => 'तीन चरण। हर स्क्रीन।';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'सूचनाएँ, $count अपठित', zero: 'सूचनाएँ');
    return '$_temp0';
  }

  @override
  String get statToday => 'आज';

  @override
  String get statUnread => 'अपठित';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'डिवाइस', one: 'डिवाइस');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'कोई मेल नहीं';

  @override
  String searchNoMatchesDetail(String query) {
    return 'किसी सूचना या डिवाइस में “$query” नहीं है।';
  }

  @override
  String get searchEyebrow => 'खोज';

  @override
  String get stepShareTitle => 'अपने फ़ोन से साझा करें';

  @override
  String get stepShareText => 'आपके Android फ़ोन पर, AirReply हर सूचना एंड-टू-एंड एन्क्रिप्ट करके यहाँ भेजता है।';

  @override
  String get stepReadTitle => 'यहाँ पढ़ें';

  @override
  String get stepReadText => 'सूचनाएँ कुछ ही सेकंड में आती हैं, ऐप और व्यक्ति के अनुसार समूह में।';

  @override
  String get stepReplyTitle => 'कहीं से भी जवाब दें';

  @override
  String get stepReplyText => 'यहाँ जवाब लिखें; आपका फ़ोन उसे उसी ऐप से भेजता है जिससे सूचना आई थी।';

  @override
  String get stepPickTitle => 'चुनें क्या साझा करना है';

  @override
  String get stepPickText => 'हर ऐप चुनें, या केवल वे जिन्हें आप दूसरे डिवाइस पर चाहते हैं।';

  @override
  String get stepPairTitle => 'अपने डिवाइस जोड़ें';

  @override
  String get stepPairText => 'Mac, PC, iPhone, iPad या ब्राउज़र एक बार कोड स्कैन करता है, और वे जुड़े रहते हैं।';

  @override
  String get stepReplySenderText => 'वहाँ लिखे गए जवाब इस फ़ोन से, उसी ऐप के ज़रिए भेजे जाते हैं।';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चुने गए ऐप्स',
      one: '1 चुना गया ऐप',
    );
    return '$_temp0';
  }

  @override
  String get actionChooseApps => 'ऐप्स चुनें →';

  @override
  String get pairDeviceKinds => 'iPhone, iPad, Mac, PC, ब्राउज़र या Android';

  @override
  String get actionPairArrow => 'जोड़ें →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count फ़ोन', one: '1 फ़ोन');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count डिवाइस', one: '1 डिवाइस');
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return '$names से सूचनाएँ मिल रही हैं।';
  }

  @override
  String statusConnectingTo(String names) {
    return '$names से जुड़ रहा है…';
  }

  @override
  String statusShowingSaved(String names) {
    return '$names की सहेजी गई सूचनाएँ दिख रही हैं।';
  }

  @override
  String get statusLive => 'लाइव। नई सूचनाएँ कुछ ही सेकंड में दिखती हैं।';

  @override
  String statusLastSynced(String ago) {
    return 'आखिरी सिंक $ago।';
  }

  @override
  String get statusNeedsAccess => 'साझा करने के लिए सूचना एक्सेस चाहिए।';

  @override
  String get statusPaused => 'साझा करना रुका हुआ है।';

  @override
  String statusSharingWith(String names) {
    return '$names के साथ साझा हो रहा है।';
  }

  @override
  String get statusNotWorking => 'अभी साझा करना काम नहीं कर रहा।';

  @override
  String get statusEncryptedDetail => 'सूचनाएँ इस फ़ोन से निकलने से पहले यहीं एंड-टू-एंड एन्क्रिप्ट होती हैं।';

  @override
  String get statusOffDetail => 'साझा करना चालू होने तक इस फ़ोन से कुछ भी आपके डिवाइस तक नहीं पहुँचता।';

  @override
  String get encrypted => 'एन्क्रिप्टेड';

  @override
  String get periodAnyTime => 'कभी भी';

  @override
  String get periodToday => 'आज';

  @override
  String get periodWeek => 'पिछले 7 दिन';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count सूचनाएँ', one: '1 सूचना');
    return '$_temp0';
  }

  @override
  String conversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count बातचीत', one: '1 बातचीत');
    return '$_temp0';
  }

  @override
  String messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count संदेश', one: '1 संदेश');
    return '$_temp0';
  }

  @override
  String newNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count नई सूचनाएँ', one: '1 नई सूचना');
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label, $count अपठित';
  }

  @override
  String get nothingHereNow => 'अभी यहाँ कुछ नहीं';

  @override
  String get goneDetail => 'ये सूचनाएँ छिपाई गईं, हटाई गईं, या ऐसे डिवाइस से आई थीं जो अब जुड़ा नहीं है।';

  @override
  String get actionBackToNotifications => 'सूचनाओं पर वापस जाएँ';

  @override
  String get searchConversationsHint => 'नाम, नंबर और संदेश खोजें';

  @override
  String get conversationsEyebrow => 'बातचीत';

  @override
  String conversationsEyebrowCount(int count) {
    return 'बातचीत · $count';
  }

  @override
  String get peopleAndGroups => 'लोग और समूह';

  @override
  String otherNotificationsCount(int count) {
    return 'अन्य सूचनाएँ · $count';
  }

  @override
  String fromApp(String app) {
    return '$app से';
  }

  @override
  String nothingMatchesQuery(String query) {
    return '“$query” से कुछ मेल नहीं खाता।';
  }

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String get notificationGoneDetail => 'यह सूचना हटाई गई, छिपाई गई, या ऐसे डिवाइस की है जो अब जुड़ा नहीं है।';

  @override
  String get markAsUnread => 'अपठित चिह्नित करें';

  @override
  String get markAsRead => 'पढ़ा हुआ चिह्नित करें';

  @override
  String get copyText => 'टेक्स्ट कॉपी करें';

  @override
  String get hideFromDevice => 'इस डिवाइस से छिपाएँ';

  @override
  String get actionHide => 'छिपाएँ';

  @override
  String hideCount(int count) {
    return '$count सूचनाएँ छिपाएँ';
  }

  @override
  String get you => 'आप';

  @override
  String youSaid(String text) {
    return 'आप: $text';
  }

  @override
  String get sentFromPhone => 'आपके फ़ोन से भेजा गया';

  @override
  String get clearedOnPhone => 'फ़ोन पर हटाई गई';

  @override
  String get canReply => 'जवाब दे सकते हैं';

  @override
  String get canBeAnswered => 'जवाब दिया जा सकता है';

  @override
  String get noRepliesInApp => 'इस ऐप में जवाब नहीं';

  @override
  String get replySending => 'भेज रहे हैं';

  @override
  String get replyDelivered => 'पहुँच गया';

  @override
  String get replySent => 'भेजा गया';

  @override
  String get replyExpired => 'फ़ोन पर समाप्त';

  @override
  String get replyNotDelivered => 'नहीं पहुँचा';

  @override
  String get replySendingPrefixed => 'जवाब भेज रहे हैं';

  @override
  String get replyDeliveredPrefixed => 'जवाब पहुँच गया';

  @override
  String get replySentPrefixed => 'जवाब भेजा गया';

  @override
  String get replyExpiredPrefixed => 'जवाब फ़ोन पर समाप्त';

  @override
  String get replyNotDeliveredPrefixed => 'जवाब नहीं पहुँचा';

  @override
  String get yourReply => 'आपका जवाब';

  @override
  String yourReplyAsShown(String app) {
    return 'आपका जवाब, जैसा $app दिखाता है';
  }

  @override
  String get allMarkedRead => 'सभी पढ़े हुए चिह्नित किए गए';

  @override
  String sharedWith(String name) {
    return '$name के साथ साझा';
  }

  @override
  String sharedWithDevices(int count) {
    return '$count डिवाइस के साथ साझा';
  }

  @override
  String fromDevice(String name) {
    return '$name से';
  }

  @override
  String fromPhones(int count) {
    return '$count फ़ोन से';
  }

  @override
  String get markAllRead => 'सभी को पढ़ा हुआ चिह्नित करें';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'फ़िल्टर, $count चालू', zero: 'फ़िल्टर');
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => 'इस खोज या फ़िल्टर से कुछ मेल नहीं खाता।';

  @override
  String get actionClearSearchAndFilters => 'खोज और फ़िल्टर साफ़ करें';

  @override
  String get allCaughtUp => 'सब देख लिया';

  @override
  String get inboxEmptySender =>
      'यह फ़ोन जो सूचनाएँ साझा करता है, वे यहाँ दिखती हैं, आपके डिवाइस से भेजे गए जवाबों के साथ।';

  @override
  String get inboxEmptyReceiver => 'आपके फ़ोन की सूचनाएँ आते ही यहाँ दिखती हैं।';

  @override
  String get inboxAllHidden => 'हर सूचना छिपी हुई है। उन्हें सेटिंग से वापस लाएँ।';

  @override
  String get notificationsLoadFailed => 'सूचनाएँ लोड नहीं हो सकीं';

  @override
  String get removeFilter => 'फ़िल्टर हटाएँ';

  @override
  String get filterUnread => 'अपठित';

  @override
  String get device => 'डिवाइस';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared => 'ये सूचनाएँ आपके फ़ोन पर हटा दी गईं, इसलिए अब यहाँ से इनका जवाब नहीं दिया जा सकता।';

  @override
  String footnoteNoReplies(String app) {
    return '$app इस बातचीत में जवाब स्वीकार नहीं करता।';
  }

  @override
  String get unknownSender => 'अज्ञात भेजने वाला';

  @override
  String get dividerNew => 'नई';

  @override
  String notificationHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सूचनाएँ छिपाई गईं',
      one: 'सूचना छिपाई गई',
    );
    return '$_temp0';
  }

  @override
  String get copied => 'कॉपी हुआ';

  @override
  String get dismissedOnPhone => 'फ़ोन पर हटाई गई';

  @override
  String get moreActions => 'और विकल्प';

  @override
  String get hideConversations => 'बातचीत छिपाएँ';

  @override
  String get showConversations => 'बातचीत दिखाएँ';

  @override
  String unmuteApp(String app) {
    return '$app के अलर्ट अनम्यूट करें';
  }

  @override
  String muteApp(String app) {
    return '$app के अलर्ट म्यूट करें';
  }

  @override
  String get threadChat => 'चैट';

  @override
  String get threadGroup => 'समूह';

  @override
  String get threadNotification => 'सूचना';

  @override
  String get replyHint => 'जवाब दें';

  @override
  String replyToHint(String name) {
    return '$name को जवाब दें';
  }

  @override
  String get sendWithEnter => 'भेजें (Enter)';

  @override
  String get actionSend => 'भेजें';

  @override
  String get filterTitle => 'फ़िल्टर';

  @override
  String get actionClearAll => 'सभी साफ़ करें';

  @override
  String get filterShow => 'दिखाएँ';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterUnreadOnly => 'केवल अपठित';

  @override
  String get filterWhen => 'कब';

  @override
  String get filterSharedWith => 'किसके साथ साझा';

  @override
  String get filterPhone => 'फ़ोन';

  @override
  String get filterApp => 'ऐप';

  @override
  String get filterAllApps => 'सभी ऐप्स';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सूचनाएँ दिखाएँ',
      one: '1 सूचना दिखाएँ',
    );
    return '$_temp0';
  }

  @override
  String get actionShowMore => 'और दिखाएँ';

  @override
  String get browseSharedWithIt => 'इसके साथ जो साझा किया, वह देखें';

  @override
  String get browseItsHistory => 'इसकी सूचनाओं का इतिहास देखें';

  @override
  String get swipeUnread => 'अपठित';

  @override
  String get swipeRead => 'पढ़ा';

  @override
  String get diagnosticsIntro => 'इसमें सूचनाओं का टेक्स्ट या एन्क्रिप्शन कुंजियाँ शामिल नहीं हैं।';

  @override
  String get reportCopied => 'रिपोर्ट कॉपी हुई';

  @override
  String get actionCopyReport => 'रिपोर्ट कॉपी करें';

  @override
  String get checkingAgain => 'फिर जाँच रहे हैं…';

  @override
  String get actionCheckAgain => 'फिर जाँचें';

  @override
  String get diagnosticsReportNote => 'रिपोर्ट अंग्रेज़ी में ही रहती है, ताकि आपकी मदद करने वाला उसे पढ़ सके।';

  @override
  String get welcomeEncryption =>
      'एंड-टू-एंड एन्क्रिप्टेड, ऐसी कुंजी से जो केवल आपके डिवाइस के पास है। सर्वर ऐसा सिफ़रटेक्स्ट आगे भेजता है जिसे वह पढ़ नहीं सकता।';

  @override
  String get theOtherDevice => 'दूसरा डिवाइस';

  @override
  String get appsShareIntro => 'चुनें कि आपके डिवाइस तक क्या पहुँचे। यह AirReply बंद होने पर भी लागू रहता है।';

  @override
  String get appsOnlySelected => 'केवल चुने गए';

  @override
  String get searchApps => 'ऐप्स खोजें';

  @override
  String get appsNothingSelected => 'कुछ नहीं चुना: कोई सूचना साझा नहीं होती';

  @override
  String appsSelected(int count) {
    return '$count चुने गए';
  }

  @override
  String get appsOnlySelectedHint => 'कौन से ऐप आपके डिवाइस तक पहुँचें, यह चुनने के लिए \"केवल चुने गए\" चुनें।';

  @override
  String get appsChoiceLoadFailed => 'आपकी पसंद लोड नहीं हो सकी';

  @override
  String get appsMutedIntro => 'म्यूट किए गए ऐप्स सूचनाओं में फिर भी आते हैं, लेकिन इस डिवाइस पर कभी अलर्ट नहीं देते।';

  @override
  String get appsNoneYet => 'अभी कोई ऐप नहीं';

  @override
  String get appsNoneYetHint => 'आपके फ़ोन से किसी ऐप की सूचना आने पर वह ऐप यहाँ दिखेगा।';

  @override
  String get appMuted => 'म्यूट';

  @override
  String get appAlertsOn => 'अलर्ट चालू';

  @override
  String get appsNoMatch => 'कोई ऐप मेल नहीं खाता';

  @override
  String get appsListFailed => 'ऐप्स की सूची नहीं बन सकी';

  @override
  String get appsReading => 'इंस्टॉल किए गए ऐप्स पढ़ रहे हैं…';

  @override
  String get alertChannelName => 'मिरर की गई सूचनाएँ';

  @override
  String get alertChannelDescription => 'आपके जोड़े गए फ़ोन से मिरर की गई सूचनाएँ';

  @override
  String get alertReply => 'जवाब दें';

  @override
  String get alertReplyHint => 'जवाब…';

  @override
  String get alertOpenApp => 'AirReply खोलें';

  @override
  String get alertNewNotification => 'नई सूचना';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystem => 'इस डिवाइस जैसी';

  @override
  String languageSystemCurrent(String language) {
    return 'इस डिवाइस जैसी ($language)';
  }

  @override
  String get previousDevicesTitle => 'पिछले डिवाइस';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count हटाए गए डिवाइस, इतिहास सुरक्षित',
      one: '1 हटाया गया डिवाइस, इतिहास सुरक्षित',
      zero: 'हटाए गए डिवाइस का इतिहास यहाँ रहता है',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro =>
      'जब आप कोई डिवाइस हटाते हैं, तो उसका इतिहास इस डिवाइस पर रहता है। वहीं से जारी रखने के लिए उसी डिवाइस को फिर से जोड़ें, या इतिहास यहाँ मिटाएँ।';

  @override
  String get previousDevicesNone => 'कोई पिछला डिवाइस नहीं';

  @override
  String get previousDevicesNoneHint => 'आप जो डिवाइस हटाते हैं, उनका इतिहास यहाँ दिखता है।';

  @override
  String previousDeviceSummary(String date, String count) {
    return '$date को हटाया गया · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return '$date को हटाया गया';
  }

  @override
  String previousDeviceContinue(String name) {
    return 'यह इतिहास अपने इनबॉक्स में जारी रखने के लिए $name को फिर से जोड़ें।';
  }

  @override
  String get actionDeleteHistory => 'इतिहास मिटाएँ';

  @override
  String deleteHistoryTitle(String name) {
    return '$name का इतिहास मिटाएँ?';
  }

  @override
  String get deleteHistoryMessage => 'इसकी सूचनाएँ और जवाब इस डिवाइस से मिटा दिए जाएँगे। इसे वापस नहीं लाया जा सकता।';

  @override
  String historyDeleted(String name) {
    return '$name का इतिहास मिटाया गया';
  }

  @override
  String get actionDeleteAll => 'सभी मिटाएँ';

  @override
  String get deleteAllHistoryTitle => 'पिछला पूरा इतिहास मिटाएँ?';

  @override
  String get deleteAllHistoryMessage =>
      'हर हटाए गए डिवाइस का इतिहास इस डिवाइस से मिटा दिया जाएगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get allHistoryDeleted => 'पिछला इतिहास मिटाया गया';

  @override
  String get feedbackReportTitle => 'समस्या बताएँ';

  @override
  String get feedbackReportSubtitle => 'कुछ काम नहीं कर रहा? हमें बताएँ क्या हुआ';

  @override
  String get feedbackIdeaTitle => 'सुविधा सुझाएँ';

  @override
  String get feedbackIdeaSubtitle => 'ऐसा विचार जो AirReply को बेहतर बनाए';

  @override
  String get feedbackKindLabel => 'प्रकार';

  @override
  String get feedbackKindProblem => 'समस्या';

  @override
  String get feedbackKindIdea => 'सुविधा का विचार';

  @override
  String get feedbackAreaLabel => 'यह किस बारे में है?';

  @override
  String get feedbackAreaNotifications => 'सूचनाएँ';

  @override
  String get feedbackAreaReplies => 'जवाब';

  @override
  String get feedbackAreaPairing => 'जोड़ना';

  @override
  String get feedbackAreaAlerts => 'अलर्ट';

  @override
  String get feedbackAreaSync => 'सिंक';

  @override
  String get feedbackAreaDesign => 'रूप-रंग';

  @override
  String get feedbackAreaOther => 'कुछ और';

  @override
  String get feedbackMessageLabel => 'आपका संदेश';

  @override
  String get feedbackProblemHint => 'क्या हुआ, और आप क्या उम्मीद कर रहे थे? इसे दोबारा करने के चरण बहुत मदद करते हैं।';

  @override
  String get feedbackIdeaHint => 'आप AirReply से क्या करवाना चाहेंगे, और इससे आपको कैसे मदद मिलेगी?';

  @override
  String get feedbackTooShort => 'थोड़ा और लिखें (कम से कम 10 अक्षर)।';

  @override
  String get feedbackIncludeDetails => 'डिवाइस की जानकारी शामिल करें';

  @override
  String get feedbackDetailsSubtitle => 'सिस्टम, डिवाइस मॉडल, ऐप की भाषा और भूमिका। आपकी सूचनाएँ या कुंजियाँ कभी नहीं।';

  @override
  String get feedbackSent => 'धन्यवाद! आपका ईमेल ऐप तैयार है: पूरा करने के लिए वहाँ भेजें पर टैप करें।';

  @override
  String get feedbackNoEmailApp => 'इस डिवाइस पर कोई ईमेल ऐप सेट नहीं है।';
}
