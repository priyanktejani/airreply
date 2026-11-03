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
  `history_database.g.dart` (approved; `build.yaml` limits the generator to that file).
- Navigation: go_router with a `StatefulShellRoute`; routes in `lib/app/router/`, paths built by `AppRoutes`.
- Backend: Firebase (Auth, Firestore, Messaging); a REST client in `lib/core/firebase/rest/` for Windows and Linux.
- Crypto: `cryptography` package, in `lib/core/crypto/`.

## Sync and storage

Like WhatsApp: history lives on the devices, Firestore is only a mailbox.

- `MirrorSyncRepository` (`lib/features/mirror/data/`) is the one sync implementation, over a `PairMailbox`
  (`FirestoreMailbox` or `RestMailbox`). The receiver keeps each notification and dismissal in `MessageHistory` and
  then deletes it from Firestore; a reply is deleted once the sender has reported its status. The sender keeps its own
  copy of what it published and the replies it executed.
- `MessageHistory` keeps the still-encrypted payloads in a drift (SQLite) database, `HistoryDatabase`
  (`lib/features/mirror/history_providers.dart`): everything is kept, and the screens load the newest 2,000
  notifications and 1,000 replies per pair. The app and the sender's background engine (separate Flutter engines) each
  open their own WAL connection; `PRAGMA data_version` tells one when the other wrote. Erased on unpair. History from
  the first, SharedPreferences version is moved in on first load.
- Search covers the whole history: `history_search` keeps each notification's title, text and app name in plain,
  lower-cased text (payloads stay sealed), filled on save and, for older rows, when a feed opens. While a search is on
  screen (inbox or Home, 2+ characters), `historySearchProvider` finds matches older than the loaded window and
  `allFeedProvider` merges them in, so they group and open like the rest. A schema change needs a `schemaVersion` bump
  and a step in `HistoryDatabase.migration`.
- Web needs `web/sqlite3.wasm` and `web/drift_worker.js`, matching the sqlite3 and drift versions in `pubspec.lock`;
  download new ones from their GitHub releases when upgrading either package.
- Every mailbox document has `expireAt` (30 days) for a Firestore TTL policy. Dismissals are their own documents,
  written only for notifications that were mirrored.
- `firestore.rules` must be deployed before an app with this change runs, or publishing is refused.

## Design system

- Tokens in `lib/core/theme/`: `AppPalette` (`context.palette`), `AppSpacing`, `AppRadius`, `AppType`, `AppShadows`,
  `AppGlass`, `AppDimensions`; `AppTheme` builds the light and dark themes from them. Use tokens, not literal sizes,
  colours or radii.
- Shared widgets in `lib/core/widgets/` (`AppCard`, `CardGroup`, `InfoRow`, `GlassScrollPage`, `EmptyState`, …) and
  motion in `lib/core/animations/` (`FadeSlideIn`, `PressableScale`, `SmoothSize`, `context.motion`).
- Icons: `AppIcons` (`lib/core/theme/app_icons.dart`), the Phosphor pack bundled as fonts in `assets/fonts` (regular,
  plus filled for a selected tab). Never `Icons.*`; add a missing icon to `AppIcons` by its Phosphor code point. Back
  and close buttons get theirs from the theme's `actionIconTheme`.
- Glass (`BackdropFilter`) only on floating chrome: app bar, pinned search, nav bar, composer.
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
- Tests use `FakeAccessibilityFeatures(disableAnimations: true)` through the helpers in `test/app/app_flow_test.dart`.

## What not to do

- Do not add packages without approval.
- Do not put feature-specific code in `lib/core/`.
- Do not edit generated files.
