import 'package:flutter/widgets.dart';

/// Every icon the app shows, from one icon pack: Phosphor (phosphoricons.com, MIT), regular weight everywhere and the
/// filled weight for a selected tab. Use these rather than `Icons.*`, so the whole app keeps one look and the pack can
/// change here alone.
///
/// The two Phosphor fonts are bundled in assets/fonts (with their licence); each icon is its code point in them, named
/// after it in a comment.
abstract final class AppIcons {
  static const _regularFont = 'PhosphorRegular';
  static const _fillFont = 'PhosphorFill';

  // drawn by Flutter's own buttons, set through the theme
  static const IconData back = IconData(0xe058, fontFamily: _regularFont); // arrowLeft
  static const IconData moreVert = IconData(0xe208, fontFamily: _regularFont); // dotsThreeVertical

  // the four tabs, filled while selected
  static const IconData homeSelected = IconData(0xe2c2, fontFamily: _fillFont); // house
  static const IconData notificationsSelected = IconData(0xe0ce, fontFamily: _fillFont); // bell
  static const IconData devicesSelected = IconData(0xeba4, fontFamily: _fillFont); // devices
  static const IconData settingsSelected = IconData(0xe272, fontFamily: _fillFont); // gearSix

  static const IconData add = IconData(0xe3d4, fontFamily: _regularFont); // plus
  static const IconData addLink = IconData(0xe2e2, fontFamily: _regularFont); // link
  static const IconData apps = IconData(0xe464, fontFamily: _regularFont); // squaresFour
  static const IconData arrowForward = IconData(0xe06c, fontFamily: _regularFont); // arrowRight
  static const IconData batteryAlert = IconData(0xe0c8, fontFamily: _regularFont); // batteryWarning
  static const IconData batteryChargingFull = IconData(0xe0ba, fontFamily: _regularFont); // batteryCharging
  static const IconData block = IconData(0xe3de, fontFamily: _regularFont); // prohibit
  static const IconData bolt = IconData(0xe2de, fontFamily: _regularFont); // lightning
  static const IconData campaign = IconData(0xe324, fontFamily: _regularFont); // megaphone
  static const IconData check = IconData(0xe182, fontFamily: _regularFont); // check
  static const IconData chevronRight = IconData(0xe13a, fontFamily: _regularFont); // caretRight
  static const IconData close = IconData(0xe4f6, fontFamily: _regularFont); // x
  static const IconData cloudOff = IconData(0xe1b6, fontFamily: _regularFont); // cloudSlash
  static const IconData computer = IconData(0xe562, fontFamily: _regularFont); // desktopTower
  static const IconData contentCopy = IconData(0xe1ca, fontFamily: _regularFont); // copy
  static const IconData contrast = IconData(0xe18c, fontFamily: _regularFont); // circleHalf
  static const IconData description = IconData(0xe23a, fontFamily: _regularFont); // fileText
  static const IconData desktopWindows = IconData(0xe560, fontFamily: _regularFont); // desktop
  static const IconData devices = IconData(0xeba4, fontFamily: _regularFont); // devices
  static const IconData dialpad = IconData(0xe1fc, fontFamily: _regularFont); // dotsNine
  static const IconData done = IconData(0xe182, fontFamily: _regularFont); // check
  static const IconData doneAll = IconData(0xe53a, fontFamily: _regularFont); // checks
  static const IconData errorOutline = IconData(0xe4e2, fontFamily: _regularFont); // warningCircle
  static const IconData filterAltOff = IconData(0xe26c, fontFamily: _regularFont); // funnelX
  static const IconData forum = IconData(0xe17e, fontFamily: _regularFont); // chatsCircle
  static const IconData group = IconData(0xe4d6, fontFamily: _regularFont); // users
  static const IconData helpOutline = IconData(0xe3e8, fontFamily: _regularFont); // question
  static const IconData home = IconData(0xe2c2, fontFamily: _regularFont); // house
  static const IconData inbox = IconData(0xe4aa, fontFamily: _regularFont); // tray
  static const IconData infoOutline = IconData(0xe2ce, fontFamily: _regularFont); // info
  static const IconData keyboardArrowDown = IconData(0xe136, fontFamily: _regularFont); // caretDown
  static const IconData language = IconData(0xe288, fontFamily: _regularFont); // globe
  static const IconData laptopMac = IconData(0xe586, fontFamily: _regularFont); // laptop
  static const IconData linkOff = IconData(0xe2e4, fontFamily: _regularFont); // linkBreak
  static const IconData lock = IconData(0xe308, fontFamily: _regularFont); // lockSimple
  static const IconData lockOutline = IconData(0xe308, fontFamily: _regularFont); // lockSimple
  static const IconData markChatUnread = IconData(0xe16c, fontFamily: _regularFont); // chatCircleDots
  static const IconData markEmailRead = IconData(0xe216, fontFamily: _regularFont); // envelopeOpen
  static const IconData markEmailUnread = IconData(0xe218, fontFamily: _regularFont); // envelopeSimple
  static const IconData monitorHeart = IconData(0xe2ac, fontFamily: _regularFont); // heartbeat
  static const IconData moreHoriz = IconData(0xe1fe, fontFamily: _regularFont); // dotsThree
  static const IconData noPhotography = IconData(0xe110, fontFamily: _regularFont); // cameraSlash
  static const IconData notificationsActive = IconData(0xe5e8, fontFamily: _regularFont); // bellRinging
  static const IconData notificationsNone = IconData(0xe0ce, fontFamily: _regularFont); // bell
  static const IconData notificationsOff = IconData(0xe0d4, fontFamily: _regularFont); // bellSlash
  static const IconData notificationsPaused = IconData(0xe5ee, fontFamily: _regularFont); // bellZ
  static const IconData pauseCircleOutline = IconData(0xe3a0, fontFamily: _regularFont); // pauseCircle
  static const IconData person = IconData(0xe4c2, fontFamily: _regularFont); // user
  static const IconData phoneIphone = IconData(0xe1e0, fontFamily: _regularFont); // deviceMobile
  static const IconData phonelinkErase = IconData(0xee46, fontFamily: _regularFont); // deviceMobileSlash
  static const IconData podcasts = IconData(0xe0f2, fontFamily: _regularFont); // broadcast
  static const IconData qrCodeScanner = IconData(0xe3e6, fontFamily: _regularFont); // qrCode
  static const IconData refresh = IconData(0xe036, fontFamily: _regularFont); // arrowClockwise
  static const IconData reply = IconData(0xe024, fontFamily: _regularFont); // arrowBendUpLeft
  static const IconData rocketLaunch = IconData(0xe3fe, fontFamily: _regularFont); // rocketLaunch
  static const IconData schedule = IconData(0xe19a, fontFamily: _regularFont); // clock
  static const IconData search = IconData(0xe30c, fontFamily: _regularFont); // magnifyingGlass
  static const IconData searchOff = IconData(0xe30e, fontFamily: _regularFont); // magnifyingGlassMinus
  static const IconData send = IconData(0xe398, fontFamily: _regularFont); // paperPlaneTilt
  static const IconData sensors = IconData(0xe4ea, fontFamily: _regularFont); // wifiHigh
  static const IconData sensorsOff = IconData(0xe4f2, fontFamily: _regularFont); // wifiSlash
  static const IconData settings = IconData(0xe272, fontFamily: _regularFont); // gearSix
  static const IconData smartphone = IconData(0xe1e0, fontFamily: _regularFont); // deviceMobile
  static const IconData sync = IconData(0xe094, fontFamily: _regularFont); // arrowsClockwise
  static const IconData tabletMac = IconData(0xe1e6, fontFamily: _regularFont); // deviceTablet
  static const IconData textFields = IconData(0xe6ee, fontFamily: _regularFont); // textAa
  static const IconData timerOff = IconData(0xe2ba, fontFamily: _regularFont); // hourglassSimple
  static const IconData tune = IconData(0xe434, fontFamily: _regularFont); // slidersHorizontal
  static const IconData vibration = IconData(0xe4d8, fontFamily: _regularFont); // vibrate
  static const IconData videocamOff = IconData(0xe4dc, fontFamily: _regularFont); // videoCameraSlash
  static const IconData visibility = IconData(0xe220, fontFamily: _regularFont); // eye
  static const IconData visibilityOff = IconData(0xe224, fontFamily: _regularFont); // eyeSlash
  static const IconData warningAmber = IconData(0xe4e0, fontFamily: _regularFont); // warning
}
