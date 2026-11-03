---
name: flutter-widget-preference
description: |
  Use this skill whenever creating, refactoring, migrating, or reviewing Flutter UI widgets.
  Prefer Flutter's built-in widgets and APIs before creating custom widgets or combining
  primitive widgets to recreate existing functionality.
  Triggers on: "create widget", "build UI", "create screen", "add button", "add input",
  "refactor widget", "refactor UI", "Flutter UI", "Flutter widget", "design screen",
  "implement screen", "migrate UI", "replace widget", "clean up widgets".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Flutter Widget Preference

You are a senior Flutter UI engineer.

Your primary rule is:

> **Use Flutter's built-in widget when it already provides the required behavior. Create a custom widget only when an appropriate built-in widget does not exist or the application requires reusable/custom behavior.**

Do not recreate functionality that Flutter already provides.

---

# 1. Built-In Widgets Come First

Before creating a widget or combining multiple widgets to reproduce a standard interaction, check whether Flutter already provides the required widget.

Prefer:

```dart
TextButton(...)
```

over:

```dart
InkWell(
  onTap: ...,
  child: Text(...),
)
```

when the intended UI is a text button.

Prefer:

```dart
ElevatedButton(...)
```

over manually creating:

```dart
Container(
  ...
  child: GestureDetector(
    onTap: ...,
    child: Text(...),
  ),
)
```

when the intended UI is an elevated button.

Prefer:

```dart
IconButton(...)
```

over:

```dart
GestureDetector(
  onTap: ...,
  child: Icon(...),
)
```

when the interaction is an icon button.

Prefer:

```dart
Checkbox(...)
```

over manually implementing checkbox behavior.

Prefer:

```dart
Switch(...)
```

over manually implementing toggle behavior.

Prefer:

```dart
Radio(...)
```

over manually implementing radio-button behavior.

Prefer:

```dart
DropdownButton(...)
```

or the project's existing Material/Cupertino dropdown widget instead of building a custom dropdown unnecessarily.

---

# 2. General Widget Preference

When implementing UI, consider Flutter's built-in widgets first.

Examples include:

```text
Text
RichText
Icon
Image
FlutterLogo

Container
Padding
SizedBox
Center
Align
Expanded
Flexible
Spacer

Row
Column
Stack
Wrap
ListView
GridView
CustomScrollView

TextButton
ElevatedButton
FilledButton
OutlinedButton
IconButton
FloatingActionButton

Checkbox
Radio
Switch
Slider
DropdownButton

TextField
TextFormField

AppBar
NavigationBar
NavigationRail
Drawer
BottomSheet
Dialog
SnackBar

Card
ListTile
Divider
Chip
Badge
Tooltip

CircularProgressIndicator
LinearProgressIndicator

InkWell
GestureDetector
Dismissible
Draggable
```

This is not an exhaustive list.

Always consider the current Flutter SDK's available widgets and the project's existing dependencies.

---

# 3. Do Not Recreate Built-In Behavior

Avoid implementing a custom widget when Flutter already provides the required behavior.

Bad:

```dart
GestureDetector(
  onTap: onPressed,
  child: Container(
    padding: const EdgeInsets.all(12),
    child: Text('Continue'),
  ),
)
```

If this is simply a button, use an appropriate button widget:

```dart
TextButton(
  onPressed: onPressed,
  child: const Text('Continue'),
)
```

Bad:

```dart
GestureDetector(
  onTap: onTap,
  child: const Icon(Icons.close),
)
```

Prefer:

```dart
IconButton(
  onPressed: onTap,
  icon: const Icon(Icons.close),
)
```

Bad:

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(...),
    borderRadius: ...,
  ),
  child: Row(
    children: [
      Checkbox(
        value: value,
        onChanged: onChanged,
      ),
      Text(label),
    ],
  ),
)
```

If the application's intended UI is a standard checkbox interaction, first consider Flutter's existing checkbox/list-tile patterns before creating a custom interaction.

---

# 4. `GestureDetector` and `InkWell` Are Not Default Buttons

Do not use:

```dart
GestureDetector
```

or:

```dart
InkWell
```

as a replacement for a standard button merely because they provide `onTap`.

First determine the semantic purpose of the interaction.

Use:

```text
TextButton      → text-based button
ElevatedButton  → elevated button
FilledButton    → filled button
OutlinedButton  → outlined button
IconButton      → icon action
FloatingActionButton → primary floating action
Checkbox        → checkbox
Switch          → toggle
Radio           → radio selection
```

Use `InkWell` or `GestureDetector` when the interaction is genuinely a custom tappable surface and no appropriate built-in semantic widget exists.

---

# 5. Semantic Widgets Are Preferred

Choose widgets based on their semantic purpose, not merely their visual appearance.

For example, if something behaves like a button:

```dart
TextButton(...)
```

is preferable to:

```dart
Container(...)
```

with an `onTap`.

If something behaves like a checkbox:

```dart
Checkbox(...)
```

is preferable to a custom `Container` that toggles a boolean.

If something behaves like a switch:

```dart
Switch(...)
```

is preferable to manually animating a container.

Semantic widgets provide important behavior such as:

- accessibility
- focus handling
- keyboard interaction
- semantics
- platform conventions
- enabled/disabled states
- interaction states
- Material/Cupertino behavior

Do not throw these benefits away by recreating the interaction manually.

---

# 6. Built-In Widget + Styling Is Better Than Recreating the Widget

Using a built-in widget does **not** mean accepting its default appearance.

Customize the built-in widget when necessary.

For example:

```dart
TextButton(
  onPressed: onPressed,
  style: TextButton.styleFrom(
    padding: ...,
  ),
  child: Text(...),
)
```

or use the project's design-system styling.

Do not replace a built-in widget with a custom implementation simply because the built-in widget needs styling.

---

# 7. Existing Design System Comes Before New Widgets

The preference order is:

```text
1. Existing project widget/design-system component
                    ↓
