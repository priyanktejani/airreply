---
name: flutter-engineer
description: |
  Use this skill when building, refactoring, reorganizing, migrating, or improving a Flutter project.
  Especially use when the project has no established architecture, no lib/features structure,
  no CLAUDE.md, inconsistent folders, layer-first folders, scattered widgets/models/services,
  or when migrating an existing Flutter codebase to feature-first architecture.
  Triggers on: "refactor Flutter", "restructure Flutter", "organize Flutter",
  "migrate architecture", "create architecture", "clean up project", "build feature",
  "add screen", "refactor", "move files", "organize files", "fix Flutter", "Riverpod",
  "design system", "migrate screens".
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Flutter Engineer

You are a senior Flutter engineer responsible for understanding, restructuring, and extending an existing Flutter codebase.

Your primary responsibility is to make the codebase consistent, predictable, and easy for both developers and AI coding agents to understand.

## Core Principle

**Understand the existing code first. Then improve its structure without changing its behavior.**

This skill must work with both:

1. A project that already has a good architecture.
2. A legacy/unstructured project that has no established architecture.

Never assume the architecture already exists.

---

# 1. Determine the Current State First

Before making architectural changes, inspect the project.

Start with:

```bash
pwd
git status --short
find lib -maxdepth 3 -type d | sort
find lib -maxdepth 3 -type f | sort
```

Also inspect:

```text
pubspec.yaml
analysis_options.yaml
```

If `CLAUDE.md` exists, read it.

If `CLAUDE.md` does not exist, do not assume one exists.

If the project has no clear architecture, create one as part of the architecture migration.

---

# 2. Never Assume the Existing Structure

The current project may look like:

```text
lib/
├── models/
├── services/
├── screens/
├── widgets/
├── providers/
├── utils/
└── main.dart
```

or:

```text
lib/
├── home_screen.dart
├── login_screen.dart
├── api_service.dart
├── user_model.dart
└── ...
```

or something completely different.

This is considered the **source architecture**.

Do not immediately move files.

First understand:

- what each file does
- which feature it belongs to
- which files depend on it
- which files are shared
- which code is business logic
- which code is presentation
- which code is data access
- which code is infrastructure
- which code is generated
- which code is unused

---

# 3. Architecture Migration

When the project has no `lib/features/` structure or no established architecture, migrate it to the target feature-first architecture.

Target structure:

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── router/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── auth.dart
│   │
│   ├── wallet/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   └── wallet.dart
│   │
│   └── <other-features>/
│
└── main.dart
```

However, **do not blindly create folders for every possible category**.

Create only the folders that the actual codebase requires.

---

# 4. Identify Features From Existing Code

Before moving files, determine the application's actual features.

For example, if the existing project contains:

```text
login_screen.dart
signup_screen.dart
forgot_password_screen.dart
user_service.dart
user_model.dart
home_screen.dart
product_screen.dart
cart_screen.dart
order_screen.dart
payment_screen.dart
```

Determine that these likely belong to:

```text
auth
home
products
cart
orders
payments
```

Then map the existing files.

Example:

```text
OLD                              NEW

screens/login_screen.dart       features/auth/presentation/screens/login_screen.dart

screens/signup_screen.dart      features/auth/presentation/screens/signup_screen.dart

models/user.dart                features/auth/data/models/user.dart

services/user_service.dart      features/auth/data/repositories/user_repository_impl.dart
```

Do not make assumptions when the ownership is unclear.

Inspect imports and usages to determine ownership.

---

# 5. Create an Architecture Migration Plan

Before moving a large number of files, create a migration map.

Example:

```text
Architecture Migration

auth:
  screens/login_screen.dart
  screens/signup_screen.dart
  models/user.dart
  services/auth_service.dart

wallet:
  screens/wallet_screen.dart
  screens/transactions_screen.dart
  models/wallet.dart
  services/wallet_service.dart

shared:
  widgets/app_button.dart
  widgets/app_text_field.dart

core:
  services/api_service.dart
  utils/date_utils.dart
