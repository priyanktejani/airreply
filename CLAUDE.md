# AirReply

Mirrors Android notifications to paired devices, end-to-end encrypted, and sends replies back through the phone.

## Commands

- flutter pub get
- dart format lib test
- flutter analyze
- flutter test
- flutter build web --dart-define=AIRREPLY_DEMO=receiver  (demo data, no Firebase; also `sender`, `welcome`)
- dart run build_runner build  (after changing `history_database.dart`; drift is the only code generator)

Do not build an APK unless asked.

## Skills

Follow the project skills in `.claude/skills/` for UI and structural work: `flutter-engineer`,
`flutter-design-consistency`, `flutter-widget-preference`.

## Architecture

Feature-first. Feature code lives in `lib/features/<feature>/` (`data/`, `domain/`, `presentation/`, plus
`background/` where a feature runs outside the UI). App-wide infrastructure lives in `lib/core/`; app wiring (router,
shell, nav bar) in `lib/app/`; demo data in `lib/demo/`.

- State: Riverpod 3 (`Provider`, `Notifier`, families keyed by records). No code generation, except drift's
  `history_database.g.dart` (approved; `build.yaml` limits the generator to that file) and gen-l10n's strings.
- Navigation: go_router with a `StatefulShellRoute`; routes in `lib/app/router/`, paths built by `AppRoutes`.
- Backend: Firebase (Auth, Firestore, Messaging); a REST client in `lib/core/firebase/rest/` for Windows and Linux.
- Crypto: `cryptography` package, in `lib/core/crypto/`.

## Sync and storage

Like WhatsApp: history lives on the devices, Firestore is only a mailbox.

- `MirrorSyncRepository` (`lib/features/mirror/data/`) is the one sync implementation, over a `PairMailbox`
  (`FirestoreMailbox` or `RestMailbox`). The receiver keeps each notification and dismissal in `MessageHistory` and
  then deletes it from Firestore; a reply is deleted once the sender has reported its status. The sender keeps its own
  copy of what it published and the replies it executed.
- The history database is encrypted at rest on every platform but web: SQLite3MultipleCiphers (`hooks: user_defines:
  sqlite3: source: sqlite3mc` in pubspec.yaml), keyed with 256 random bits that `HistoryKey` keeps in the system
  keystore. `history_connection_io.dart` unlocks each connection (`PRAGMA hexkey`), encrypts a plain file in place, and
  starts afresh when the key is gone. On the web the browser's site storage holds it unencrypted (a key could only live
  beside it). Android Auto Backup is off (`allowBackup="false"`): history and keys stay on the device.
- `MessageHistory` keeps the still-encrypted payloads in a drift (SQLite) database, `HistoryDatabase`
  (`lib/features/mirror/history_providers.dart`): everything is kept, and the screens load the newest 2,000
  notifications and 1,000 replies per pair. The app and the sender's background engine (separate Flutter engines) each
  open their own WAL connection; `PRAGMA data_version` tells one when the other wrote. Kept on unpair (below). History from
  the first, SharedPreferences version is moved in on first load.
