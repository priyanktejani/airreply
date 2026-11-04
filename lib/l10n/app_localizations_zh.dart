// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => '首页';

  @override
  String get tabNotifications => '通知';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '通知，$count 条未读', zero: '通知');
    return '$_temp0';
  }

  @override
  String get tabDevices => '设备';

  @override
  String get tabSettings => '设置';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条未读', zero: '全部已读');
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => '你的手机，';

  @override
  String get welcomeHeadlineSecond => '无处不在。';

  @override
  String get welcomeIntro => '在 iPhone、iPad、Mac、PC 或浏览器上查看手机通知，并直接回复消息。';

  @override
  String get welcomeEyebrow => '开始使用';

  @override
  String get welcomeQuestion => '你打算如何使用这台设备？';

  @override
  String get roleShareTitle => '共享我的通知';

  @override
  String get roleShareDescription => '这部手机会把通知发送到你的其他设备，并发出你在那里写的回复。';

  @override
  String get roleShareUnavailable => '只有 Android 允许应用读取通知。请使用 Android 手机来共享。';

  @override
  String get roleReceiveTitle => '在这里查看和回复';

  @override
  String get roleReceiveDescription => '在这台设备上查看手机通知，不用拿起手机就能回复消息。';

  @override
  String get errorOffline => '你似乎已离线。请检查网络连接后重试。';

  @override
  String get errorServerUnreachable => '无法连接 AirReply 服务器。请检查网络连接。';

  @override
  String get errorSignInRefused => '登录被拒绝。Firebase 项目中是否已启用匿名登录？';

  @override
  String get errorSignInFailed => '登录失败。';

  @override
  String get errorSyncFailed => '与已配对设备同步失败。';

  @override
  String get errorPairingCodeNotCreated => '无法生成配对码。请重试。';

  @override
  String get errorSessionNotConfirmable => '无法确认此会话。';

  @override
  String get errorCodeUnavailable => '此配对码已失效。请在另一部手机上生成新的配对码。';

  @override
  String get errorCannotPairWithItself => '设备不能与自己配对。';

  @override
  String get errorCodeAlreadyUsed => '此配对码已被使用。';

  @override
  String get errorNoDeviceJoined => '还没有设备加入。';

  @override
  String get errorCodeFormat => '请输入手机上显示的 6 位数字。';

  @override
  String get errorNotAPairingCode => '这不是 AirReply 配对码。';

  @override
  String get errorCodeNotFound => '找不到这个配对码。请检查另一部手机上的配对码。';

  @override
  String get errorCodeExpired => '此配对码已过期。请生成新的配对码。';

  @override
  String get errorQrMismatch => '二维码与此会话不符。为了你的安全，已停止配对。';

  @override
  String get errorNotConfirmedYet => '另一部手机尚未确认。';

  @override
  String get errorPairingCancelledOnPhone => '另一部手机已取消配对。';

  @override
  String get errorPairingCancelled => '配对已取消。请生成新的配对码重试。';

  @override
  String get errorPairingNotAvailable => '此配对会话不适用于这台设备。';

  @override
  String get errorPairingServerFailed => '服务器无法完成配对。';

  @override
  String get errorPairingOffInDemo => '演示模式下无法配对。';

  @override
  String get errorNotPaired => '这台设备尚未配对。';

  @override
  String get errorInvalidPeerKey => '另一台设备发送了无效的密钥。';

  @override
  String get errorUnsafePeerKey => '另一台设备发送了不安全的密钥。';

  @override
  String get errorEncryptFailed => '无法加密通知。';

  @override
  String get errorDecryptFailed => '无法解密通知。';

  @override
  String get errorPayloadUnknown => '此通知的格式无法识别。';

  @override
  String get errorPayloadForeign => '此通知不是用本配对的密钥生成的，或已被篡改。';

  @override
  String get errorNativeServiceFailed => 'Android 通知服务出错。';

  @override
  String get errorNativeServiceUnavailable => 'Android 通知服务不可用。';

  @override
  String get errorReplyEmpty => '请先输入回复。';

  @override
  String get errorReplyTooLong => '回复太长了。';

  @override
  String get errorReplyNotPossible => '无法回复此通知。';

  @override
  String get errorReplyDismissed => '此通知已在手机上清除，无法再回复。';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '无法连接 $total 台已配对设备中的 $count 台。');
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message（$detail）';
  }

  @override
  String get errorUnknown => '出了点问题。请重试。';

  @override
  String get errorSharingAndroidOnly => '只有 Android 可以共享通知。';

  @override
  String get timeNow => '刚刚';

  @override
  String timeMinutesShort(int n) {
    return '$n分钟';
  }

  @override
  String timeHoursShort(int n) {
    return '$n小时';
  }

  @override
  String get timeToday => '今天';

  @override
  String get timeYesterday => '昨天';

  @override
  String timeAt(String day, String time) {
    return '$day $time';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n 分钟前');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n 小时前');
    return '$_temp0';
  }

  @override
  String get actionUndo => '撤销';

  @override
  String get actionCancel => '取消';

  @override
  String get searchHint => '搜索';

  @override
  String get searchClear => '清除搜索';

  @override
  String get splashFailed => 'AirReply 无法启动';

  @override
  String get actionTryAgain => '重试';

  @override
  String get splashStarting => 'AirReply 正在启动';

  @override
  String get firebaseSetupEyebrow => '需要设置';

  @override
  String get firebaseSetupTitle => '连接 Firebase';

  @override
  String get firebaseSetupBody => 'AirReply 通过你自己的 Firebase 项目同步设备。请在项目文件夹中运行此命令，然后重新构建应用。';

  @override
  String get actionCopyCommand => '复制命令';

  @override
  String get firebaseSetupDetails => '详细信息';

  @override
  String get deviceConnected => '已连接';

  @override
  String get deviceOffline => '离线';

  @override
  String get deviceConnecting => '正在连接';

  @override
  String get deviceNeedsAccess => '需要权限';

  @override
  String get devicePaused => '已暂停';

  @override
  String get deviceNotReceiving => '未在接收';

  @override
  String get deviceReceivingDetail => '新通知会实时送达。';

  @override
  String get deviceSharingDetail => '新通知一到就会共享。';

  @override
  String get deviceOfflineDetail => '在这台设备恢复联网前，显示已保存的通知。';

  @override
  String get deviceConnectingDetail => '正在连接服务器…';

  @override
  String get deviceNeedsAccessDetail => '通知使用权已关闭，因此无法共享任何内容。';

  @override
  String get devicePausedDetail => '共享已关闭。打开后才会发送通知。';

  @override
  String get deviceNotReceivingDetail => 'Android 停止了 AirReply 的通知监听器。';

  @override
  String get settingsAccessEyebrow => '权限';

  @override
  String get settingsPermissionsTitle => '权限';

  @override
  String get settingsFilterEyebrow => '筛选';

  @override
  String get settingsAppsTitle => '应用';

  @override
  String get settingsPrivacyEyebrow => '隐私';

  @override
  String get settingsPrivacyTitle => '镜像与隐私';

  @override
  String get settingsConnectionEyebrow => '连接';

  @override
  String get settingsSyncTitle => '同步';

  @override
  String get settingsAppearanceEyebrow => '外观';

  @override
  String get settingsAppearanceTitle => '外观与辅助功能';

  @override
  String get settingsDataEyebrow => '数据';

  @override
  String get settingsDataTitle => '你的数据';

  @override
  String get settingsHelpEyebrow => '帮助';

  @override
  String get settingsHelpTitle => '帮助与关于';

  @override
  String get permissionOn => '已开启';

  @override
  String get actionOpen => '打开';

  @override
  String get actionAllow => '允许';

  @override
  String get permissionAccessTitle => '通知使用权';

  @override
  String get permissionAccessSubtitle => '读取和共享通知所必需';

  @override
  String get permissionStatusTitle => '状态通知';

  @override
  String get permissionStatusSubtitle => '显示带有“暂停”按钮的“通知同步已开启”';

  @override
  String get permissionBatteryTitle => '电池优化';

  @override
  String get permissionBatteryOk => '不受限制：Android 不会暂停共享';

  @override
  String get permissionBatteryFix => '设为“不受限制”，Android 就不会暂停共享';

  @override
  String get permissionAlertsTitle => '提醒';

  @override
  String get permissionAlertsBrowser => '允许此浏览器显示新通知';

  @override
  String get permissionAlertsDevice => '允许这台设备提醒你新通知';

  @override
  String get loading => '正在加载…';

  @override
  String get appsAllShared => '共享所有应用';

  @override
  String get appsNoneShared => '未选择应用：不会共享任何内容';

  @override
  String get appsToShareTitle => '要共享的应用';

  @override
  String get appsMutedTitle => '已静音的应用';

  @override
  String get encryptionTitle => '端到端加密';

  @override
  String get encryptionDetail =>
      '每对设备都有自己的密钥，由两台设备协商生成（X25519）。通知和回复使用 AES-256-GCM 加密。历史记录只保存在你的设备上：服务器只转发密文，并在每条消息送达后将其删除。';

  @override
  String get shareNotificationsTitle => '共享通知';

  @override
  String get shareNeedsAccess => '请先开启通知使用权';

  @override
  String get alertTextTitle => '在提醒中显示消息内容';

  @override
  String get alertTextSubtitle => '关闭时提醒只显示应用名称，适合锁屏和共享屏幕';

  @override
  String get alertsBrowserTitle => '此浏览器中的提醒';

  @override
  String get alertsComputerTitle => '这台电脑上的提醒';

  @override
  String get alertsWhileOpen => 'AirReply 运行时会提醒你新通知。请保持打开（在 Mac 上关闭窗口后它仍会运行）。';

  @override
  String get syncNoDevices => '没有已配对的设备';

  @override
  String get syncStatusTitle => '同步状态';

  @override
  String get syncChecking => '正在检查连接…';

  @override
  String get actionRefresh => '刷新';

  @override
  String get listenerTitle => '通知监听器';

  @override
  String get listenerSubtitle => '如果设备收不到通知，请让 Android 重新连接 AirReply 的监听器';

  @override
  String get actionReconnect => '重新连接';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSubtitle => '“系统”跟随这台设备';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get hapticsTitle => '触感反馈';

  @override
  String get hapticsSubtitle => '发送、切换或确认时轻微振动';

  @override
  String get textSizeTitle => '文字大小';

  @override
  String get textSizeSubtitle => 'AirReply 跟随这台设备设置的文字大小和粗体文字';

  @override
  String get removeAllConfirmTitle => '移除所有设备？';

  @override
  String get actionRemoveAll => '全部移除';

  @override
  String get markAllReadTitle => '全部标为已读';

  @override
  String get markedAllRead => '已全部标为已读';

  @override
  String get restoreHiddenTitle => '恢复隐藏的通知';

  @override
  String get hiddenRestored => '已恢复隐藏的通知';

  @override
  String get removeAllTitle => '移除所有设备';

  @override
  String get removeAllSubtitle => '结束所有配对；它们的历史记录保留在“以前的设备”中';

  @override
  String get troubleshootingTitle => '故障排除';

  @override
  String get troubleshootingSubtitle => '通知或回复没有送达时该检查什么';

  @override
  String get diagnosticsTitle => '诊断';

  @override
  String get diagnosticsSubtitle => '可查看或分享的连接、权限和同步详情';

  @override
  String get licencesTitle => '开源许可';

  @override
  String get appTagline => '手机通知，尽在每块屏幕。';

  @override
  String get syncSharing => '正在共享';

  @override
  String get syncStarting => '正在启动';

  @override
  String get permissionAutostartTitle => '自启动';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return '$vendor 手机必需。Android 无法报告此设置，请在系统设置中检查。';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '仅 $count 个已选应用');
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个已静音：通知会静默送达', zero: '所有应用都会提醒你');
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state。实时连接中。';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state。上次同步：$ago。';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state。$detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return '将停止与 $name 同步。它的历史记录会保留在这台设备的“以前的设备”中，重新配对后会恢复。';
  }

  @override
  String removeAllConfirmMany(int count) {
    return '将停止与全部 $count 台设备同步。它们的历史记录会保留在这台设备的“以前的设备”中，重新配对后会恢复。';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条未读', zero: '没有未读');
    return '$_temp0';
  }

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '在这台设备上隐藏了 $count 条', zero: '没有隐藏的通知');
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => '通知使用权已关闭';

  @override
  String get noticeAccessOffMessage => '重新开启前，AirReply 无法看到新通知。';

  @override
  String get actionOpenSettings => '打开设置';

  @override
  String get noticePausedTitle => '共享已暂停';

  @override
  String get noticePausedMessage => '这部手机的通知没有发送到你的设备。';

  @override
  String get actionResumeSharing => '恢复共享';

  @override
  String get noticeNotReceivingTitle => '未收到通知';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android 停止了 AirReply 的监听器。请重新连接，并在 $vendor 手机上为 AirReply 开启自启动，以免再次发生。';
  }

  @override
  String get noticeNotReceivingMessage => 'Android 停止了 AirReply 的通知监听器。重新连接即可恢复。';

  @override
  String get noticeBatteryTitle => '电池优化已开启';

  @override
  String get noticeBatteryMessage => 'Android 可能会为了省电暂停共享。请将 AirReply 设为“不受限制”。';

  @override
  String get actionBatterySettings => '电池设置';

  @override
  String get noticeAlertsOffTitle => '这台设备的提醒已关闭';

  @override
  String get noticeAlertsOffMessage => '新通知仍会显示在这里，但这台设备不会提醒你。';

  @override
  String get actionAllowAlerts => '允许提醒';

  @override
  String noticeOneOffline(String name) {
    return '$name 已离线';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count 台设备已离线';
  }

  @override
  String get noticeOfflineMessage => '正在显示已保存的通知。这台设备恢复联网后，新通知就会送达。';

  @override
  String get actionRetry => '重试';

  @override
  String get setupTitle => '设置';

  @override
  String get disclosureEyebrow => '开始之前';

  @override
  String get disclosureTitle => 'AirReply 需要访问你的通知';

  @override
  String get disclosureIntro => '为了把这部手机的通知共享到已配对的设备，AirReply 会使用 Android 的通知使用权。';

  @override
  String get disclosureWhatTitle => '会访问什么';

  @override
  String get disclosureWhatBody => '这部手机上显示的通知：应用名称、标题、内容、时间，以及聊天应用的回复操作。即使 AirReply 已关闭，也会在后台运行。';

  @override
  String get disclosureWhyTitle => '为什么';

  @override
  String get disclosureWhyBody => '仅用于在你配对的设备上显示这些通知，并通过这部手机上的原应用发出你在那里输入的回复。';

  @override
  String get disclosureHowTitle => '如何保护';

  @override
  String get disclosureHowBody =>
      '每条通知都在这部手机上用 AES-256-GCM 加密，密钥只有这部手机和已配对的设备持有。我们的服务器只转发它们无法读取的密文，并在送达后删除：历史记录只保存在你的设备上。';

  @override
  String get disclosureControlTitle => '一切由你掌控';

  @override
  String get disclosureControlBody => '你可以选择共享哪些应用，随时在状态通知中暂停，或移除设备以停止共享；历史记录可随时删除。通知内容绝不会被出售、与第三方共享，或用于广告和分析。';

  @override
  String get actionAgreeAndContinue => '同意并继续';

  @override
  String get actionNoThanks => '不用了';

  @override
  String setupProgress(int done, int total) {
    return '已完成 $done/$total 个必需步骤';
  }

  @override
  String get setupPhoneTitle => '设置这部手机';

  @override
  String get setupPhoneSubtitle => '两项权限让 AirReply 能共享通知并在后台持续运行。';

  @override
  String get setupAccessSubtitle => '必需。在列表中找到 AirReply 并打开。';

  @override
  String get setupStatusSubtitle => '共享开启时，显示带有“暂停”按钮的“通知同步已开启”。';

  @override
  String setupAutostartSubtitle(String vendor) {
    return '$vendor 手机必需。否则应用关闭后，手机会阻止 AirReply 监听。找到 AirReply 并开启自启动。';
  }

  @override
  String get setupBatterySubtitle => '建议。将 AirReply 设为“不受限制”，Android 就不会暂停共享。';

  @override
  String get actionContinue => '继续';

  @override
  String get setupNeedsAccess => '开启通知使用权后才能继续';

  @override
  String get stepDone => '已完成';

  @override
  String get pairADevice => '配对设备';

  @override
  String get pairTitle => '配对';

  @override
  String get pairAddADevice => '添加设备';

  @override
  String pairPairedWith(String name) {
    return '已与 $name 配对';
  }

  @override
  String pairStep(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get pairStopped => '配对已停止';

  @override
  String get actionMakeNewCode => '生成新配对码';

  @override
  String get pairShowCodeIntro => '在你的 iPhone、iPad、Mac、PC、浏览器或另一部 Android 上打开 AirReply，选择“在这里查看和回复”，然后扫描此二维码或输入数字。';

  @override
  String get pairQrLabel => '配对二维码';

  @override
  String get pairOrTypeCode => '或输入此配对码';

  @override
  String pairCodeCopied(String code) {
    return '已复制配对码 $code';
  }

  @override
  String get actionCopyCode => '复制配对码';

  @override
  String get actionNewCode => '新配对码';

  @override
  String get pairCodesMatchQuestion => '两边的码一致吗？';

  @override
  String pairVerifyWarning(String name) {
    return '$name 请求配对。它必须显示完全相同的码。如果不同，可能有其他人试图连接。';
  }

  @override
  String get actionCodesMatch => '一致，配对';

  @override
  String get actionCodesDoNotMatch => '不一致';

  @override
  String get pairAddAnotherPhone => '添加另一部手机';

  @override
  String get pairWithYourPhone => '与你的手机配对';

  @override
  String get pairEnterCodeIntro => '在你想在这里查看的 Android 手机上打开 AirReply，选择“共享我的通知”（如果已在共享，则选择“添加设备”）。它会显示一个二维码和六位数字。';

  @override
  String get pairMethodScan => '扫描';

  @override
  String get pairMethodType => '输入配对码';

  @override
  String get pairCodeLabel => '配对码';

  @override
  String get pairStartsOnLastDigit => '输入最后一位数字后立即开始配对。';

  @override
  String get pairConnecting => '正在连接…';

  @override
  String get pairPointCamera => '将摄像头对准手机上的二维码。';

  @override
  String get cameraDenied => 'AirReply 需要使用摄像头来扫描。请在手机设置中允许，或改为输入配对码。';

  @override
  String get cameraNotStarted => '摄像头未能启动。';

  @override
  String pairConfirmOn(String name) {
    return '在 $name 上确认';
  }

  @override
  String get pairConfirmHint => '确认手机上显示的码相同，然后在手机上点按“一致”。';

  @override
  String get pairWaitingForPhone => '正在等待你的手机…';

  @override
  String get pairCodeExpired => '配对码已过期，正在生成新的';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return '$minutes:$seconds 后过期';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return '第 $current 步，共 $total 步：$name';
  }

  @override
  String get pairCouldNotPair => '无法配对';

  @override
  String get stepShowCode => '显示配对码';

  @override
  String get stepVerify => '验证';

  @override
  String get stepEnterCode => '输入配对码';

  @override
  String get notYet => '尚无';

  @override
  String get factStatus => '状态';

  @override
  String get factLive => '实时';

  @override
  String get factLastSynced => '上次同步';

  @override
  String get factNow => '现在';

  @override
  String get lastShared => '上次共享';

  @override
  String get lastNotification => '最新通知';

  @override
  String get factPaired => '配对时间';

  @override
  String get factEncryption => '加密';

  @override
  String get factEncryptionValue => '端到端，AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return '移除 $name？';
  }

  @override
  String removeDeviceMessage(String name) {
    return '两台设备都会停止与 $name 同步。它的历史记录会保留在这台设备的“设置 → 以前的设备”中，直到你删除为止。其他设备不受影响。';
  }

  @override
  String get actionRemove => '移除';

  @override
  String deviceRemoved(String name) {
    return '已移除 $name';
  }

  @override
  String get actionTurnOnAccess => '开启通知使用权';

  @override
  String get browseShared => '浏览你共享的内容';

  @override
  String get browseHistory => '浏览通知历史';

  @override
  String get actionRemoveDevice => '移除设备';

  @override
  String get addAPhone => '添加手机';

  @override
  String factWithTime(String label, String time) {
    return '$label $time';
  }

  @override
  String pairedAgo(String time) {
    return '配对于 $time';
  }

  @override
  String devicesPaired(int count) {
    return '已配对 $count 台';
  }

  @override
  String get devicesIntroSender => '这部手机会把通知共享到这些设备。';

  @override
  String get devicesIntroReceiver => '这台设备显示来自这些手机的通知。';

  @override
  String get devicesNone => '没有设备';

  @override
  String get devicesNoneHint => '配对一台设备即可开始。';

  @override
  String get helpNotArrivingQ => '收不到通知';

  @override
  String get helpNotArrivingA => '在手机上打开 AirReply，确认“共享通知”已开启，并且应用可以在后台运行。两台设备都需要联网。然后在这里重试。';

  @override
  String get actionRetrySync => '重新同步';

  @override
  String get helpNoAlertsQ => '这台设备没有提醒';

  @override
  String get helpNoAlertsA => '新通知总会出现在“通知”标签页中。如果也想收到提醒，请允许 AirReply 发送通知，并确认该应用没有在“设置 → 已静音的应用”中被静音。';

  @override
  String get helpExpiredQ => '回复显示“已在手机上失效”';

  @override
  String get helpExpiredA => '回复是通过手机上的通知发出的。一旦通知在手机上被清除或被应用替换，就无法再回复。请回复更新的通知，或直接在手机上回复。';

  @override
  String get helpNotReceivingQ => '设备收不到通知';

  @override
  String get helpNotReceivingA => '确认通知使用权已开启且共享没有暂停。如果 Android 停止了 AirReply 的监听器，请重新连接。';

  @override
  String get actionReconnectListener => '重新连接监听器';

  @override
  String get helpStopsQ => '过一段时间后共享就停止了';

  @override
  String helpStopsAutostartA(String vendor) {
    return '在 $vendor 手机上，请为 AirReply 开启自启动并将其电池使用设为“不受限制”，否则手机会在后台停止它。';
  }

  @override
  String get helpStopsA => '将 AirReply 的电池使用设为“不受限制”，这样 Android 就不会在后台暂停它。';

  @override
  String get helpRepliesQ => '回复没有送达';

  @override
  String get helpRepliesA => '回复是通过所回复的那条通知发出的，因此该通知必须仍在这部手机的状态栏中。在通知中提供“回复”的聊天应用效果最好。';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historySharedWithIt => '共享给它的内容';

  @override
  String get emptyNothingYet => '这里还没有内容';

  @override
  String historyEmptySender(String name) {
    return '这部手机共享给 $name 的通知会显示在这里。';
  }

  @override
  String historyEmptyReceiver(String name) {
    return '来自 $name 的通知会显示在这里。';
  }

  @override
  String get thisPhone => '这部手机';

  @override
  String get itDevice => '它';

  @override
  String get homeHeadlineSender => '已共享。';

  @override
  String get homeIntroSender => '这部手机的通知会送达你的其他设备，回复也会传回来。';

  @override
  String get homeIntroReceiver => '手机的通知会出现在这里。阅读通知，不用拿起手机就能回复。';

  @override
  String get searchNotificationsHint => '搜索通知';

  @override
  String get homeTodayEyebrow => '今天';

  @override
  String get homeGlanceTitle => '概览';

  @override
  String get homeRecentEyebrow => '最近动态';

  @override
  String get homeLatestTitle => '最新通知';

  @override
  String get actionSeeAll => '查看全部';

  @override
  String get homeRecentEmptySender => '还没有共享内容。这部手机的新通知会显示在这里。';

  @override
  String get homeRecentEmptyReceiver => '还没有内容。来自手机的新通知会显示在这里。';

  @override
  String get homeRecentFailed => '无法加载最近的通知。';

  @override
  String get homeSharingEyebrow => '共享';

  @override
  String get homeThisPhoneTitle => '这部手机';

  @override
  String get howItWorksEyebrow => '使用方法';

  @override
  String get howItWorksSenderTitle => '共享一次，随处回复。';

  @override
  String get howItWorksReceiverTitle => '三个步骤，每块屏幕。';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '通知，$count 条未读', zero: '通知');
    return '$_temp0';
  }

  @override
  String get statToday => '今天';

  @override
  String get statUnread => '未读';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '设备');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => '没有匹配项';

  @override
  String searchNoMatchesDetail(String query) {
    return '没有通知或设备包含“$query”。';
  }

  @override
  String get searchEyebrow => '搜索';

  @override
  String get stepShareTitle => '从手机共享';

  @override
  String get stepShareText => '在你的 Android 手机上，AirReply 会将每条通知端到端加密后发送到这里。';

  @override
  String get stepReadTitle => '在这里阅读';

  @override
  String get stepReadText => '通知几秒内送达，并按应用和联系人分组。';

  @override
  String get stepReplyTitle => '随处回复';

  @override
  String get stepReplyText => '在这里写下回复；手机会通过原应用发出。';

  @override
  String get stepPickTitle => '选择要共享的内容';

  @override
  String get stepPickText => '选择所有应用，或只选你想在其他设备上看到的应用。';

  @override
  String get stepPairTitle => '配对你的设备';

  @override
  String get stepPairText => 'Mac、PC、iPhone、iPad 或浏览器只需扫描一次配对码，之后会保持配对。';

  @override
  String get stepReplySenderText => '在那里写的回复会由这部手机通过对应的应用发出。';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '已选 $count 个应用');
    return '$_temp0';
  }

  @override
  String get actionChooseApps => '选择应用 →';

  @override
  String get pairDeviceKinds => 'iPhone、iPad、Mac、PC、浏览器或 Android';

  @override
  String get actionPairArrow => '配对 →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 部手机');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 台设备');
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return '正在接收来自 $names 的通知。';
  }

  @override
  String statusConnectingTo(String names) {
    return '正在连接 $names…';
  }

  @override
  String statusShowingSaved(String names) {
    return '正在显示来自 $names 的已保存通知。';
  }

  @override
  String get statusLive => '实时连接中。新通知几秒内就会出现。';

  @override
  String statusLastSynced(String ago) {
    return '上次同步：$ago。';
  }

  @override
  String get statusNeedsAccess => '共享需要通知使用权。';

  @override
  String get statusPaused => '共享已暂停。';

  @override
  String statusSharingWith(String names) {
    return '正在与 $names 共享。';
  }

  @override
  String get statusNotWorking => '共享目前无法正常工作。';

  @override
  String get statusEncryptedDetail => '通知在离开这部手机前就已端到端加密。';

  @override
  String get statusOffDetail => '共享开启前，这部手机的任何内容都不会送达你的设备。';

  @override
  String get encrypted => '已加密';

  @override
  String get periodAnyTime => '任何时间';

  @override
  String get periodToday => '今天';

  @override
  String get periodWeek => '最近 7 天';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条通知');
    return '$_temp0';
  }

  @override
  String conversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 个对话');
    return '$_temp0';
  }

  @override
  String messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条消息');
    return '$_temp0';
  }

  @override
  String newNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count 条新通知');
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label，$count 条未读';
  }

  @override
  String get nothingHereNow => '这里暂时没有内容';

  @override
  String get goneDetail => '这些通知已被隐藏、移除，或来自一台已不再配对的设备。';

  @override
  String get actionBackToNotifications => '返回通知';

  @override
  String get searchConversationsHint => '搜索姓名、号码和消息';

  @override
  String get conversationsEyebrow => '对话';

  @override
  String conversationsEyebrowCount(int count) {
    return '对话 · $count';
  }

  @override
  String get peopleAndGroups => '联系人和群组';

  @override
  String otherNotificationsCount(int count) {
    return '其他通知 · $count';
  }

  @override
  String fromApp(String app) {
    return '来自 $app';
  }

  @override
  String nothingMatchesQuery(String query) {
    return '没有与“$query”匹配的内容。';
  }

  @override
  String get notAvailable => '不可用';

  @override
  String get notificationGoneDetail => '此通知已被移除、隐藏，或属于一台已不再配对的设备。';

  @override
  String get markAsUnread => '标为未读';

  @override
  String get markAsRead => '标为已读';

  @override
  String get copyText => '复制文字';

  @override
  String get hideFromDevice => '在这台设备上隐藏';

  @override
  String get actionHide => '隐藏';

  @override
  String hideCount(int count) {
    return '隐藏 $count 条通知';
  }

  @override
  String get you => '你';

  @override
  String youSaid(String text) {
    return '你：$text';
  }

  @override
  String get sentFromPhone => '从你的手机发送';

  @override
  String get clearedOnPhone => '已在手机上清除';

  @override
  String get canReply => '可回复';

  @override
  String get canBeAnswered => '可被回复';

  @override
  String get noRepliesInApp => '此应用不支持回复';

  @override
  String get replySending => '正在发送';

  @override
  String get replyDelivered => '已送达';

  @override
  String get replySent => '已发送';

  @override
  String get replyExpired => '已在手机上失效';

  @override
  String get replyNotDelivered => '未送达';

  @override
  String get replySendingPrefixed => '回复正在发送';

  @override
  String get replyDeliveredPrefixed => '回复已送达';

  @override
  String get replySentPrefixed => '回复已发送';

  @override
  String get replyExpiredPrefixed => '回复已在手机上失效';

  @override
  String get replyNotDeliveredPrefixed => '回复未送达';

  @override
  String get yourReply => '你的回复';

  @override
  String yourReplyAsShown(String app) {
    return '你的回复，在 $app 中显示的样子';
  }

  @override
  String get allMarkedRead => '已全部标为已读';

  @override
  String sharedWith(String name) {
    return '已共享给 $name';
  }

  @override
  String sharedWithDevices(int count) {
    return '已共享给 $count 台设备';
  }

  @override
  String fromDevice(String name) {
    return '来自 $name';
  }

  @override
  String fromPhones(int count) {
    return '来自 $count 部手机';
  }

  @override
  String get markAllRead => '全部标为已读';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '筛选，已启用 $count 项', zero: '筛选');
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => '没有与此搜索或筛选条件匹配的内容。';

  @override
  String get actionClearSearchAndFilters => '清除搜索和筛选';

  @override
  String get allCaughtUp => '全部看完了';

  @override
  String get inboxEmptySender => '这部手机共享的通知会显示在这里，以及从你的设备发出的回复。';

  @override
  String get inboxEmptyReceiver => '来自手机的通知一到就会显示在这里。';

  @override
  String get inboxAllHidden => '所有通知都已隐藏。可在“设置”中恢复。';

  @override
  String get notificationsLoadFailed => '无法加载通知';

  @override
  String get removeFilter => '移除筛选条件';

  @override
  String get filterUnread => '未读';

  @override
  String get device => '设备';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared => '这些通知已在你的手机上清除，无法再从这里回复。';

  @override
  String footnoteNoReplies(String app) {
    return '$app 不接受此对话的回复。';
  }

  @override
  String get unknownSender => '未知发送者';

  @override
  String get dividerNew => '新消息';

  @override
  String notificationHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '已隐藏 $count 条通知', one: '已隐藏通知');
    return '$_temp0';
  }

  @override
  String get copied => '已复制';

  @override
  String get dismissedOnPhone => '已在手机上清除';

  @override
  String get moreActions => '更多操作';

  @override
  String get hideConversations => '收起对话';

  @override
  String get showConversations => '展开对话';

  @override
  String unmuteApp(String app) {
    return '取消静音 $app 的提醒';
  }

  @override
  String muteApp(String app) {
    return '静音 $app 的提醒';
  }

  @override
  String get threadChat => '聊天';

  @override
  String get threadGroup => '群组';

  @override
  String get threadNotification => '通知';

  @override
  String get replyHint => '回复';

  @override
  String replyToHint(String name) {
    return '回复 $name';
  }

  @override
  String get sendWithEnter => '发送（Enter）';

  @override
  String get actionSend => '发送';

  @override
  String get filterTitle => '筛选';

  @override
  String get actionClearAll => '全部清除';

  @override
  String get filterShow => '显示';

  @override
  String get filterAll => '全部';

  @override
  String get filterUnreadOnly => '仅未读';

  @override
  String get filterWhen => '时间';

  @override
  String get filterSharedWith => '共享对象';

  @override
  String get filterPhone => '手机';

  @override
  String get filterApp => '应用';

  @override
  String get filterAllApps => '所有应用';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '显示 $count 条通知');
    return '$_temp0';
  }

  @override
  String get actionShowMore => '显示更多';

  @override
  String get browseSharedWithIt => '浏览你共享给它的内容';

  @override
  String get browseItsHistory => '浏览它的通知历史';

  @override
  String get swipeUnread => '未读';

  @override
  String get swipeRead => '已读';

  @override
  String get diagnosticsIntro => '这里不包含任何通知内容或加密密钥。';

  @override
  String get reportCopied => '已复制报告';

  @override
  String get actionCopyReport => '复制报告';

  @override
  String get checkingAgain => '正在重新检查…';

  @override
  String get actionCheckAgain => '重新检查';

  @override
  String get diagnosticsReportNote => '报告本身保持英文，方便帮助你的人阅读。';

  @override
  String get welcomeEncryption => '端到端加密，密钥只有你的设备持有。服务器只转发它无法读取的密文。';

  @override
  String get theOtherDevice => '另一台设备';

  @override
  String get appsShareIntro => '选择哪些内容可以送达你的设备。即使 AirReply 已关闭也会生效。';

  @override
  String get appsOnlySelected => '仅已选';

  @override
  String get searchApps => '搜索应用';

  @override
  String get appsNothingSelected => '未选择任何应用：不会共享任何通知';

  @override
  String appsSelected(int count) {
    return '已选 $count 个';
  }

  @override
  String get appsOnlySelectedHint => '选择“仅已选”来挑选哪些应用的通知可以送达你的设备。';

  @override
  String get appsChoiceLoadFailed => '无法加载你的选择';

  @override
  String get appsMutedIntro => '已静音的应用仍会出现在“通知”中，但不会在这台设备上提醒你。';

  @override
  String get appsNoneYet => '还没有应用';

  @override
  String get appsNoneYetHint => '手机发送过某个应用的通知后，该应用就会出现在这里。';

  @override
  String get appMuted => '已静音';

  @override
  String get appAlertsOn => '提醒已开启';

  @override
  String get appsNoMatch => '没有匹配的应用';

  @override
  String get appsListFailed => '无法列出应用';

  @override
  String get appsReading => '正在读取已安装的应用…';

  @override
  String get alertChannelName => '镜像通知';

  @override
  String get alertChannelDescription => '从已配对手机镜像过来的通知';

  @override
  String get alertReply => '回复';

  @override
  String get alertReplyHint => '回复…';

  @override
  String get alertOpenApp => '打开 AirReply';

  @override
  String get alertNewNotification => '新通知';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随此设备';

  @override
  String languageSystemCurrent(String language) {
    return '跟随此设备（$language）';
  }

  @override
  String get previousDevicesTitle => '以前的设备';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 台已移除的设备，历史记录已保留',
      zero: '已移除设备的历史记录会保留在这里',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro => '移除设备后，它的历史记录仍保留在这台设备上。重新配对同一台设备即可从上次的地方继续，也可以在这里删除历史记录。';

  @override
  String get previousDevicesNone => '没有以前的设备';

  @override
  String get previousDevicesNoneHint => '你移除的设备的历史记录会显示在这里。';

  @override
  String previousDeviceSummary(String date, String count) {
    return '移除于 $date · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return '移除于 $date';
  }

  @override
  String previousDeviceContinue(String name) {
    return '重新配对 $name，即可在收件箱中继续这段历史记录。';
  }

  @override
  String get actionDeleteHistory => '删除历史记录';

  @override
  String deleteHistoryTitle(String name) {
    return '删除 $name 的历史记录？';
  }

  @override
  String get deleteHistoryMessage => '它的通知和回复会从这台设备上删除。此操作无法撤销。';

  @override
  String historyDeleted(String name) {
    return '已删除 $name 的历史记录';
  }

  @override
  String get actionDeleteAll => '全部删除';

  @override
  String get deleteAllHistoryTitle => '删除所有以前的历史记录？';

  @override
  String get deleteAllHistoryMessage => '所有已移除设备的历史记录都会从这台设备上删除。此操作无法撤销。';

  @override
  String get allHistoryDeleted => '已删除以前的历史记录';

  @override
  String get feedbackReportTitle => '报告问题';

  @override
  String get feedbackReportSubtitle => '有地方不正常？告诉我们发生了什么';

  @override
  String get feedbackIdeaTitle => '建议新功能';

  @override
  String get feedbackIdeaSubtitle => '让 AirReply 变得更好的想法';

  @override
  String get feedbackKindLabel => '类型';

  @override
  String get feedbackKindProblem => '问题';

  @override
  String get feedbackKindIdea => '功能建议';

  @override
  String get feedbackAreaLabel => '关于哪方面？';

  @override
  String get feedbackAreaNotifications => '通知';

  @override
  String get feedbackAreaReplies => '回复';

  @override
  String get feedbackAreaPairing => '配对';

  @override
  String get feedbackAreaAlerts => '提醒';

  @override
  String get feedbackAreaSync => '同步';

  @override
  String get feedbackAreaDesign => '外观与体验';

  @override
  String get feedbackAreaOther => '其他';

  @override
  String get feedbackMessageLabel => '你的留言';

  @override
  String get feedbackProblemHint => '发生了什么？你原本期望怎样？如果能写出重现步骤会很有帮助。';

  @override
  String get feedbackIdeaHint => '你希望 AirReply 做什么？这对你有什么帮助？';

  @override
  String get feedbackTooShort => '请再多写一点（至少 10 个字符）。';

  @override
  String get feedbackIncludeDetails => '附上设备信息';

  @override
  String get feedbackDetailsSubtitle => '系统、设备型号、应用语言和角色。绝不包含你的通知或密钥。';

  @override
  String get feedbackSent => '谢谢！你的邮件应用已准备好：在那里点按发送即可完成。';

  @override
  String get feedbackNoEmailApp => '这台设备上没有设置邮件应用。';
}
