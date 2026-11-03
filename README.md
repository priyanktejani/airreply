# AirReply

See an Android phone's notifications on your other devices — **iPhone, iPad, Mac, Windows, Linux, a browser or
another Android** — and **reply to messages** (WhatsApp, Telegram, SMS, Instagram…) from any of them. The phone
fires the original app's own `RemoteInput` reply action, so the reply goes out exactly as if it had been typed into
the notification on the phone.

Pairing is many-to-many: one phone can share with several devices, and one desktop can show several phones.
Everything is **end-to-end encrypted** per pair: the two devices agree on a key with X25519, then seal every
notification and reply with AES-256-GCM. Firebase only relays ciphertext.

Flutter 3.44 · Dart 3.12 · Riverpod 3 · go_router · Firebase (Auth, Firestore, Messaging, Functions) · Kotlin.

## Platforms

| Platform | Role | Backend transport | Alerts while closed | QR scan |
|---|---|---|---|---|
| Android | **sender** or receiver | FlutterFire (realtime) | push (FCM) | ✓ |
| iOS / iPadOS | receiver | FlutterFire (realtime) | push (generic text, see notes) | ✓ |
| macOS | receiver | FlutterFire (realtime) | while running (keeps running when the window closes) | ✓ |
| Windows | receiver | Firebase REST, polling every 3 s | while running | type code |
| Linux | receiver | Firebase REST, polling every 3 s | while running | type code |
| Web | receiver | FlutterFire (realtime) | while the tab is open | ✓ |

**Why only Android can share:** only Android lets an app read other apps' notifications
(`NotificationListenerService`). iOS gives no app access to other apps' notifications, so an iPhone can show and
answer an Android phone's notifications, but cannot share its own.

**Why REST on Windows and Linux:** FlutterFire has no Linux support, and its Windows support is for development
only. Both use the same repository interfaces backed by the Firebase REST APIs (Identity Toolkit + Firestore), with
the same security rules. Feeds are refreshed incrementally: every write sets a server `updatedAt`, so an idle poll
reads a single document, not the whole feed.

## Design

**Modern frosted glass**: clean, contemporary, and intuitive interface with refined frosted glassmorphism.
Translucent surfaces with background blur, fine borders, and subtle highlights for depth, paired with solid high-contrast
surfaces for maximum reading comfort. Light, dark and system themes, chosen in Settings and restored before the first frame.

* **Type:** Modern sans-serif throughout (DM Sans). Clear, moderately sized semibold page titles (24/30), compact
  section headings (18/24), readable notification titles (16/22), comfortable body text (14/20), and concise labels (11/15).
  SIL Open Font License text bundled in `assets/fonts/` and listed in Settings → Open-source licences.
* **Tokens** live in `lib/core/theme/app_tokens.dart`: colours (`AppColors` theme extension: paper `#F8F7F4`, ink
  `#1E1E1C`, secondary `#75736D`, border `#E5E2DC`, surface, glass `#D9FFFFFF`, glassBorder, glassHighlight, success
  `#2E7D56`, warning, error, disabled, with dark counterparts), a 4 px spacing scale with 24 px page padding, 10 px
  control, 16 px card, 22 px glass and 24 px sheet radii, and standard blur strengths (subtle 10 px, standard 16 px, heavy 24 px).
* **Components** (`lib/core/widgets/glass.dart` and `editorial.dart`): `GlassContainer`, `GlassCard`, `GlassNavBar`,
  `GlassSheet`, `EditorialPage`, `PageHeader`, `SectionLabel`, `RuledList`, `InfoRow` / `SwitchRow`, `StatusBadge`,
  `Stat`, `Notice`, `StateMessage`, `SkeletonList`, `AsyncButton`, `SearchField`; app icons with a monogram fallback in
  `app_icon.dart`.
* **Navigation:** four tabs (Home, Notifications, Devices, Settings): a refined floating frosted-glass navigation bar
  on phones, a navigation rail on wide windows. Designed with safe insets so it never obscures content or interferes with
  system navigation. Detail, pairing, app management and diagnostics open above the tabs.