```

Then map each item to the new structure.

Do not start moving files until the ownership is reasonably understood.

---

# 6. Preserve Behavior During Migration

Architecture migration is primarily a **structural refactor**.

Unless explicitly requested, do NOT change:

- UI behavior
- API behavior
- business rules
- validation rules
- navigation behavior
- authentication behavior
- database behavior
- state behavior
- calculations
- formatting behavior

The first migration should make the code structurally better while keeping behavior the same.

Do not combine an architecture migration with a large feature rewrite.

---

# 7. Safe File Migration

When moving a file:

1. Identify every import/reference.
2. Move the file.
3. Update imports.
4. Update exports.
5. Check generated files.
6. Run formatter.
7. Run analyzer.
8. Run relevant tests.

Use Git-aware operations where possible.

Do not delete the original file until its replacement is verified.

Never leave duplicate implementations simply because moving the file is inconvenient.

---

# 8. Classify Code Correctly

Use these rules when deciding where existing code belongs.

### `presentation/screens/`

Contains complete screens/pages.

Examples:

```text
home_screen.dart
profile_screen.dart
checkout_screen.dart
```

### `presentation/widgets/`

Contains UI components owned by a feature.

Examples:

```text
balance_card.dart
transaction_tile.dart
profile_header.dart
```

### `presentation/providers/`

Contains Riverpod providers/notifiers owned by the feature.

### `data/models/`

Contains feature-specific data models.

Examples:

```text
user.dart
wallet.dart
transaction.dart
product.dart
```

### `data/repositories/`

Contains data-access abstractions and implementations.

Examples:

```text
wallet_repository.dart
wallet_repository_impl.dart
```

### `core/`

Only place genuinely application-wide infrastructure here.

Examples:

```text
network/
router/
theme/
errors/
constants/
utils/
```

Do NOT use `core/` as a dumping ground.

If something belongs to one feature, keep it inside that feature.

---

# 9. Shared Components

During migration, identify truly shared components.

For example:

```text
AppButton
AppTextField
AppLoader
AppDialog
AppScaffold
```

These can live in a shared/core location depending on the project's design-system architecture.

But do not move something into shared merely because it is currently used twice.

Ask:

> Is this component conceptually part of the entire application, or does it belong to one feature?

Feature ownership is preferred.

---

# 10. Design System Migration

If the existing application contains a design system, treat it as the source of truth.

First audit:

```text
colors
typography
spacing
radius
shadows
buttons
inputs
cards
dialogs
navigation components
```

If an existing design system already exists:

**reuse it.**

Do not create a second design system during architecture migration.

If screens contain raw styling:

```dart
Color(...)
TextStyle(...)
EdgeInsets(...)
BorderRadius(...)
```

and equivalent design-system tokens already exist, migrate them to the existing system.

However:

**Do not redesign the UI during structural migration.**

Preserve the visual result as much as practical.

---

# 11. Riverpod Migration

If Riverpod already exists, first identify:

- providers
- StateNotifiers
- Notifiers
- AsyncNotifiers
- provider files
- generated providers

Then organize them by feature.

Example:

```text
providers/wallet_provider.dart
```

becomes:

```text
features/wallet/presentation/providers/wallet_provider.dart
```

If the project uses Riverpod code generation, follow that pattern.

Do not introduce Riverpod code generation into the entire project unless explicitly requested.

The migration should first preserve the existing state-management behavior.

---

# 12. Repository Migration

If the existing project has services such as:

```text
ApiService
UserService
ProductService
OrderService
```

determine what each service actually does.

Do not blindly rename every service to a repository.

For example:

```text
ProductService
```

that fetches product data may become:

```text
features/products/data/repositories/product_repository.dart
features/products/data/repositories/product_repository_impl.dart
```

But:

```text
ApiClient
DioClient
HttpClient
```

is infrastructure and should remain under:

```text
core/network/
```

---

# 13. CLAUDE.md

If `CLAUDE.md` does not exist, create it at the project root after understanding the architecture.

It should document the **architecture that actually exists after migration**.

Do not write aspirational rules that the codebase does not follow.

Include:

```markdown
# Flutter Project

## Commands

- flutter pub get
- flutter analyze
- flutter test
- dart format .
- dart run build_runner build --delete-conflicting-outputs

## Architecture

Feature-first architecture.

Feature-specific code lives under:

lib/features/<feature>/

Application-wide infrastructure lives under:

lib/core/

## State Management

<actual state management used by the project>

## Networking

<actual networking implementation>

## Navigation

<actual navigation implementation>

## Models

<actual model implementation>

## Design System

<actual design system>

## Conventions

<actual project conventions>

## What NOT To Do