- Search and browsing read the database, never only the loaded feed. `history_fts` (FTS5, trigram tokenizer, keyed by
  the notification's rowid) holds each notification's title, text and app name, lower-cased, in plain text beside the
  sealed payload; `package_name` is a column. Both are filled on save and, for older rows (`package_name IS NULL`), as
  a feed opens. `MessageHistory.page` / `count` run the queries, keyset-paged on `(posted_at, id)`.
- `historyResultsProvider` (`lib/features/notifications/history_providers.dart`) holds one view each: `inboxSearch`,
  `homeSearch`, `deviceHistory(pairId)`. A view is a snapshot by save order (rowid, `HistoryQuery.savedUpTo`), so it
  holds still while notifications arrive; `newResultsProvider` counts the new ones and `includeNew` merges them in by
  time. A newer query drops the pages of the one before.
- `liveFeedProvider` (newest loaded) drives the inbox, counts and alerts; `allFeedProvider` adds the views on screen
  so found notifications group and open like any other. Searching a phone's name finds the device
  (`deviceMatchesProvider`, `DeviceResults`), which opens `DeviceHistoryScreen`; notification search never matches the
  device name.
- A schema change needs a `schemaVersion` bump and a step in `HistoryDatabase.migration`, tested from each older
  version (see `mirror_sync_repository_test.dart`).
- Desktop (REST) reads each pair document through one shared poll (`DocumentPolls`): the connection status and the
  pair-active check use the same read.
- Desktop doorbell (`lib/features/mirror/data/doorbell.dart`): the phone rings `doorbells/<blind index of the pair key>`
  in the Realtime Database after each notification, dismissal and reply status; Windows/Linux listen over one
  server-sent-events stream per pair and read the mailbox on each ring (backstop every 2 minutes; every 3 seconds while
  the stream is down). Off when the project has no Realtime Database (`FirebaseRestConfig.hasDatabase`). Rules in
  `database.rules.json`; emulator tests need `--only auth,firestore,database`. The project's database is
  `airreply-default-rtdb` in asia-southeast1 (`databaseURL` in `firebase_options.dart`).
- Removing the last device clears the role (`DeviceSessionController.unpair`), so the app opens on the welcome
  screen's choice again; the privacy disclosure stays accepted. While nothing is paired, setup and pairing have a back
  button (and system back, via `OnboardingBack`) that returns to that choice.
- Unpairing (`Unpair`) ends the pair on the server (`PairingRepository.endPair`: empties its mailboxes, marks it ended,
  deletes it) and removes its doorbell; the server part is capped at 10 seconds so an offline unpair never hangs. The
  other device sees the pair gone and does the same locally. Read/hidden marks of an ended pair are dropped by
  `InboxController`; the phone prunes its icon records when its sync engine starts.
- History is kept when a device is removed, as in WhatsApp: a pair that left any history becomes an `ArchivedPair`
  (`SecureArchivedPairsStore`, in the keystore with the pair's key, since its payloads stay sealed with it); one with
  none is erased. Devices → Previous devices (`/previous`, reachable while unpaired too, and linked from the welcome
  screen) lists them, opens each read-only (`previousDeviceHistory` scope, read through `ClosedMailbox`) and deletes
  them (`archivedPairsProvider`).
- The same device paired again continues its history (`ContinueHistory`, run by `DeviceSessionController.paired`
  before the pair is shown): devices are recognised by the other side's sign-in uid, `PairingCredentials.peerUid`
  (from the pairing session's `senderUid` / `receiverUid`; same role only). `MessageHistory.moveTo` re-seals each
  payload with the new pair's key and moves the rows in place (rowids, so the search index, are kept), a batch at a
  time; moved notifications are marked read (`continuedHistoryProvider`). When either pair lacks `peerUid` (made
  before it existed), the same device name and role decide (`ArchivedPair.continuesIn`); two different uids never
  match, so another person's history never joins on a shared computer.
- On start the app runs `RestoreKeptHistory` (`DeviceSessionController.restoreKeptHistory`, from `_PairEffects`):
  active pairs without `peerUid` read it once from the pair document (`PairingRepository.peerUidOf`), then every
  active pair takes back matching kept history, so a device paired again before it could be recognised gets it too.
- Delivery is at-least-once and idempotent: a document is saved (upsert by id) before its mailbox copy is deleted, so a
  failed delete or a server retry only redelivers it. Each receiver has its own pair, so its own mailbox.
- Web needs `web/sqlite3.wasm` and `web/drift_worker.js`, matching the sqlite3 and drift versions in `pubspec.lock`;
  download new ones from their GitHub releases when upgrading either package.
- A notification's sealed payload must stay under firestore.rules' 16 KB: `PublishCapturedNotification.fit` keeps
  the clear JSON under `maxPayloadBytes`, by bytes (Hindi, Chinese, emoji take 3-4 bytes a character): the icon goes
  first, then text and title are shortened with an ellipsis. Without it such notifications were refused, unseen.
- Every mailbox document has `expireAt` (30 days) for a Firestore TTL policy. Dismissals are their own documents,
  written only for notifications that were mirrored.
- `firestore.rules` must be deployed before an app with this change runs, or publishing is refused.

## Localization

Flutter's gen-l10n (https://docs.flutter.dev/ui/internationalization), configured in `l10n.yaml`.

- User-facing strings live in `lib/l10n/app_en.arb` (the template), each with an `@key` description; read them with
  `context.l10n.key` (`lib/core/l10n/l10n.dart`). Counts use ARB plurals, values use placeholders, never string
  concatenation. New screens and strings go there, not as literals.
- `lib/l10n/app_localizations*.dart` are generated on `flutter pub get` / `flutter run` (or `flutter gen-l10n`):
  never edit them (the second approved code generator, beside drift's).
- Languages: English (template), Hindi, Chinese (Simplified, `zh`), Spanish, French and German. A new language is a
  new `lib/l10n/app_<code>.arb` with every key (the same placeholders; plurals keep an `other` case), plus its code
  in `CFBundleLocalizations` (`ios/Runner/Info.plist`, `macos/Runner/Info.plist`) and `knownRegions` in both Xcode
  projects, and `android/app/src/main/res/values-<code>/strings.xml` for the sharing service's status notification.
- Every user-facing string is in the ARB files. Code with no `BuildContext` (alerts raised in the background) uses
  `appL10n()` (the language chosen in Settings, `appLocaleProvider`, else the device's). Errors are `AppError` reasons that screens describe (`context.describeError`); device states are
  `DeviceCondition`s (`DeviceStatusText`); feed periods are described by `FeedPeriodLabel`.
- Times (`lib/core/utils/time_format.dart`) take the strings first: words from the ARB files, month and weekday names
  from intl in the same language.
- Left in English on purpose: the diagnostics report (for whoever helps; the screen says so in other languages), the
  feedback email's subject and device details, device names sent at pairing, demo data, and log messages.
- `test/app/screen_sizes_test.dart` opens every tab in each language on a small phone, so a long translation that
  overflows fails a test.

## Design system

- Tokens in `lib/core/theme/`: `AppPalette` (`context.palette`), `AppSpacing`, `AppRadius`, `AppType`, `AppShadows`,
  `AppGlass`, `AppDimensions`; `AppTheme` builds the light and dark themes from them. Use tokens, not literal sizes,
  colours or radii.
- Shared widgets in `lib/core/widgets/` (`AppCard`, `CardGroup`, `InfoRow`, `GlassScrollPage`, `EmptyState`, …) and
  motion in `lib/core/animations/` (`FadeSlideIn`, `PressableScale`, `SmoothSize`, `context.motion`).
- Icons: `AppIcons` (`lib/core/theme/app_icons.dart`), the Phosphor pack bundled as fonts in `assets/fonts` (regular,
  plus filled for a selected tab). Never `Icons.*`; add a missing icon to `AppIcons` by its Phosphor code point. Back
  and close buttons get theirs from the theme's `actionIconTheme`.
- App icon: one glossy deep blue chat bubble with a white reply arrow on a flat charcoal ground (#1E1F21), in
  the style of the system's own dark icons. `tool/make_app_icon.py` (Pillow only) draws the masters in `assets/icon/`,
  the Windows `.ico`, Android's status-bar `ic_stat_air_reply.png` at each density and `assets/icon/app_logo.png`
  (the in-app `AppLogo`: the bubble alone, on clear; only the app icon has the charcoal plate);
  `dart run flutter_launcher_icons` then writes every platform's set.
- Glass (`BackdropFilter`) only on floating chrome: app bar, pinned search, nav bar, composer.
- Scrolling pages use `GlassSliverAppBar` (through `GlassScrollPage`, and on Home): reading on slides the bar away and
  scrolling back brings it back; a strip of its glass stays under the status bar, and pinned search boxes stay just
  below whatever of it shows (a pinned + floating header, since plain floating headers ignore what is pinned above).
- Every notification, app group and conversation is shown with `NotificationCard`
  (`lib/features/notifications/presentation/widgets/notification_card.dart`), which owns the layout, the press and the
  swipe (`SwipeActions`). Do not build another notification card or swipe; add to this one.

## Responsive layout

- `ScreenType` (`lib/core/utils/app_dimen.dart`): mobile below 600, tablet below 840, desktop from 840
  (`AppDimensions.maxMobileWidth` / `maxTabletWidth`, Material's window classes). `AppDimen.of(context)` gives the
  screen type and `responsive(mobile:, tablet:, desktop:)` to choose a value for it.
- Sizes stay on the design tokens on every screen; what changes with the screen type is the layout. No
  `flutter_screenutil`-style scaling.
- `WindowClassLayout` / `OrientationLayout` (`lib/core/widgets/window_class_layout.dart`) build a different layout
  per screen type (by the width they are given) or orientation. `ResponsiveCenter` / `ResponsiveSliverCenter`
  (`lib/core/widgets/responsive_center.dart`) cap content at `AppDimensions.maxContentWidth` and centre it; use them
  rather than computing side padding from `MediaQuery`.
- Phones get the floating bottom bar; tablets, phones on their side and desktops get the rail. Home is two columns on
  a desktop. `test/app/screen_sizes_test.dart` opens every screen at landscape, tablet and desktop sizes.

## Notification grouping

- `lib/features/notifications/domain/grouping.dart` decides threads. Contacts must never mix: a one-to-one chat is
  its conversation id plus the person; messages that name nobody (your own "You", "2 new messages") join a chat only
  when exactly one fits. Group chats are their id or name.
- The app's copy of a reply is only recognised when it is marked as the user's ("You"); same words from the other
  person are their message.
- Look up a notification's chat with `chatOfProvider` / `conversationProvider` (grouping), never by Android's
  notification key, which some apps share between chats.
- The phone stamps messages with their own time (MessagingStyle), so re-posted copies are exact duplicates and
  `buildFeed` drops them; two real messages with the same words are kept.

## Conventions

- Rows inside a card are square (the card clips the corners); a swipe behind a card rounds only its outer corners.
- A `CardGroup`'s rows are `InfoRow` / `SwitchRow`, or laid out like them: `AppSpacing.card` from the card's edge, a
  `InfoRow.tile`-sized leading, an `AppSpacing.md` gap, so text and hairlines line up. Rows without a leading pass
  `inset: AppSpacing.card`. A tall row keeps its icon and control beside the title (`titleHeight` alignment).
- Floating chrome at the bottom (nav bar, message box, `StickyActionBar`) sits on `BottomFade`, so content scrolling
  under it fades out instead of showing between the panel and the screen's edge.
- Tests use `FakeAccessibilityFeatures(disableAnimations: true)` through the helpers in `test/app/app_flow_test.dart`.

## macOS signing

The Mac app must be signed with a team (personal team `F9FQQ7JL29`, "Apple Development") and keep the
`keychain-access-groups` entitlement in both `macos/Runner/*.entitlements`: Firebase Authentication stores the
signed-in device in the keychain, and an ad-hoc signed build fails sign-in (so pairing) with keychain error -34018.
The development profile is "Mac Team Provisioning Profile: com.airreply.airReply"; a new Mac needs one build with
`-allowProvisioningUpdates` (or opening the project in Xcode). Secure storage itself uses the legacy keychain.

## Pairing handshake

- The sender keeps its credentials under a locally made pair id (`PairingRepository.newPairId`) before confirming;
  a refused confirmation removes them, a slow one keeps them. Each side then acknowledges by writing its own
  `senderPlatform` / `receiverPlatform` on the pair (`markReady`; already allowed by the rules), and the sender shows
  paired only once the receiver acknowledged (`watchReady`), or asks after `pairingTimingsProvider.ackTimeout`
  (keep waiting / it's paired there / cancel, which ends the pair).
- Both sides poll the session beside the live listener. The receiver keeps a `PendingJoin` (keystore) until the
  sender confirms, and `ResumeReceiverPairing` finishes it on the next start if the app was closed meanwhile.
- Covered by `test/features/pairing/handshake_test.dart` and the emulator test (acknowledgements under the real rules).

## Alerts

- How alerts appear (pop-up, sound, vibration, lock screen) is the system's, as in other messaging apps: Android has
  two fixed channels, "Messages" (`mirrored_popUp_sound_vibrate`, high importance) and "Other notifications"
  (`mirrored_normal_sound_vibrate`), from the fixed `AlertStyle()`; the bootstrap tidies away the per-choice channels
  of earlier versions. Settings → Alerts opens the system's page (`openSystemNotificationSettings`: Android, iOS, Mac,
  Windows) under `AlertExpectationBanner`, which says what messages and other notifications will do as the system
  has them now (`AlertExpectation`, read per channel by `alertDeliveryProvider`). AirReply itself only decides muted
  apps, message text in alerts and receiving while closed.
- Replying from an alert: Android needs `ActionBroadcastReceiver` in the manifest and the background handler
  (`onAlertActionInBackground`) on Android and iOS whether or not push is used; a reply that started the app is sent
  (`launchReply`); one that cannot be queued raises a "Reply not sent" alert with the reason. Receivers check history
  for writes from other isolates too. Android 15+ keeps an answered alert until the shade closes (system behaviour).
- While the app is in front, arrivals only appear in it (no popup or sound, the person's choice). Away, phones get a
  push (`functions/`, deployed in asia-south1 on the Blaze plan: `onNotificationMirrored` → `onBackgroundPush`);
  desktops and the web alert while they run (`ArrivalAlerts`, `_InAppAlerts`). iOS pushes need an APNs key in the
  Firebase console. Optional on Android receivers, for phones that hold back pushes: Settings → "Receive when AirReply
  is closed" (`receiveWhenClosed`, off by default) runs `SyncForegroundService` (type `remoteMessaging`) in receiving
  mode (`SyncPreferences.receiving`, `_runReceiving` in `sender_sync_entrypoint.dart`), alerting only while the app's
  window is not showing (`AppVisibility`); a push and the service raise the same alert id (`onlyAlertOnce`).
- Phone makers hold apps' alerts back: on OnePlus/OPPO/realme (and others) only an allowlist (WhatsApp, Telegram,
  Instagram...) keeps pop-up channels; every other app's channels are lowered to the list with no sound as they are
  created (even Slack's), and no app can raise them. `alertDeliveryProvider` reads what the system does with each
  channel in use (`AlertChannels.kt` via `alertChannel`, judged by `judgeAlertDelivery`) and, when held back, Home
  asks once (`showAlertDeliveryPrompt`, `alertPromptShown`), the Setup assistant lists `popUps` and Settings → Alerts
  shows `AlertExpectationBanner`; each opens the system page with the switch (on OnePlus/OPPO/realme the app's
  notification page: Banner, Ring and Vibrate are app-wide there, off by default, and a category offers Banner only
  once the app's is on; elsewhere the channel's page) and confirms when the person comes back fixed.
  No overlays or full-screen intents (a permission of their own; Android 14 keeps FSI for calls and alarms).
- A push the server sent more than `ArrivalAlerts.window` ago (`isLatePush`, by FCM's `sentTime`, so no clock skew
  between devices) lands without an alert: a device back online gets the backlog without one ring per message.
- Read in AirReply means gone from the system's panel: `InboxController.markRead` / `hide` take the alerts down
  (`MirroredAlerts.dismiss`, by `MirroredAlerts.alertId`, the same id in every isolate), "Mark all as read" takes down
  every mirrored alert (`dismissAll`; on Android only the `mirrored*` channels, never the sharing service's status),
  and a reply typed into an alert takes that alert down once it is queued.
- `--dart-define=AIRREPLY_DEMO_ARRIVALS=true` (with the receiver demo) brings a new answerable message every 20 seconds,
  to try alerts and replies on a device or emulator.

## Setup assistant and cleanup

- `setupTasks` (`lib/features/permissions/domain/setup_tasks.dart`) lists what the device needs, from what the app can
  read (notification access, sharing, listener, status notification, background restriction, battery, autostart —
  unknown until the person confirms it, alerts, a pair); Settings → Setup assistant and Home's "Finish setting up" card.
- Android: no backup or device transfer (`data_extraction_rules.xml`); the OS removes all app data on uninstall.
  Apple keeps keychain items after deletion, so `forgetEarlierInstall` wipes them on a fresh install (an upgrade, with
  settings present, keeps everything). Settings → Erase everything (`eraseEverythingProvider`) ends every pair, deletes
  all history, keys, sign-in and its server account, push token, alerts and settings: the only way to leave nothing
  on desktops and on the server.

## Feedback

Settings → Report a problem / Suggest a feature open `FeedbackScreen` (`/feedback?kind=problem|idea`, reachable while
unpaired too): kind, area, message and optional device details (`deviceDetails`: system and model, never a device's
own name, notifications or keys). Send opens the email app with it written out (`url_launcher`, approved; a `mailto:`
`<queries>` entry in the Android manifest) to `supportEmail` in `lib/core/config/support.dart`, a placeholder address
to replace before release.

## What not to do

- Do not add packages without approval.
- Do not put feature-specific code in `lib/core/`.
- Do not edit generated files.