2. Flutter built-in widget
                    ↓
3. Existing third-party widget already used by project
                    ↓
4. New custom widget
```

However, when the project's design system wraps Flutter's built-in widgets, use the project's established component if it is the correct abstraction.

For example, if the project already has:

```dart
AppButton(...)
```

that standardizes:

- typography
- colors
- spacing
- loading state
- disabled state

use `AppButton` rather than introducing another button implementation.

Do not create a second button component.

---

# 8. Before Creating a New Widget

Before creating a custom widget, search the project.

Check:

```text
lib/
```

for existing components that already solve the problem.

Search for:

- similar widget names
- similar UI
- similar behavior
- design-system components
- feature-specific components
- core/shared components

Example:

If you need a loading button, first search for:

```text
LoadingButton
AppButton
PrimaryButton
SubmitButton
Button
```

If an existing component is appropriate, reuse it.

---

# 9. When a Custom Widget Is Appropriate

Create a custom widget when:

- Flutter does not provide the required behavior.
- The design requires behavior significantly different from built-in widgets.
- The same custom UI is reused in multiple places.
- The widget represents a meaningful domain-specific component.
- The project design system requires a standardized abstraction.
- Combining built-in widgets into a reusable component significantly improves consistency.

Example:

```dart
class TransactionStatusBadge extends StatelessWidget {
  ...
}
```

This is appropriate because `TransactionStatusBadge` represents application-specific UI.

---

# 10. Do Not Create Needless Wrapper Widgets

Avoid creating widgets that only wrap one built-in widget without adding meaningful behavior.

Bad:

```dart
class MyTextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const MyTextButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text('Continue'),
    );
  }
}
```

if it is only used once and adds no project-specific behavior.

Use:

```dart
TextButton(
  onPressed: onPressed,
  child: const Text('Continue'),
)
```

Instead, create a reusable abstraction when it provides meaningful application-level consistency.

---

# 11. Widget Location Rules

Do not put every widget into one file.

Do not create a giant:

```text
widgets.dart
```

containing unrelated widgets.

Organize widgets according to ownership.

## Feature-Specific Widgets

If a widget belongs to one feature, keep it inside that feature.

Example:

```text
lib/features/wallet/
├── presentation/
│   ├── screens/
│   │   └── wallet_screen.dart
│   └── widgets/
│       ├── balance_card.dart
│       ├── transaction_tile.dart
│       └── wallet_header.dart
```

These widgets should not be moved into `core/` simply because they are widgets.

---

# 12. Core Widgets

Put genuinely application-wide widgets in `core/`.

Example:

```text
lib/core/
├── widgets/
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── app_loader.dart
│   └── app_error_view.dart
```

A widget belongs in `core/widgets/` when it is:

- generic
- reusable across unrelated features
- not coupled to a specific feature
- part of the application's shared UI infrastructure

Do not put feature-specific widgets in core.

---

# 13. Feature Ownership

Use this rule:

> **If removing a feature would make the widget meaningless, the widget belongs to that feature.**

For example:

```text
TransactionTile
BeneficiaryCard
WalletBalanceCard
OrderStatusBadge
```

should normally remain inside their respective feature folders.

Examples:

```text
lib/features/wallet/presentation/widgets/transaction_tile.dart

lib/features/transfer/presentation/widgets/beneficiary_card.dart

lib/features/orders/presentation/widgets/order_status_badge.dart
```

---

# 14. Core vs Feature Decision

When deciding where a widget belongs:

```text
Is it specific to one feature?
        │
       YES
        ↓
features/<feature>/presentation/widgets/

        NO
        ↓
Is it generic and reused across unrelated features?
        │
       YES
        ↓
core/widgets/

        NO
        ↓
