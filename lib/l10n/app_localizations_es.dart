// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AirReply';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabNotifications => 'Notificaciones';

  @override
  String tabNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones, $count sin leer',
      one: 'Notificaciones, 1 sin leer',
      zero: 'Notificaciones',
    );
    return '$_temp0';
  }

  @override
  String get tabDevices => 'Dispositivos';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String inboxUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sin leer', zero: 'Todo leído');
    return '$_temp0';
  }

  @override
  String get welcomeHeadlineFirst => 'Tu teléfono,';

  @override
  String get welcomeHeadlineSecond => 'en todas partes.';

  @override
  String get welcomeIntro =>
      'Lee las notificaciones de tu teléfono en tu iPhone, iPad, Mac, PC o navegador, y responde a los mensajes desde allí.';

  @override
  String get welcomeEyebrow => 'Empezar';

  @override
  String get welcomeQuestion => '¿Cómo vas a usar este dispositivo?';

  @override
  String get roleShareTitle => 'Compartir mis notificaciones';

  @override
  String get roleShareDescription =>
      'Este teléfono envía sus notificaciones a tus otros dispositivos y envía las respuestas que escribas allí.';

  @override
  String get roleShareUnavailable =>
      'Solo Android permite que las apps lean notificaciones. Usa un teléfono Android para compartir.';

  @override
  String get roleReceiveTitle => 'Ver y responder aquí';

  @override
  String get roleReceiveDescription =>
      'Mira las notificaciones de tu teléfono en este dispositivo y responde a los mensajes sin cogerlo.';

  @override
  String get errorOffline => 'Parece que no tienes conexión. Comprueba la conexión y vuelve a intentarlo.';

  @override
  String get errorServerUnreachable => 'No se pudo contactar con los servidores de AirReply. Comprueba la conexión.';

  @override
  String get errorSignInRefused =>
      'Se rechazó el inicio de sesión. ¿Está activado el inicio de sesión anónimo en el proyecto de Firebase?';

  @override
  String get errorSignInFailed => 'No se pudo iniciar sesión.';

  @override
  String get errorSyncFailed => 'Falló la sincronización con tu dispositivo vinculado.';

  @override
  String get errorPairingCodeNotCreated => 'No se pudo crear un código de vinculación. Inténtalo de nuevo.';

  @override
  String get errorSessionNotConfirmable => 'Esta sesión no se puede confirmar.';

  @override
  String get errorCodeUnavailable => 'Este código ya no está disponible. Crea uno nuevo en el otro teléfono.';

  @override
  String get errorCannotPairWithItself => 'Un dispositivo no puede vincularse consigo mismo.';

  @override
  String get errorCodeAlreadyUsed => 'Este código ya se ha usado.';

  @override
  String get errorNoDeviceJoined => 'Todavía no se ha unido ningún dispositivo.';

  @override
  String get errorCodeFormat => 'Introduce el código de 6 dígitos que aparece en el teléfono.';

  @override
  String get errorNotAPairingCode => 'Ese no es un código de vinculación de AirReply.';

  @override
  String get errorCodeNotFound => 'No existe ese código. Revisa el código en el otro teléfono.';

  @override
  String get errorCodeExpired => 'Este código ha caducado. Crea uno nuevo.';

  @override
  String get errorQrMismatch =>
      'El código QR no coincide con esta sesión. Se ha detenido la vinculación por tu seguridad.';

  @override
  String get errorNotConfirmedYet => 'El otro teléfono aún no ha confirmado.';

  @override
  String get errorPairingCancelledOnPhone => 'Se canceló la vinculación en el otro teléfono.';

  @override
  String get errorPairingCancelled => 'Se canceló la vinculación. Crea un código nuevo para volver a intentarlo.';

  @override
  String get errorPairingNotAvailable => 'Esta sesión de vinculación no está disponible para este dispositivo.';

  @override
  String get errorPairingServerFailed => 'El servidor no pudo completar la vinculación.';

  @override
  String get errorPairingOffInDemo => 'La vinculación está desactivada en el modo de demostración.';

  @override
  String get errorNotPaired => 'Este dispositivo aún no está vinculado.';

  @override
  String get errorInvalidPeerKey => 'El otro dispositivo envió una clave no válida.';

  @override
  String get errorUnsafePeerKey => 'El otro dispositivo envió una clave insegura.';

  @override
  String get errorEncryptFailed => 'No se pudo cifrar la notificación.';

  @override
  String get errorDecryptFailed => 'No se pudo descifrar la notificación.';

  @override
  String get errorPayloadUnknown => 'Esta notificación tiene un formato desconocido.';

  @override
  String get errorPayloadForeign => 'Esta notificación no se creó con la clave de este par, o se ha modificado.';

  @override
  String get errorNativeServiceFailed => 'Falló el servicio de notificaciones de Android.';

  @override
  String get errorNativeServiceUnavailable => 'El servicio de notificaciones de Android no está disponible.';

  @override
  String get errorReplyEmpty => 'Escribe una respuesta primero.';

  @override
  String get errorReplyTooLong => 'La respuesta es demasiado larga.';

  @override
  String get errorReplyNotPossible => 'No se puede responder a esta notificación.';

  @override
  String get errorReplyDismissed => 'Esta notificación se descartó en tu teléfono, así que ya no se puede responder.';

  @override
  String errorDevicesUnreachable(int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No se pudo contactar con $count de $total dispositivos vinculados.',
      one: 'No se pudo contactar con 1 de $total dispositivos vinculados.',
    );
    return '$_temp0';
  }

  @override
  String errorWithDetail(String message, String detail) {
    return '$message ($detail)';
  }

  @override
  String get errorUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorSharingAndroidOnly => 'Compartir notificaciones solo está disponible en Android.';

  @override
  String get timeNow => 'ahora';

  @override
  String timeMinutesShort(int n) {
    return '$n min';
  }

  @override
  String timeHoursShort(int n) {
    return '$n h';
  }

  @override
  String get timeToday => 'Hoy';

  @override
  String get timeYesterday => 'Ayer';

  @override
  String timeAt(String day, String time) {
    return '$day a las $time';
  }

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'hace $n min', one: 'hace 1 min');
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'hace $n h', one: 'hace 1 h');
    return '$_temp0';
  }

  @override
  String get actionUndo => 'Deshacer';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get searchHint => 'Buscar';

  @override
  String get searchClear => 'Borrar búsqueda';

  @override
  String get splashFailed => 'AirReply no pudo iniciarse';

  @override
  String get actionTryAgain => 'Reintentar';

  @override
  String get splashStarting => 'AirReply se está iniciando';

  @override
  String get firebaseSetupEyebrow => 'Configuración necesaria';

  @override
  String get firebaseSetupTitle => 'Conectar Firebase';

  @override
  String get firebaseSetupBody =>
      'AirReply sincroniza tus dispositivos a través de tu propio proyecto de Firebase. Ejecuta esto en la carpeta del proyecto y vuelve a compilar la app.';

  @override
  String get actionCopyCommand => 'Copiar comando';

  @override
  String get firebaseSetupDetails => 'Detalles';

  @override
  String get deviceConnected => 'Conectado';

  @override
  String get deviceOffline => 'Sin conexión';

  @override
  String get deviceConnecting => 'Conectando';

  @override
  String get deviceNeedsAccess => 'Necesita acceso';

  @override
  String get devicePaused => 'En pausa';

  @override
  String get deviceNotReceiving => 'Sin recibir';

  @override
  String get deviceReceivingDetail => 'Las notificaciones nuevas llegan al momento.';

  @override
  String get deviceSharingDetail => 'Las notificaciones nuevas se comparten en cuanto llegan.';

  @override
  String get deviceOfflineDetail =>
      'Se muestran las notificaciones guardadas hasta que este dispositivo vuelva a conectarse.';

  @override
  String get deviceConnectingDetail => 'Conectando con el servidor…';

  @override
  String get deviceNeedsAccessDetail =>
      'El acceso a notificaciones está desactivado, así que no se puede compartir nada.';

  @override
  String get devicePausedDetail => 'Compartir está desactivado. Actívalo para enviar notificaciones.';

  @override
  String get deviceNotReceivingDetail => 'Android detuvo el servicio de escucha de notificaciones de AirReply.';

  @override
  String get settingsAccessEyebrow => 'Acceso';

  @override
  String get settingsPermissionsTitle => 'Permisos';

  @override
  String get settingsPrivacyEyebrow => 'Privacidad';

  @override
  String get settingsConnectionEyebrow => 'Conexión';

  @override
  String get settingsSyncTitle => 'Sincronización';

  @override
  String get settingsAppearanceEyebrow => 'Apariencia';

  @override
  String get settingsAppearanceTitle => 'Apariencia y accesibilidad';

  @override
  String get settingsDataTitle => 'Privacidad y datos';

  @override
  String get settingsHelpEyebrow => 'Ayuda';

  @override
  String get settingsHelpTitle => 'Ayuda e información';

  @override
  String get permissionOn => 'Activado';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionAllow => 'Permitir';

  @override
  String get permissionAccessTitle => 'Acceso a notificaciones';

  @override
  String get permissionAccessSubtitle => 'Necesario para leer y compartir notificaciones';

  @override
  String get permissionStatusTitle => 'Notificación de estado';

  @override
  String get permissionStatusSubtitle => 'Muestra «Sincronización de notificaciones activa» con un botón Pausar';

  @override
  String get permissionBatteryTitle => 'Optimización de batería';

  @override
  String get permissionBatteryOk => 'Sin restricciones: Android no pausará el uso compartido';

  @override
  String get permissionBatteryFix => 'Elige «Sin restricciones» para que Android nunca pause el uso compartido';

  @override
  String get permissionAlertsTitle => 'Avisos';

  @override
  String get permissionAlertsBrowser => 'Permite que este navegador muestre las notificaciones nuevas';

  @override
  String get loading => 'Cargando…';

  @override
  String get appsAllShared => 'Se comparten todas las apps';

  @override
  String get appsNoneShared => 'No hay apps seleccionadas: no se comparte nada';

  @override
  String get appsToShareTitle => 'Apps que compartir';

  @override
  String get appsMutedTitle => 'Apps silenciadas';

  @override
  String get encryptionTitle => 'Cifrado de extremo a extremo';

  @override
  String get encryptionDetail =>
      'Cada par tiene su propia clave, acordada entre los dos dispositivos (X25519). Las notificaciones y respuestas se sellan con AES-256-GCM. El historial se queda en tus dispositivos: el servidor solo retransmite texto cifrado y borra cada mensaje en cuanto se entrega.';

  @override
  String get shareNotificationsTitle => 'Compartir notificaciones';

  @override
  String get shareNeedsAccess => 'Activa primero el acceso a notificaciones';

  @override
  String get alertTextTitle => 'Mostrar el texto de los mensajes en los avisos';

  @override
  String get alertTextSubtitle =>
      'Desactivado: los avisos solo nombran la app, para pantallas de bloqueo y pantallas compartidas';

  @override
  String get alertsBrowserTitle => 'Avisos en este navegador';

  @override
  String get alertsComputerTitle => 'Avisos en este ordenador';

  @override
  String get alertsWhileOpen =>
      'Las notificaciones nuevas te avisan mientras AirReply está en marcha. Mantenlo abierto (en Mac sigue funcionando al cerrar la ventana).';

  @override
  String get syncNoDevices => 'No hay dispositivos vinculados';

  @override
  String get syncStatusTitle => 'Estado de sincronización';

  @override
  String get syncChecking => 'Comprobando la conexión…';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String get listenerTitle => 'Servicio de escucha de notificaciones';

  @override
  String get listenerSubtitle =>
      'Pide a Android que vuelva a conectar el servicio de AirReply si los dispositivos dejan de recibir';

  @override
  String get actionReconnect => 'Reconectar';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeSubtitle => 'Sistema sigue a este dispositivo';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get hapticsTitle => 'Respuesta háptica';

  @override
  String get hapticsSubtitle => 'Una vibración suave al enviar, cambiar o confirmar';

  @override
  String get textSizeTitle => 'Tamaño del texto';

  @override
  String get textSizeSubtitle => 'AirReply sigue el tamaño de texto y la negrita configurados en este dispositivo';

  @override
  String get removeAllConfirmTitle => '¿Quitar todos los dispositivos?';

  @override
  String get actionRemoveAll => 'Quitar todos';

  @override
  String get markAllReadTitle => 'Marcar todo como leído';

  @override
  String get markedAllRead => 'Todo marcado como leído';

  @override
  String get removeAllTitle => 'Quitar todos los dispositivos';

  @override
  String get removeAllSubtitle => 'Termina todos los pares; su historial se queda en Dispositivos anteriores';

  @override
  String get troubleshootingTitle => 'Solución de problemas';

  @override
  String get troubleshootingSubtitle => 'Qué revisar cuando no llegan notificaciones o respuestas';

  @override
  String get diagnosticsTitle => 'Diagnóstico';

  @override
  String get diagnosticsSubtitle => 'Detalles de conexión, permisos y sincronización para revisar o compartir';

  @override
  String get licencesTitle => 'Licencias de código abierto';

  @override
  String get appTagline => 'Las notificaciones de tu teléfono, en todas tus pantallas.';

  @override
  String get syncSharing => 'Compartiendo';

  @override
  String get syncStarting => 'Iniciando';

  @override
  String get permissionAutostartTitle => 'Inicio automático';

  @override
  String permissionAutostartSubtitle(String vendor) {
    return 'Necesario en teléfonos $vendor. Android no puede indicarlo, así que compruébalo allí.';
  }

  @override
  String appsSomeShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solo $count apps seleccionadas',
      one: 'Solo 1 app seleccionada',
    );
    return '$_temp0';
  }

  @override
  String appsMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count silenciadas: llegan sin sonido',
      zero: 'Todas las apps pueden avisarte',
    );
    return '$_temp0';
  }

  @override
  String syncLive(String state) {
    return '$state. En directo.';
  }

  @override
  String syncLastSynced(String state, String ago) {
    return '$state. Última sincronización: $ago.';
  }

  @override
  String syncStateDetail(String state, String detail) {
    return '$state. $detail';
  }

  @override
  String removeAllConfirmOne(String name) {
    return 'Se detiene la sincronización con $name. Su historial se queda en este dispositivo en Dispositivos anteriores y vuelve si lo vinculas de nuevo.';
  }

  @override
  String removeAllConfirmMany(int count) {
    return 'Se detiene la sincronización con los $count dispositivos. Su historial se queda en este dispositivo en Dispositivos anteriores y vuelve si los vinculas de nuevo.';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sin leer', zero: 'Nada sin leer');
    return '$_temp0';
  }

  @override
  String get noticeAccessOffTitle => 'El acceso a notificaciones está desactivado';

  @override
  String get noticeAccessOffMessage =>
      'AirReply no puede ver las notificaciones nuevas hasta que lo vuelvas a activar.';

  @override
  String get actionOpenSettings => 'Abrir ajustes';

  @override
  String get noticePausedTitle => 'El uso compartido está en pausa';

  @override
  String get noticePausedMessage => 'Las notificaciones de este teléfono no se están enviando a tus dispositivos.';

  @override
  String get actionResumeSharing => 'Reanudar';

  @override
  String get noticeNotReceivingTitle => 'No se reciben notificaciones';

  @override
  String noticeNotReceivingAutostart(String vendor) {
    return 'Android detuvo el servicio de escucha de AirReply. Reconéctalo y activa el inicio automático de AirReply en los teléfonos $vendor para que no vuelva a pasar.';
  }

  @override
  String get noticeNotReceivingMessage =>
      'Android detuvo el servicio de escucha de notificaciones de AirReply. Reconéctalo para empezar de nuevo.';

  @override
  String get noticeBatteryTitle => 'La optimización de batería está activada';

  @override
  String get noticeBatteryMessage =>
      'Android puede pausar el uso compartido para ahorrar batería. Configura AirReply como «Sin restricciones».';

  @override
  String get actionBatterySettings => 'Ajustes de batería';

  @override
  String get noticeAlertsOffTitle => 'Los avisos están desactivados en este dispositivo';

  @override
  String get noticeAlertsOffMessage =>
      'Las notificaciones nuevas seguirán apareciendo aquí, pero este dispositivo no te avisará.';

  @override
  String get actionAllowAlerts => 'Permitir avisos';

  @override
  String noticeOneOffline(String name) {
    return '$name no tiene conexión';
  }

  @override
  String noticeManyOffline(int count) {
    return '$count dispositivos sin conexión';
  }

  @override
  String get noticeOfflineMessage =>
      'Se muestran las notificaciones guardadas. Las nuevas llegarán cuando este dispositivo vuelva a conectarse.';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get setupTitle => 'Configurar';

  @override
  String get disclosureEyebrow => 'Antes de empezar';

  @override
  String get disclosureTitle => 'AirReply necesita acceder a tus notificaciones';

  @override
  String get disclosureIntro =>
      'Para compartir las notificaciones de este teléfono con tus dispositivos vinculados, AirReply usa el permiso de acceso a notificaciones de Android.';

  @override
  String get disclosureWhatTitle => 'A qué se accede';

  @override
  String get disclosureWhatBody =>
      'Las notificaciones que aparecen en este teléfono: nombre de la app, título, texto, hora y la acción de respuesta de las apps de mensajería. Funciona en segundo plano, incluso con AirReply cerrado.';

  @override
  String get disclosureWhyTitle => 'Para qué';

  @override
  String get disclosureWhyBody =>
      'Solo para mostrar esas notificaciones en los dispositivos que vincules y para enviar las respuestas que escribas allí mediante la app original de este teléfono.';

  @override
  String get disclosureHowTitle => 'Cómo se protege';

  @override
  String get disclosureHowBody =>
      'Cada notificación se cifra en este teléfono con AES-256-GCM, con una clave que solo tienen este teléfono y el dispositivo vinculado. Nuestros servidores retransmiten texto cifrado que no pueden leer y lo borran al entregarlo: el historial solo se guarda en tus dispositivos.';

  @override
  String get disclosureControlTitle => 'Tú tienes el control';

  @override
  String get disclosureControlBody =>
      'Elige qué apps se comparten, pausa en cualquier momento desde la notificación de estado o quita un dispositivo para dejar de compartir; borra su historial cuando quieras. El contenido de las notificaciones nunca se vende, se comparte con terceros ni se usa para publicidad o analíticas.';

  @override
  String get actionAgreeAndContinue => 'Aceptar y continuar';

  @override
  String get actionNoThanks => 'No, gracias';

  @override
  String setupProgress(int done, int total) {
    return '$done de $total pasos obligatorios completados';
  }

  @override
  String get setupPhoneTitle => 'Configura este teléfono';

  @override
  String get setupPhoneSubtitle =>
      'Dos permisos permiten que AirReply comparta notificaciones y siga funcionando en segundo plano.';

  @override
  String get setupAccessSubtitle => 'Obligatorio. Busca AirReply en la lista y actívalo.';

  @override
  String get setupStatusSubtitle =>
      'Muestra «Sincronización de notificaciones activa» con un botón Pausar mientras se comparte.';

  @override
  String setupAutostartSubtitle(String vendor) {
    return 'Obligatorio en $vendor. Sin él, el teléfono impide que AirReply escuche cuando se cierra la app. Busca AirReply y activa el inicio automático.';
  }

  @override
  String get setupBatterySubtitle =>
      'Recomendado. Configura AirReply como «Sin restricciones» para que Android nunca pause el uso compartido.';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get setupNeedsAccess => 'Activa el acceso a notificaciones para continuar';

  @override
  String get stepDone => 'Hecho';

  @override
  String get pairADevice => 'Vincular un dispositivo';

  @override
  String get pairTitle => 'Vincular';

  @override
  String get pairAddADevice => 'Añadir un dispositivo';

  @override
  String pairPairedWith(String name) {
    return 'Vinculado con $name';
  }

  @override
  String pairStep(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get pairStopped => 'Vinculación detenida';

  @override
  String get actionMakeNewCode => 'Crear un código nuevo';

  @override
  String get pairShowCodeIntro =>
      'En tu iPhone, iPad, Mac, PC, navegador u otro Android, abre AirReply, elige «Ver y responder aquí» y escanea este código o escribe los dígitos.';

  @override
  String get pairQrLabel => 'Código QR de vinculación';

  @override
  String get pairOrTypeCode => 'O ESCRIBE ESTE CÓDIGO';

  @override
  String pairCodeCopied(String code) {
    return 'Código $code copiado';
  }

  @override
  String get actionCopyCode => 'Copiar código';

  @override
  String get actionNewCode => 'Código nuevo';

  @override
  String get pairCodesMatchQuestion => '¿Coinciden los códigos?';

  @override
  String pairVerifyWarning(String name) {
    return '$name quiere vincularse. Debe mostrar exactamente este código. Si no es así, puede que otra persona esté intentando conectarse.';
  }

  @override
  String get actionCodesMatch => 'Coinciden, vincular';

  @override
  String get actionCodesDoNotMatch => 'No coinciden';

  @override
  String get pairAddAnotherPhone => 'Añadir otro teléfono';

  @override
  String get pairWithYourPhone => 'Vincular con tu teléfono';

  @override
  String get pairEnterCodeIntro =>
      'En el teléfono Android que quieres ver aquí, abre AirReply y elige «Compartir mis notificaciones» (o «Añadir un dispositivo» si ya comparte). Mostrará un código QR y seis dígitos.';

  @override
  String get pairMethodScan => 'Escanear';

  @override
  String get pairMethodType => 'Escribir código';

  @override
  String get pairCodeLabel => 'CÓDIGO DE VINCULACIÓN';

  @override
  String get pairStartsOnLastDigit => 'La vinculación empieza en cuanto escribes el último dígito.';

  @override
  String get pairConnecting => 'Conectando…';

  @override
  String get pairPointCamera => 'Apunta la cámara al código QR de tu teléfono.';

  @override
  String get cameraDenied =>
      'AirReply necesita la cámara para escanear. Permítela en los ajustes del teléfono o escribe el código.';

  @override
  String get cameraNotStarted => 'La cámara no se inició.';

  @override
  String pairConfirmOn(String name) {
    return 'Confirma en $name';
  }

  @override
  String get pairConfirmHint => 'Comprueba que tu teléfono muestra el mismo código y toca «Coinciden» allí.';

  @override
  String get pairWaitingForPhone => 'Esperando a tu teléfono…';

  @override
  String get pairCodeExpired => 'Código caducado, creando uno nuevo';

  @override
  String pairExpiresIn(int minutes, String seconds) {
    return 'Caduca en $minutes:$seconds';
  }

  @override
  String pairStepNamed(int current, int total, String name) {
    return 'Paso $current de $total: $name';
  }

  @override
  String get pairCouldNotPair => 'No se pudo vincular';

  @override
  String get stepShowCode => 'Mostrar código';

  @override
  String get stepVerify => 'Verificar';

  @override
  String get stepEnterCode => 'Introducir código';

  @override
  String get notYet => 'Aún no';

  @override
  String get factStatus => 'Estado';

  @override
  String get factLive => 'En directo';

  @override
  String get factLastSynced => 'Última sincronización';

  @override
  String get factNow => 'Ahora';

  @override
  String get lastShared => 'Último compartido';

  @override
  String get lastNotification => 'Última notificación';

  @override
  String get factPaired => 'Vinculado';

  @override
  String get factEncryption => 'Cifrado';

  @override
  String get factEncryptionValue => 'De extremo a extremo, AES-256-GCM';

  @override
  String removeDeviceTitle(String name) {
    return '¿Quitar $name?';
  }

  @override
  String removeDeviceMessage(String name) {
    return 'La sincronización con $name se detiene en ambos dispositivos. Su historial se queda en este dispositivo en Dispositivos → Dispositivos anteriores hasta que lo borres. Los demás dispositivos no se ven afectados.';
  }

  @override
  String get actionRemove => 'Quitar';

  @override
  String deviceRemoved(String name) {
    return '$name quitado';
  }

  @override
  String get actionTurnOnAccess => 'Activar el acceso a notificaciones';

  @override
  String get browseShared => 'Ver lo que has compartido';

  @override
  String get browseHistory => 'Ver el historial de notificaciones';

  @override
  String get actionRemoveDevice => 'Quitar dispositivo';

  @override
  String get addAPhone => 'Añadir un teléfono';

  @override
  String factWithTime(String label, String time) {
    return '$label: $time';
  }

  @override
  String pairedAgo(String time) {
    return 'Vinculado: $time';
  }

  @override
  String devicesPaired(int count) {
    return '$count vinculados';
  }

  @override
  String get devicesIntroSender => 'Este teléfono comparte sus notificaciones con estos dispositivos.';

  @override
  String get devicesIntroReceiver => 'Este dispositivo muestra las notificaciones de estos teléfonos.';

  @override
  String get devicesNone => 'No hay dispositivos';

  @override
  String get devicesNoneHint => 'Vincula un dispositivo para empezar.';

  @override
  String get helpNotArrivingQ => 'No llegan las notificaciones';

  @override
  String get helpNotArrivingA =>
      'En el teléfono, abre AirReply y comprueba que «Compartir notificaciones» está activado y que la app puede funcionar en segundo plano. Ambos dispositivos necesitan conexión a internet. Luego vuelve a intentarlo aquí.';

  @override
  String get actionRetrySync => 'Volver a sincronizar';

  @override
  String get helpNoAlertsQ => 'No hay avisos en este dispositivo';

  @override
  String get helpNoAlertsA =>
      'Las notificaciones nuevas siempre llegan a la pestaña Notificaciones. Para recibir también avisos, permite las notificaciones de AirReply y comprueba que la app no está silenciada en Ajustes → Apps silenciadas.';

  @override
  String get helpExpiredQ => 'Una respuesta dice «Caducada en el teléfono»';

  @override
  String get helpExpiredA =>
      'Las respuestas se envían a través de la notificación del teléfono. Si se ha borrado allí o la app la ha sustituido, ya no se puede responder. Responde a una notificación más reciente o desde el teléfono.';

  @override
  String get helpNotReceivingQ => 'Los dispositivos no reciben notificaciones';

  @override
  String get helpNotReceivingA =>
      'Comprueba que el acceso a notificaciones está activado y que el uso compartido no está en pausa. Si Android detuvo el servicio de escucha de AirReply, reconéctalo.';

  @override
  String get actionReconnectListener => 'Reconectar servicio';

  @override
  String get helpStopsQ => 'Se deja de compartir al cabo de un rato';

  @override
  String helpStopsAutostartA(String vendor) {
    return 'En los teléfonos $vendor, activa el inicio automático de AirReply y configura su uso de batería como «Sin restricciones»; si no, el teléfono lo detiene en segundo plano.';
  }

  @override
  String get helpStopsA =>
      'Configura el uso de batería de AirReply como «Sin restricciones» para que Android no lo pause en segundo plano.';

  @override
  String get helpRepliesQ => 'Las respuestas no se entregan';

  @override
  String get helpRepliesA =>
      'Una respuesta se envía a través de la notificación a la que responde, así que esa notificación tiene que seguir en la barra de estado de este teléfono. Las apps de mensajería que ofrecen «Responder» en sus notificaciones son las que mejor funcionan.';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historySharedWithIt => 'Compartido con él';

  @override
  String get emptyNothingYet => 'Aún no hay nada';

  @override
  String historyEmptySender(String name) {
    return 'Aquí aparecen las notificaciones que este teléfono comparte con $name.';
  }

  @override
  String historyEmptyReceiver(String name) {
    return 'Aquí aparecen las notificaciones de $name.';
  }

  @override
  String get thisPhone => 'este teléfono';

  @override
  String get itDevice => 'este dispositivo';

  @override
  String get homeHeadlineSender => 'compartido.';

  @override
  String get homeIntroSender =>
      'Las notificaciones de este teléfono llegan a tus otros dispositivos y sus respuestas vuelven.';

  @override
  String get homeIntroReceiver => 'Las notificaciones de tu teléfono llegan aquí. Léelas y responde sin cogerlo.';

  @override
  String get searchNotificationsHint => 'Buscar notificaciones';

  @override
  String get homeTodayEyebrow => 'Hoy';

  @override
  String get homeGlanceTitle => 'De un vistazo';

  @override
  String get homeRecentEyebrow => 'Actividad reciente';

  @override
  String get homeLatestTitle => 'Últimas notificaciones';

  @override
  String get actionSeeAll => 'Ver todo';

  @override
  String get homeRecentEmptySender =>
      'Aún no se ha compartido nada. Las notificaciones nuevas de este teléfono aparecerán aquí.';

  @override
  String get homeRecentEmptyReceiver => 'Aún no hay nada. Las notificaciones nuevas de tu teléfono aparecerán aquí.';

  @override
  String get homeRecentFailed => 'No se pudieron cargar las notificaciones recientes.';

  @override
  String get homeSharingEyebrow => 'Compartir';

  @override
  String get homeThisPhoneTitle => 'Este teléfono';

  @override
  String get howItWorksEyebrow => 'Cómo funciona';

  @override
  String get howItWorksSenderTitle => 'Comparte una vez. Responde desde cualquier sitio.';

  @override
  String get howItWorksReceiverTitle => 'Tres pasos. Todas las pantallas.';

  @override
  String bellUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notificaciones, $count sin leer',
      zero: 'Notificaciones',
    );
    return '$_temp0';
  }

  @override
  String get statToday => 'Hoy';

  @override
  String get statUnread => 'Sin leer';

  @override
  String statDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Dispositivos', one: 'Dispositivo');
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Sin resultados';

  @override
  String searchNoMatchesDetail(String query) {
    return 'Ninguna notificación ni dispositivo menciona «$query».';
  }

  @override
  String get searchEyebrow => 'Búsqueda';

  @override
  String get stepShareTitle => 'Comparte desde tu teléfono';

  @override
  String get stepShareText =>
      'En tu teléfono Android, AirReply envía aquí cada notificación, cifrada de extremo a extremo.';

  @override
  String get stepReadTitle => 'Léelas aquí';

  @override
  String get stepReadText => 'Las notificaciones llegan en segundos, agrupadas por app y por persona.';

  @override
  String get stepReplyTitle => 'Responde desde cualquier sitio';

  @override
  String get stepReplyText => 'Escribe aquí la respuesta; tu teléfono la envía a través de la app de la que vino.';

  @override
  String get stepPickTitle => 'Elige qué compartir';

  @override
  String get stepPickText => 'Elige todas las apps o solo las que quieras en tus otros dispositivos.';

  @override
  String get stepPairTitle => 'Vincula tus dispositivos';

  @override
  String get stepPairText => 'Un Mac, PC, iPhone, iPad o navegador escanea un código una vez y quedan vinculados.';

  @override
  String get stepReplySenderText =>
      'Las respuestas escritas allí se envían desde este teléfono, a través de la app a la que pertenecen.';

  @override
  String appsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps seleccionadas',
      one: '1 app seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get actionChooseApps => 'Elegir apps →';

  @override
  String get pairDeviceKinds => 'iPhone, iPad, Mac, PC, navegador o Android';

  @override
  String get actionPairArrow => 'Vincular →';

  @override
  String phonesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count teléfonos', one: '1 teléfono');
    return '$_temp0';
  }

  @override
  String devicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos',
      one: '1 dispositivo',
    );
    return '$_temp0';
  }

  @override
  String statusReceivingFrom(String names) {
    return 'Recibiendo de $names.';
  }

  @override
  String statusConnectingTo(String names) {
    return 'Conectando con $names…';
  }

  @override
  String statusShowingSaved(String names) {
    return 'Mostrando las notificaciones guardadas de $names.';
  }

  @override
  String get statusLive => 'En directo. Las notificaciones nuevas aparecen en segundos.';

  @override
  String statusLastSynced(String ago) {
    return 'Última sincronización: $ago.';
  }

  @override
  String get statusNeedsAccess => 'Para compartir se necesita acceso a notificaciones.';

  @override
  String get statusPaused => 'El uso compartido está en pausa.';

  @override
  String statusSharingWith(String names) {
    return 'Compartiendo con $names.';
  }

  @override
  String get statusNotWorking => 'El uso compartido no funciona ahora mismo.';

  @override
  String get statusEncryptedDetail =>
      'Las notificaciones se cifran de extremo a extremo en este teléfono antes de salir de él.';

  @override
  String get statusOffDetail => 'Nada de este teléfono llega a tus dispositivos hasta que actives el uso compartido.';

  @override
  String get encrypted => 'Cifrado';

  @override
  String get periodAnyTime => 'Cualquier momento';

  @override
  String get periodToday => 'Hoy';

  @override
  String get periodWeek => 'Últimos 7 días';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones',
      one: '1 notificación',
    );
    return '$_temp0';
  }

  @override
  String conversationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conversaciones',
      one: '1 conversación',
    );
    return '$_temp0';
  }

  @override
  String messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count mensajes', one: '1 mensaje');
    return '$_temp0';
  }

  @override
  String newNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones nuevas',
      one: '1 notificación nueva',
    );
    return '$_temp0';
  }

  @override
  String withUnread(String label, int count) {
    return '$label, $count sin leer';
  }

  @override
  String get nothingHereNow => 'Ahora no hay nada aquí';

  @override
  String get goneDetail =>
      'Estas notificaciones se ocultaron, se eliminaron o venían de un dispositivo que ya no está vinculado.';

  @override
  String get actionBackToNotifications => 'Volver a notificaciones';

  @override
  String get searchConversationsHint => 'Buscar nombres, números y mensajes';

  @override
  String get conversationsEyebrow => 'Conversaciones';

  @override
  String conversationsEyebrowCount(int count) {
    return 'Conversaciones · $count';
  }

  @override
  String get peopleAndGroups => 'Personas y grupos';

  @override
  String otherNotificationsCount(int count) {
    return 'Otras notificaciones · $count';
  }

  @override
  String fromApp(String app) {
    return 'De $app';
  }

  @override
  String nothingMatchesQuery(String query) {
    return 'Nada coincide con «$query».';
  }

  @override
  String get notAvailable => 'No disponible';

  @override
  String get notificationGoneDetail =>
      'Esta notificación se eliminó, se ocultó o pertenece a un dispositivo que ya no está vinculado.';

  @override
  String get markAsUnread => 'Marcar como no leída';

  @override
  String get markAsRead => 'Marcar como leída';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get you => 'Tú';

  @override
  String youSaid(String text) {
    return 'Tú: $text';
  }

  @override
  String get sentFromPhone => 'Enviado desde tu teléfono';

  @override
  String get clearedOnPhone => 'Borrada en el teléfono';

  @override
  String get canReply => 'Se puede responder';

  @override
  String get canBeAnswered => 'Admite respuesta';

  @override
  String get noRepliesInApp => 'Esta app no admite respuestas';

  @override
  String get replySending => 'Enviando';

  @override
  String get replyDelivered => 'Entregada';

  @override
  String get replySent => 'Enviada';

  @override
  String get replyExpired => 'Caducada en el teléfono';

  @override
  String get replyNotDelivered => 'No entregada';

  @override
  String get replySendingPrefixed => 'Enviando respuesta';

  @override
  String get replyDeliveredPrefixed => 'Respuesta entregada';

  @override
  String get replySentPrefixed => 'Respuesta enviada';

  @override
  String get replyExpiredPrefixed => 'Respuesta caducada en el teléfono';

  @override
  String get replyNotDeliveredPrefixed => 'Respuesta no entregada';

  @override
  String get yourReply => 'Tu respuesta';

  @override
  String yourReplyAsShown(String app) {
    return 'Tu respuesta, tal como la muestra $app';
  }

  @override
  String get allMarkedRead => 'Todo marcado como leído';

  @override
  String sharedWith(String name) {
    return 'Compartido con $name';
  }

  @override
  String sharedWithDevices(int count) {
    return 'Compartido con $count dispositivos';
  }

  @override
  String fromDevice(String name) {
    return 'De $name';
  }

  @override
  String fromPhones(int count) {
    return 'De $count teléfonos';
  }

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String filtersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Filtros, $count activos', zero: 'Filtros');
    return '$_temp0';
  }

  @override
  String get nothingMatchesFilter => 'Nada coincide con esta búsqueda o filtro.';

  @override
  String get actionClearSearchAndFilters => 'Borrar búsqueda y filtros';

  @override
  String get allCaughtUp => 'Estás al día';

  @override
  String get inboxEmptySender =>
      'Aquí aparecen las notificaciones que comparte este teléfono, con las respuestas enviadas desde tus dispositivos.';

  @override
  String get inboxEmptyReceiver => 'Las notificaciones de tu teléfono aparecen aquí en cuanto llegan.';

  @override
  String get notificationsLoadFailed => 'No se pudieron cargar las notificaciones';

  @override
  String get removeFilter => 'Quitar filtro';

  @override
  String get filterUnread => 'Sin leer';

  @override
  String get device => 'Dispositivo';

  @override
  String messageCountSubtitle(String app, String messages) {
    return '$app · $messages';
  }

  @override
  String get footnoteCleared =>
      'Estas notificaciones se borraron en tu teléfono, así que ya no se pueden responder desde aquí.';

  @override
  String footnoteNoReplies(String app) {
    return '$app no admite respuestas en esta conversación.';
  }

  @override
  String get unknownSender => 'Remitente desconocido';

  @override
  String get dividerNew => 'Nuevos';

  @override
  String get copied => 'Copiado';

  @override
  String get dismissedOnPhone => 'Descartada en el teléfono';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get hideConversations => 'Ocultar conversaciones';

  @override
  String get showConversations => 'Mostrar conversaciones';

  @override
  String unmuteApp(String app) {
    return 'Activar avisos de $app';
  }

  @override
  String muteApp(String app) {
    return 'Silenciar avisos de $app';
  }

  @override
  String get threadChat => 'Chat';

  @override
  String get threadGroup => 'Grupo';

  @override
  String get threadNotification => 'Notificación';

  @override
  String get replyHint => 'Responder';

  @override
  String replyToHint(String name) {
    return 'Responder a $name';
  }

  @override
  String get sendWithEnter => 'Enviar (Intro)';

  @override
  String get actionSend => 'Enviar';

  @override
  String get filterTitle => 'Filtrar';

  @override
  String get actionClearAll => 'Borrar todo';

  @override
  String get filterShow => 'Mostrar';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterUnreadOnly => 'Solo sin leer';

  @override
  String get filterWhen => 'Cuándo';

  @override
  String get filterSharedWith => 'Compartido con';

  @override
  String get filterPhone => 'Teléfono';

  @override
  String get filterApp => 'App';

  @override
  String get filterAllApps => 'Todas las apps';

  @override
  String showNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count notificaciones',
      one: 'Mostrar 1 notificación',
    );
    return '$_temp0';
  }

  @override
  String get actionShowMore => 'Mostrar más';

  @override
  String get browseSharedWithIt => 'Ver lo que has compartido con él';

  @override
  String get browseItsHistory => 'Ver su historial de notificaciones';

  @override
  String get swipeUnread => 'No leída';

  @override
  String get swipeRead => 'Leída';

  @override
  String get diagnosticsIntro => 'Aquí no se incluye el texto de las notificaciones ni las claves de cifrado.';

  @override
  String get reportCopied => 'Informe copiado';

  @override
  String get actionCopyReport => 'Copiar informe';

  @override
  String get checkingAgain => 'Comprobando de nuevo…';

  @override
  String get actionCheckAgain => 'Comprobar de nuevo';

  @override
  String get diagnosticsReportNote => 'El informe se mantiene en inglés para que pueda leerlo quien te ayude.';

  @override
  String get welcomeEncryption =>
      'Cifrado de extremo a extremo con una clave que solo tienen tus dispositivos. El servidor retransmite texto cifrado que no puede leer.';

  @override
  String get theOtherDevice => 'El otro dispositivo';

  @override
  String get appsShareIntro => 'Elige qué llega a tus dispositivos. Se aplica incluso con AirReply cerrado.';

  @override
  String get appsOnlySelected => 'Solo seleccionadas';

  @override
  String get searchApps => 'Buscar apps';

  @override
  String get appsNothingSelected => 'Nada seleccionado: no se comparte ninguna notificación';

  @override
  String appsSelected(int count) {
    return '$count seleccionadas';
  }

  @override
  String get appsOnlySelectedHint => 'Elige «Solo seleccionadas» para escoger qué apps llegan a tus dispositivos.';

  @override
  String get appsChoiceLoadFailed => 'No se pudo cargar tu selección';

  @override
  String get appsMutedIntro =>
      'Las apps silenciadas siguen llegando a Notificaciones, pero nunca te avisan en este dispositivo.';

  @override
  String get appsNoneYet => 'Aún no hay apps';

  @override
  String get appsNoneYetHint => 'Las apps aparecen aquí cuando tu teléfono ha enviado alguna notificación suya.';

  @override
  String get appMuted => 'Silenciada';

  @override
  String get appAlertsOn => 'Avisos activados';

  @override
  String get appsNoMatch => 'Ninguna app coincide';

  @override
  String get appsListFailed => 'No se pudieron listar las apps';

  @override
  String get appsReading => 'Leyendo las apps instaladas…';

  @override
  String get alertChannelName => 'Otras notificaciones';

  @override
  String get alertChannelDescription => 'Notificaciones reenviadas desde tu teléfono vinculado';

  @override
  String get alertReply => 'Responder';

  @override
  String get alertReplyHint => 'Responder…';

  @override
  String get alertOpenApp => 'Abrir AirReply';

  @override
  String get alertNewNotification => 'Notificación nueva';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Igual que este dispositivo';

  @override
  String languageSystemCurrent(String language) {
    return 'Igual que este dispositivo ($language)';
  }

  @override
  String get previousDevicesTitle => 'Dispositivos anteriores';

  @override
  String previousDevicesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos quitados, historial guardado',
      one: '1 dispositivo quitado, historial guardado',
      zero: 'Aquí se guarda el historial de los dispositivos quitados',
    );
    return '$_temp0';
  }

  @override
  String get previousDevicesIntro =>
      'Cuando quitas un dispositivo, su historial se queda en este dispositivo. Vincula el mismo dispositivo de nuevo para seguir donde lo dejaste, o borra el historial aquí.';

  @override
  String get previousDevicesNone => 'No hay dispositivos anteriores';

  @override
  String get previousDevicesNoneHint => 'Aquí aparece el historial de los dispositivos que quites.';

  @override
  String previousDeviceSummary(String date, String count) {
    return 'Quitado: $date · $count';
  }

  @override
  String previousDeviceRemoved(String date) {
    return 'Quitado: $date';
  }

  @override
  String previousDeviceContinue(String name) {
    return 'Vincula $name de nuevo para continuar este historial en tu bandeja.';
  }

  @override
  String get actionDeleteHistory => 'Borrar historial';

  @override
  String deleteHistoryTitle(String name) {
    return '¿Borrar el historial de $name?';
  }

  @override
  String get deleteHistoryMessage =>
      'Sus notificaciones y respuestas se borran de este dispositivo. No se puede deshacer.';

  @override
  String historyDeleted(String name) {
    return 'Historial de $name borrado';
  }

  @override
  String get actionDeleteAll => 'Borrar todo';

  @override
  String get deleteAllHistoryTitle => '¿Borrar todo el historial anterior?';

  @override
  String get deleteAllHistoryMessage =>
      'El historial de todos los dispositivos quitados se borra de este dispositivo. No se puede deshacer.';

  @override
  String get allHistoryDeleted => 'Historial anterior borrado';

  @override
  String get feedbackReportTitle => 'Informar de un problema';

  @override
  String get feedbackReportSubtitle => '¿Algo no funciona? Cuéntanos qué ha pasado';

  @override
  String get feedbackIdeaTitle => 'Sugerir una función';

  @override
  String get feedbackIdeaSubtitle => 'Una idea para mejorar AirReply';

  @override
  String get feedbackKindLabel => 'Tipo';

  @override
  String get feedbackKindProblem => 'Problema';

  @override
  String get feedbackKindIdea => 'Idea de función';

  @override
  String get feedbackAreaLabel => '¿Sobre qué es?';

  @override
  String get feedbackAreaNotifications => 'Notificaciones';

  @override
  String get feedbackAreaReplies => 'Respuestas';

  @override
  String get feedbackAreaPairing => 'Vinculación';

  @override
  String get feedbackAreaAlerts => 'Avisos';

  @override
  String get feedbackAreaSync => 'Sincronización';

  @override
  String get feedbackAreaDesign => 'Aspecto';

  @override
  String get feedbackAreaOther => 'Otra cosa';

  @override
  String get feedbackMessageLabel => 'Tu mensaje';

  @override
  String get feedbackProblemHint => '¿Qué ha pasado y qué esperabas? Los pasos para reproducirlo ayudan mucho.';

  @override
  String get feedbackIdeaHint => '¿Qué te gustaría que hiciera AirReply y en qué te ayudaría?';

  @override
  String get feedbackTooShort => 'Escribe un poco más (al menos 10 caracteres).';

  @override
  String get feedbackIncludeDetails => 'Incluir datos del dispositivo';

  @override
  String get feedbackDetailsSubtitle =>
      'Sistema, modelo, idioma de la app y función. Nunca tus notificaciones ni tus claves.';

  @override
  String get feedbackSent => '¡Gracias! Tu app de correo está lista: toca enviar allí para terminar.';

  @override
  String get feedbackNoEmailApp => 'No hay ninguna app de correo configurada en este dispositivo.';

  @override
  String get alertChannelPopUp => 'Mensajes';

  @override
  String get alertChannelSilent => 'Notificaciones silenciosas';

  @override
  String get alertStatusChannelName => 'Estado de las respuestas';

  @override
  String get alertStatusChannelDescription =>
      'Te avisa cuando no se pudo enviar una respuesta escrita en una notificación';

  @override
  String alertReplyNotSent(String name) {
    return 'No se envió la respuesta a $name';
  }

  @override
  String get alertStyleTest => 'Enviar un aviso de prueba';

  @override
  String get alertStyleTestTitle => 'AirReply';

  @override
  String get alertStyleTestText => 'Así te avisará un mensaje.';

  @override
  String pairFinishingOn(String name) {
    return 'Terminando en $name…';
  }

  @override
  String pairFinishingHint(String name) {
    return 'Mantén AirReply abierto en $name. La vinculación termina cuando ambos dispositivos la han guardado.';
  }

  @override
  String pairUnconfirmedTitle(String name) {
    return '$name no ha terminado de vincularse';
  }

  @override
  String pairUnconfirmedHint(String name) {
    return 'Comprueba que AirReply está abierto en $name y con conexión. Si allí ya aparece como vinculado, continúa.';
  }

  @override
  String get actionKeepWaiting => 'Seguir esperando';

  @override
  String get actionPairedThere => 'Allí ya está vinculado';

  @override
  String get actionCancelPairing => 'Cancelar vinculación';

  @override
  String get setupAssistantTitle => 'Asistente de configuración';

  @override
  String setupAssistantProgress(int done, int total) {
    return '$done de $total hechos';
  }

  @override
  String get setupAssistantIntroTitle => 'Mantén AirReply funcionando';

  @override
  String get setupAssistantIntro =>
      'Todo lo que este dispositivo necesita para compartir o mostrar notificaciones de forma fiable, también en segundo plano. Se actualiza cuando cambias los ajustes.';

  @override
  String get setupNeeded => 'Necesario';

  @override
  String get setupRecommended => 'Recomendado';

  @override
  String get setupAllDone => 'Todo listo';

  @override
  String get setupAllDoneHint => 'Todo está en orden. AirReply sigue funcionando en segundo plano.';

  @override
  String get setupCardTitle => 'Termina la configuración';

  @override
  String get actionNotNow => 'Ahora no';

  @override
  String get actionTurnOn => 'Activar';

  @override
  String get actionAutostartDone => 'Ya lo he activado';

  @override
  String get taskAccessText =>
      'Permite que AirReply lea las notificaciones que comparte. Busca AirReply en la lista y actívalo.';

  @override
  String get taskSharingText => 'Compartir está desactivado, así que nada llega a tus dispositivos.';

  @override
  String get taskListenerText =>
      'Android detuvo el servicio de escucha de notificaciones de AirReply. Reconéctalo para volver a recibir.';

  @override
  String get taskBackgroundTitle => 'Actividad en segundo plano';

  @override
  String get taskBackgroundText =>
      '«Restringir uso en segundo plano» está activado para AirReply, así que Android deja de compartir poco después de apagar la pantalla. En los ajustes de AirReply, abre Batería y elige Sin restricciones.';

  @override
  String get taskBatterySamsung =>
      'En Samsung, añade también AirReply a Aplicaciones que nunca se suspenden: Ajustes → Batería → Límites de uso en segundo plano.';

  @override
  String get taskAutostartXiaomi =>
      'Abre Seguridad → Permisos → Inicio automático y activa AirReply. Sin esto, el teléfono detiene AirReply al cerrar la app.';

  @override
  String get taskAutostartOppo =>
      'Abre Ajustes → Batería → Gestión de batería de apps, elige AirReply y permite que se inicie automáticamente y funcione en segundo plano.';

  @override
  String get taskAutostartVivo => 'Abre i Manager → Gestor de apps → Inicio automático y activa AirReply.';

  @override
  String get taskAutostartHuawei =>
      'Abre Gestor del teléfono → Inicio de apps, busca AirReply, elige Gestionar manualmente y activa los tres interruptores.';

  @override
  String get taskAlertsText =>
      'Permite que este dispositivo te avise cuando llega una notificación. Sin esto, las notificaciones siguen apareciendo en la app.';

  @override
  String get taskPairSender => 'Vincula un dispositivo con el que compartir las notificaciones de este teléfono.';

  @override
  String get taskPairReceiver => 'Vincula el teléfono cuyas notificaciones quieres ver aquí.';

  @override
  String get eraseEverythingTitle => 'Borrar todo';

  @override
  String get eraseEverythingSubtitle =>
      'Quita de este dispositivo todos los dispositivos, el historial, las claves y los ajustes, y su cuenta del servidor';

  @override
  String get eraseEverythingConfirmTitle => '¿Borrar todo?';

  @override
  String get eraseEverythingConfirmMessage =>
      'Se quitan todos los dispositivos, se borra todo el historial (también el guardado) y AirReply empieza como recién instalado. No se puede deshacer.';

  @override
  String get actionErase => 'Borrar';

  @override
  String get receiveWhenClosedTitle => 'Recibir con AirReply cerrada';

  @override
  String get receiveWhenClosedText =>
      'Un respaldo para teléfonos que retienen las alertas. Muestra una pequeña notificación de estado.';

  @override
  String get popUpsTitle => 'Deja que las alertas aparezcan';

  @override
  String get actionOpenAlertSettings => 'Abrir ajustes de alertas';

  @override
  String get popUpsPromptTitle => 'Haz que las alertas aparezcan';

  @override
  String get alertSoundOffTitle => 'Activa el sonido de las alertas';

  @override
  String popUpsWhy(String maker) {
    return '$maker solo deja que unas pocas apps, como WhatsApp, aparezcan en pantalla y suenen hasta que lo permitas. Ninguna app puede activarlo sola; basta con un interruptor.';
  }

  @override
  String get popUpsWhyGeneric =>
      'Este teléfono deja las alertas de AirReply en la lista de notificaciones, sin mostrarlas ni sonar. Ninguna app puede activarlo sola; basta con un interruptor.';

  @override
  String popUpsStepsOppo(String category) {
    return 'Toca Abrir ajustes de alertas. En la página de AirReply, activa Banner, Sonar y Vibrar. Después, en Categorías, abre $category y activa Banner también ahí.';
  }

  @override
  String get popUpsStepsXiaomi =>
      'Toca Abrir ajustes de alertas, activa Notificaciones flotantes y después Sonido y Vibración.';

  @override
  String get popUpsStepsSamsung => 'Toca Abrir ajustes de alertas, elige Alertar y activa Mostrar como emergente.';

  @override
  String get popUpsStepsGeneric => 'Toca Abrir ajustes de alertas, activa Mostrar en pantalla y elige un sonido.';

  @override
  String get popUpsFixed => 'Listo: las alertas ahora aparecerán y sonarán.';

  @override
  String get settingsAlertsEyebrow => 'Notificaciones';

  @override
  String get settingsAlertsTitle => 'Alertas';

  @override
  String get settingsSharingEyebrow => 'Teléfono';

  @override
  String get settingsSharingTitle => 'Compartir';

  @override
  String get systemAlertSettingsTitle => 'Ajustes de notificaciones';

  @override
  String get systemAlertSettingsSubtitle =>
      'Ventanas emergentes, sonido, vibración y pantalla de bloqueo, según este dispositivo';

  @override
  String get testAlertSubtitle => 'Mira cómo te avisa un mensaje ahora mismo';

  @override
  String get expectAlertsOffText =>
      'Las notificaciones siguen llegando a AirReply, pero este dispositivo no te avisará. Permite las alertas para enterarte.';

  @override
  String get expectMessagesPopUp => 'Los mensajes aparecen en pantalla con sonido';

  @override
  String get expectMessagesPopUpSilent => 'Los mensajes aparecen en pantalla sin sonido';

  @override
  String get expectMessagesList => 'Los mensajes esperan en la lista de notificaciones';

  @override
  String get expectMessagesQuiet => 'Los mensajes llegan en silencio';

  @override
  String get expectMessagesOff => 'Las alertas de mensajes están desactivadas';

  @override
  String expectOthers(String how) {
    return 'Otras notificaciones: $how.';
  }

  @override
  String get expectOthersPopUp => 'aparecen con sonido';

  @override
  String get expectOthersPopUpSilent => 'aparecen sin sonido';

  @override
  String get expectOthersList => 'en la lista, con sonido';

  @override
  String get expectOthersQuiet => 'en la lista, en silencio';

  @override
  String get expectOthersOff => 'sin alerta';

  @override
  String get expectChangeHint => 'Para cambiar algo, abre Ajustes de notificaciones abajo.';

  @override
  String get expectOffHelp =>
      'Están desactivadas en los ajustes de notificaciones de este dispositivo. Toca Abrir ajustes de alertas y actívalas.';

  @override
  String get appIconTitle => 'Icono de la app';

  @override
  String get appIconLight => 'Claro';

  @override
  String get appIconDark => 'Oscuro';

  @override
  String get appIconHint => 'El icono de AirReply en tu pantalla de inicio.';

  @override
  String get appIconChanged => 'Icono cambiado. Tu pantalla de inicio puede tardar un momento en mostrarlo.';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String deleteCount(int count) {
    return 'Eliminar $count notificaciones';
  }

  @override
  String get deleteFromDevice => 'Eliminar de este dispositivo';

  @override
  String notificationDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones eliminadas',
      one: 'Notificación eliminada',
    );
    return '$_temp0';
  }

  @override
  String get clearAllTitle => 'Borrar todo';

  @override
  String get clearAllConfirmTitle => '¿Eliminar todas las notificaciones?';

  @override
  String get clearAllConfirmMessage =>
      'Se eliminan todas las notificaciones de este dispositivo, con sus respuestas, y las alertas de AirReply salen del panel de notificaciones. No se puede deshacer. Tus dispositivos vinculados conservan las suyas.';

  @override
  String get clearAllDone => 'Todas las notificaciones eliminadas';
}