* **Home:** live connection status card (`GlassCard`), today / unread / device metrics (`GlassContainer`),
  what needs attention with the fix, recent activity, and, on the phone, the sharing switch.
* **Notifications:** grouped by day, with one conversation's notifications folded into an expandable row; app icons;
  unread dots; search; filters for unread, time, device and app; swipe right for read/unread and left to hide, with
  Undo (long-press or the row menu do the same); mark all as read with Undo. The detail view shows the full text,
  earlier messages of the conversation, replies with delivery state, and a frosted glass reply bar.
* **Devices:** live state per device (connected, connecting, offline, needs permission), last sync and last
  notification, a frosted glass sheet with the fix for its problem, removal with confirmation, and troubleshooting answers.
* **Settings:** permissions, apps to share (phone) or muted apps (receivers), message text in alerts, sharing, sync
  status, theme, haptics, data (mark all read, restore hidden, remove all devices), diagnostics with a copyable
  report, and licences.
* **App icons** travel encrypted inside notifications: the phone attaches an app's icon (64 px PNG, at most 6 KB)
  the first time each device sees that app and then about weekly; receivers keep them on the device.

### Demo mode

The real UI on sample data, with no backend or phone needed. Useful for design reviews, screenshots, or trying the
app on any platform:

```bash
flutter run -d chrome --dart-define=AIRREPLY_DEMO=receiver
```

```bash
flutter run -d macos --dart-define=AIRREPLY_DEMO=sender
```

## How it works

```
 SENDER (Android)                                            RECEIVERS (any platform, any number)
 ─────────────────────────────────────────                   ─────────────────────────────────────
 NotificationMirrorService (Kotlin)                          Feed: every paired phone, decrypted,
   parse → filter → cache RemoteInput action                   filter by phone / app, inline reply
          │ NotificationEventHub                                     │
          ▼                                                          │ encrypt with that pair's key
 BackgroundSyncEngine: headless FlutterEngine                        ▼
   SenderSyncRunner (Dart), for each pair:
     encrypt + publish ─────►  pairs/{id}/notifications  ──► realtime (FlutterFire) / polling (REST)
     mark dismissed    ─────►        (ciphertext only)
     execute replies   ◄─────  pairs/{id}/replies  ◄──── PENDING
       └─► ReplyExecutor fires the cached PendingIntent, reports SENT / FAILED_EXPIRED
                         Cloud Functions: push "reply" (wakes the sender), push "notification" (phone alert)
```

* **Thin native layer.** Kotlin captures notifications, caches reply actions and executes replies. Encryption and
  the backend live once, in Dart, and run 24/7 in a headless engine owned by the foreground service. When a device
  is paired or unpaired, native restarts that engine so it serves the new set of pairs.
* **Verified pairing.** The phone shows a QR (`airreply://pair?c=<code>&k=<public key>`) and a 6-digit code. Both
  screens then show a verification code derived from the shared secret, and the phone confirms they match. A key
  swapped in transit (even by the backend) fails that check, or is caught immediately on the QR path.
* **History survives dismissal.** When a notification leaves the phone's status bar, its mirrored copies are
  flagged `dismissedOnSender`: receivers keep them marked "Dismissed on phone", and reply is disabled.
* **No echo.** After a reply, messaging apps append it to the notification; the listener recognises the user's own
  MessagingStyle message and does not mirror it back.

## Project layout

Feature-first clean architecture: `domain` (entities, repository interfaces, use cases; pure Dart) ←
`data` (FlutterFire / REST, secure storage, platform channels) ← `presentation` (Riverpod controllers + widgets).
Each feature's `*_providers.dart` is its composition root; the transport is picked there per platform, so screens and
use cases never know which backend they talk to.