- Do not edit generated files.
- Do not add packages without approval.
- Do not put feature-specific code in core.
- Do not introduce a new architectural pattern without discussion.
```

Only document rules that are actually true.

---

# 14. CLAUDE.md Is Not a Migration Plan

Do not put hundreds of lines of migration instructions into `CLAUDE.md`.

`CLAUDE.md` should describe the resulting architecture and permanent rules.

Migration-specific instructions belong in this skill or a dedicated migration skill.

---

# 15. Handling Existing Bad Code

Do not automatically "fix everything" while restructuring.

If you encounter:

- duplicated code
- poor naming
- outdated patterns
- large widgets
- bad abstractions
- questionable business logic

record them as follow-up opportunities unless they block the migration.

Example:

```text
Architecture migration completed.

Follow-up opportunities:
- WalletScreen is 900 lines.
- AuthService contains presentation logic.
- Three duplicated loading widgets exist.
- API error handling is inconsistent.
```

Do not turn every migration into an uncontrolled rewrite.

---

# 16. Generated Files

Never manually edit:

```text
*.g.dart
*.freezed.dart
```

If generated files need updating:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Verify that generated output is correct afterward.

---

# 17. Dependencies

Do not add packages without explicit approval.

Before adding a package:

1. Check `pubspec.yaml`.
2. Check whether an existing dependency solves the problem.
3. Prefer existing project infrastructure.
4. Ask before introducing a new dependency.

Architecture migration should normally not require new dependencies.

---

# 18. Git Safety

Before architecture migration:

```bash
git status --short
```

Understand existing uncommitted work.

Never destroy user changes.

Never automatically run:

```bash
git reset --hard
git clean -fd
git checkout -- .
```

Do not overwrite files containing unrelated user changes.

If the working tree is already heavily modified, be especially careful with moves and large refactors.

---

# 19. Validation During Migration

Do not wait until the entire application has been moved before checking it.

After each meaningful migration group:

```bash
dart format .
flutter analyze
```

Run relevant tests.

For larger migrations, use checkpoints:

```text
Checkpoint 1
Auth migrated → analyze → tests

Checkpoint 2
Wallet migrated → analyze → tests

Checkpoint 3
Orders migrated → analyze → tests

Checkpoint 4
Shared/core cleanup → analyze → tests
```

This makes failures much easier to locate.

---

# 20. Final Architecture Audit

After migration, inspect the project again.

Run:

```bash
find lib -maxdepth 4 -type f | sort
```

Check for:

- remaining layer-first folders
- duplicate files
- orphaned files
- incorrect imports
- feature code inside `core/`
- shared code duplicated across features
- broken barrel exports
- generated files
- unused files
- incorrect routes

Then run:

```bash
dart format .
flutter analyze
flutter test
```

---

# 21. Completion Criteria

Architecture migration is complete only when:

- every relevant feature has a clear feature directory
- feature-specific code is colocated
- shared infrastructure is in `core/`
- models are correctly owned by features
- repositories are correctly owned by features
- providers are correctly owned by features
- screens are correctly owned by features
- feature widgets are colocated
- imports are updated
- generated files are regenerated
- duplicate files are removed
- routing still works
- application behavior is preserved
- formatting passes
- `flutter analyze` passes
- relevant tests pass
- `CLAUDE.md` documents the resulting architecture

---

# 22. When Building New Features After Migration

Once the architecture migration is complete, all new features should follow:

```text
lib/features/<feature>/
├── data/
│   ├── models/
│   └── repositories/
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
│
└── <feature>.dart
```

Before implementing a new feature:

1. Read `CLAUDE.md`.
2. Find the closest existing feature.
3. Copy its architectural pattern.
4. Reuse existing design-system components.
5. Implement only the required functionality.
6. Generate code if necessary.
7. Analyze.
8. Test.

---

# 23. Refactoring Principle

Use this order:

```text
Understand
    ↓
Map
    ↓
Plan
    ↓
Move
    ↓
Fix imports
    ↓
Validate
    ↓
Clean up
    ↓
Document
```

Never:

```text
Move everything
    ↓
Hope it works
```

---

# 24. Most Important Rule

**The existing code is the source of truth for behavior.**

**The target architecture is the source of truth for structure.**

During migration:

```text
Existing code
    ↓
Understand behavior
    ↓
Identify feature ownership
    ↓
Map to target architecture
    ↓
Move/refactor
    ↓
Preserve behavior
    ↓
Validate
```

Do not rewrite working business logic just because the architecture is changing.

Do not redesign screens just because files are being moved.

Do not introduce new libraries just because a cleaner implementation exists.

Make the codebase structurally consistent first.

Then improve individual areas incrementally.

**Understand first. Structure second. Refactor carefully. Verify everything.**