Keep it close to the code that owns it.
```

Do not prematurely move widgets into core.

---

# 15. Keep Files Focused

Prefer:

```text
balance_card.dart
transaction_tile.dart
wallet_header.dart
```

over:

```text
wallet_widgets.dart
```

Each file should have a clear responsibility.

A file can contain small private helper widgets when they are tightly coupled to the primary widget.

Example:

```dart
class TransactionTile extends StatelessWidget {
  ...
}

class _TransactionAmount extends StatelessWidget {
  ...
}
```

But do not turn one file into an entire widget library.

---

# 16. Avoid Excessive Nesting

Do not create a custom widget for every tiny piece of UI.

This:

```dart
Column(
  children: [
    Text(...),
    SizedBox(...),
    Text(...),
  ],
)
```

does not automatically require three custom widgets.

Create a widget when it provides:

- reuse
- meaningful abstraction
- readability
- independent behavior
- testability
- feature/domain meaning

Do not abstract purely to reduce line count.

---

# 17. Prefer Composition

When Flutter already provides the required primitives, compose them.

For example:

```dart
Card(
  child: ListTile(
    leading: Icon(...),
    title: Text(...),
    subtitle: Text(...),
    trailing: IconButton(...),
  ),
)
```

is preferable to creating a custom implementation of a card/list item from scratch when the standard widgets meet the requirements.

---

# 18. Do Not Use `Container` Everywhere

`Container` is useful, but it should not be the default wrapper for every UI element.

Prefer the more specific widget when possible:

```dart
Padding(...)
```

instead of:

```dart
Container(
  padding: ...,
)
```

Use:

```dart
SizedBox(...)
```

for fixed spacing/sizing.

Use:

```dart
Align(...)
```

for alignment.

Use:

```dart
Center(...)
```

for centering.

Use:

```dart
DecoratedBox(...)
```

when only decoration is required.

Use:

```dart
Padding(...)
```

when only padding is required.

Use `Container` when multiple container responsibilities are genuinely needed.

---

# 19. Prefer Built-In Layout Widgets

Do not implement layout behavior manually when Flutter provides it.

Prefer:

```text
Expanded
Flexible
Spacer
Wrap
Align
Center
Padding
SizedBox
ConstrainedBox
FractionallySizedBox
AspectRatio
LayoutBuilder
```

when appropriate.

Avoid manually calculating dimensions unless the design actually requires it.

---

# 20. Accessibility and Interaction

Built-in semantic widgets should be preferred partly because they provide better accessibility and interaction behavior.

Do not replace a semantic widget with a generic gesture widget just because it is visually convenient.

When creating a custom interactive widget:

- provide appropriate semantics
- support disabled states when applicable
- support focus when applicable
- ensure sufficient touch target size
- support keyboard interaction where appropriate
- preserve platform conventions

---

# 21. Material vs Cupertino

Follow the project's established design language.

If the project is Material-based, prefer Material widgets.

If the project is Cupertino-based, prefer Cupertino widgets.

Do not introduce a mixture of Material and Cupertino components without a reason.

When both provide the required behavior, follow the existing project's convention.

---

# 22. Do Not Add Dependencies for Existing Flutter Widgets

Before adding a UI package, check whether Flutter already provides the required widget or behavior.

Do not add a package for functionality that can reasonably be implemented with existing Flutter widgets.

If a package is genuinely required, follow the project's dependency rules and obtain approval before adding it.

---

# 23. UI Refactoring

When refactoring existing UI:

1. Understand the current behavior.
2. Identify whether a Flutter built-in widget already provides the behavior.
3. Identify whether the project already has a component for it.
4. Replace unnecessary custom implementations with the appropriate existing widget.
5. Preserve behavior.
6. Preserve the intended visual design.
7. Run formatting.
8. Run `flutter analyze`.
9. Run relevant tests.

Example:

Before:

```dart
GestureDetector(
  onTap: submit,
  child: Container(
    decoration: ...,
    child: Text('Submit'),
  ),
)
```

After:

```dart
TextButton(
  onPressed: submit,
  style: ...,
  child: const Text('Submit'),
)
```

Only make this change if the interaction is semantically a text button and the resulting behavior matches the intended design.

---

# 24. Decision Rule

For every new UI component, ask these questions in order:

### Question 1

Does the project already have a component for this?

If yes:

**Reuse it.**

### Question 2

Does Flutter already provide this behavior?

If yes:

**Use the Flutter widget.**

### Question 3

Does an existing dependency already provide the required behavior?

If yes:

**Use the existing dependency.**

### Question 4

Is there genuinely no suitable existing solution?

If yes:

**Create a custom widget.**

---

# 25. Final Rule

Always prefer:

```text
Existing project component
        ↓
Flutter built-in widget
        ↓
Existing dependency
        ↓
Custom widget
```

Never choose a custom implementation merely because it gives more control.

Use the simplest semantic Flutter widget that correctly represents the intended UI.

**Do not recreate Flutter.**

**Do not create custom widgets unnecessarily.**

**Do not put feature widgets in core.**

**Do not put unrelated widgets into one file.**

**Reuse first. Built-in second. Custom last.**