```
lib/
  main.dart                     app entry + backgroundMain() (sender sync engine entry point)
  bootstrap.dart                backend start-up per platform, push + alert handlers
  app/                          MaterialApp.router, tab shell, pure route guard, in-app alerts for desktop/web
  background/                   entry points for isolates without UI (sync engine, FCM, alert actions)
  core/
    platform/                   AppPlatform (capabilities, transport), NotificationBridge, notification permission
    firebase/rest/              REST auth (anonymous, token refresh), Firestore REST client, polling
    theme/                      tokens, type scale, Material theme
    widgets/                    editorial components, app icon, feedback (snackbars, undo, confirm)
    crypto/ device/ storage/ ...
  features/
    session/                    DeviceSession: role, disclosure, list of pairs
    pairing/                    handshake, X25519, verification code, unpair; FlutterFire + REST repositories
    mirror/                     MirrorDocuments codec; FirestoreSyncRepository + RestSyncRepository
    home/                       Home tab
    notifications/              inbox: feed merge and grouping, read/hidden state, filters, detail, reply, alerts
    devices/                    device status rules, Devices tab, device sheet, troubleshooting
    app_management/             apps to share (phone) and muted apps (receivers)
    settings/                   preferences (alert privacy, haptics, muted apps), diagnostics, Settings tab
    sender/  permissions/  onboarding/  push/
android/app/src/main/kotlin/com/Kairo/airreply/   listener, reply executor, foreground service, headless engine
functions/src/index.ts          push relay + cleanup of ended pairs
firestore.rules                 per-member, per-role write rules
```

## Setup

Firebase project **`airreply`** is already connected (`flutterfire configure`), with:

- Anonymous sign-in enabled (`"auth"` in `firebase.json`, deployed with `firebase deploy --only auth`)
- Cloud Firestore in **asia-south1 (Mumbai)**, security rules deployed

Still to do:

1. **Upgrade the project to the Blaze plan** (Console → Usage and billing), then deploy:
   ```bash
   firebase deploy --only functions,firestore
   ```
   This adds the push functions (sender wake-up, phone alerts, history cleanup when a pair ends) and the TTL
   policy that deletes expired pairing codes. Until then, use `firebase deploy --only firestore:rules` for rule
   changes. Without functions, syncing and replies still work; pushes do not.
2. **iOS push:** in Xcode add the *Push Notifications* capability, and upload an APNs key in the Firebase console.
3. **Linux build machine:** `sudo apt install libsecret-1-dev libgtk-3-dev` (secure storage + GTK).

Run on any platform: `flutter run -d <android|ios|macos|windows|linux|chrome>`.

## Tests

```bash
flutter test
firebase emulators:exec --only auth,firestore --project demo-airreply "flutter test test/integration"
```

The unit tests cover the crypto, the pairing handshake (QR, typed code, swapped key, several devices, unpairing one
of them), the sender loop fanning out to every pair, icon delivery, the merged feed (including the sender's
de-duplicated history), day and conversation grouping, filters, read / unread / hidden state, device status and sync
state rules, preferences, the diagnostics report, the REST client's encoding/auth/retries, and the navigation guard.
Widget tests drive the real app on the demo backend: Home, opening a notification and replying, search, swipe to
hide with Undo, removing a device, theme, mark all read, muting an app, the sender's sharing switch, and the rail on
wide windows. The integration tests run two and three simulated devices over the REST transport against the Auth
and Firestore emulators **with the real `firestore.rules`**: pair, mirror, reply, dismiss, unpair, two desktops on
one phone, and strangers / wrong roles being refused.

## Notes & next steps

* **iOS background alerts** say "New notification from your paired phone": the server cannot read the content, and
  iOS does not run app code for data-only pushes reliably. A Notification Service Extension that decrypts with a
  Keychain-shared key would show the real text.
* **Windows and Linux** receive while AirReply is running; closing the window quits it. A tray icon (e.g.
  `tray_manager`) and launch-at-login would keep them receiving in the background.
* **Push tokens** use `getToken()` / `onTokenRefresh`, deprecated in firebase_messaging 17 in favour of FID
  registration; move the app and `functions/` to the new API together.
* Windows and Linux builds can't be made on a Mac; they were not built here. Their Dart code is analysed and their
  backend path is covered by the emulator tests.
* Release builds are signed with the debug key (see `android/app/build.gradle.kts`).
