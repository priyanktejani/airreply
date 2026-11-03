---
name: flutter-design-consistency
description: Refactor a Flutter app so its whole UI feels like one designed product — extract the Home Screen's visual language (spacing, typography, colors, radii, shadows, components) into shared tokens/widgets and apply it consistently across every other screen. Use when asked to unify styling, fix visual inconsistency, build a design system, or make screens "match" the Home Screen.
---

# Flutter Design Consistency Refactoring Skill

## Purpose

Refactor a Flutter application so the entire UI feels like one intentionally designed product rather than a collection of independently built screens.

The **Home Screen is the primary visual source of truth**. Analyze it first, extract its visual language, then apply that language consistently across the rest of the app.

The main objective is **design consistency**, not merely code cleanup.

---

## Core Principle

> **Do not redesign every screen independently. Define the design language once from the Home Screen, then reuse it everywhere.**

Prioritize:

1. Consistent spacing and padding
2. Consistent typography and text hierarchy
3. Consistent colors, surfaces, borders, radii, shadows, and icons
4. Consistent component sizing and alignment
5. Maximum practical widget/component reuse
6. Consistent states: loading, empty, error, disabled, selected, pressed
7. Consistent responsive behavior
8. Consistent interaction patterns
9. Minimal one-off styling
10. Clean Flutter architecture that makes consistency easy to maintain

---

## Operating Rules

### 1. Inspect before changing

Before modifying code:

- Locate the Home Screen and all reusable widgets it uses.
- Inspect the theme, color definitions, typography, dimensions, spacing, button styles, input styles, cards, app bars, navigation components, and common utilities.
- Inspect representative screens from every major feature area.
- Identify duplicated widgets and visually similar widgets implemented differently.
- Identify hard-coded values such as `EdgeInsets`, font sizes, colors, border radii, heights, widths, and shadows.
- Determine whether the application already has a design system or whether one must be extracted.

Do not start large-scale refactoring until the existing visual patterns are understood.

### 2. Treat the Home Screen as the baseline

Analyze the Home Screen for:

- Page-level horizontal margins
- Section spacing
- Vertical rhythm
- Typography hierarchy
- Heading/subheading/body/caption relationships
- Container/card treatment
- Corner radius language
- Border language
- Shadow/elevation language
- Background/surface hierarchy
- Primary/secondary/accent colors
- Button dimensions and shapes
- Icon sizes and alignment
- Image aspect ratios and corner treatments
- Chips, tabs, filters, banners, and badges
- List/grid spacing
- Section headers
- CTA patterns
- Navigation patterns
- Loading/empty/error behavior

Convert repeated observations into explicit reusable tokens/components.

### 3. Build a design system before broad UI changes

Create or consolidate a small Flutter design-system layer when appropriate.

Prefer structures such as:

```text
lib/
  core/
    theme/
      app_theme.dart
      app_colors.dart
      app_text_styles.dart
      app_spacing.dart
      app_radii.dart
      app_shadows.dart
      app_dimensions.dart
    widgets/
      app_button.dart
      app_text.dart
      app_card.dart
      app_section.dart
      app_input.dart
      app_chip.dart
      app_avatar.dart
      app_divider.dart
      app_app_bar.dart
```

Adapt this structure to the project's existing architecture instead of blindly creating duplicate folders.

Use the project's established naming and architecture conventions whenever they are sound.

---

## Design Tokens

Extract tokens instead of scattering literals through screens.

### Spacing

Create a small, intentional spacing scale rather than dozens of arbitrary values.

For example:

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
```

Do not assume these exact values must be used. Derive the actual scale from the Home Screen and existing product style.

### Typography

Define semantic text styles such as:

- display/title
- section title
- body
- body emphasis
- label
- caption
- button text
- metadata

Avoid manually specifying `fontSize`, `fontWeight`, `height`, and letter spacing in individual widgets unless there is a genuine exception.

### Colors

Centralize semantic colors such as:

- background
- surface
- elevated surface
- primary text
- secondary text
- muted text
- primary action
- accent
- border
- divider
- success
- warning
- error

Use semantic tokens rather than raw hex values in UI files.

### Radii

Define a small radius scale and reuse it across cards, buttons, inputs, images, chips, and dialogs.

Do not create many visually similar radii such as 10, 11, 12, 13, and 14 without a strong reason.

### Shadows / elevation

Standardize elevation and shadow styles. Avoid screen-specific shadow recipes when an existing surface treatment can be reused.

### Dimensions

Standardize recurring dimensions:

- minimum touch targets
- button heights
- icon sizes
- input heights
- avatar sizes
- card media ratios
- navigation heights

---

## Component Reuse Rules

### Strongly prefer reuse

Whenever two widgets have the same visual purpose, create or use one reusable component.

Examples:

- Primary CTA buttons
- Secondary buttons
- Section headers
- Product/category cards
- List rows
- Search fields
- Form inputs
- Chips
- Badges
- Tabs
- Empty states
- Error states
- Loading skeletons
- App bars
- Bottom sheets
- Dialogs

### Avoid premature abstraction

Do not combine components merely because they contain similar Flutter code.

Abstract when there is a shared:

- visual pattern,
- interaction pattern,
- semantic purpose,
- or repeated layout structure.

The goal is **maximum useful reuse**, not maximum abstraction.

### Component API quality

Reusable components should expose meaningful semantic properties instead of requiring callers to rebuild internal styling.

Prefer:

```dart
AppButton(
  label: 'Continue',
  onPressed: ..., 
  variant: AppButtonVariant.primary,
)
```

over:

```dart
Container(
  height: 48,
  padding: ...,
  decoration: ...,
  child: Text(...),
)
```

Avoid excessive configuration parameters. Keep APIs easy to use correctly.

---

## Screen Refactoring Process

For every screen other than Home:

### Step 1 — Compare

Compare the screen against the Home Screen's design language.

Look specifically for:

- inconsistent outer padding
- inconsistent section gaps
- inconsistent title placement
- different font sizes for equivalent hierarchy
- different button shapes
- different card radii
- different icon sizes
- inconsistent colors
- inconsistent divider/border treatments
- inconsistent alignment
- inconsistent image treatment
- inconsistent empty/loading/error states

### Step 2 — Replace literals with tokens

Replace arbitrary values with the appropriate shared token.

### Step 3 — Replace one-off widgets

Replace duplicated UI with existing reusable components.

### Step 4 — Normalize hierarchy

Equivalent semantic elements should look equivalent across the app.

For example:

- Every primary page title should use the same title style.
- Every primary CTA should use the same button language.
- Every card representing the same entity should share the same structure.
- Every section should follow the same spacing rhythm unless the content genuinely requires an exception.

### Step 5 — Preserve functionality

Do not change business logic, data flow, navigation, API behavior, validation, or state management unless required to support the visual refactor.

### Step 6 — Improve only when it supports consistency

Small UX/layout improvements are acceptable when they clearly strengthen the unified system, but avoid unrelated redesign work.

---

## Layout Consistency Rules

### Page margins

Use one coherent horizontal content margin system.

Do not allow screens to randomly use different values such as 14, 17, 20, and 24 for equivalent page content.

### Vertical rhythm

Use a predictable hierarchy:

```text
Page top padding
  ↓
Header/title spacing
  ↓
Section spacing
  ↓
Element spacing
  ↓
Section spacing
```

Avoid arbitrary spacer widgets and unexplained pixel values.

### Alignment

Prefer alignment consistency over individual visual optimization.

For related content:

- text edges should line up,
- cards should share consistent internal padding,
- icons should use consistent visual dimensions,
- buttons should align to the same content grid.

### Grids and lists

Standardize:

- cross-axis spacing
- main-axis spacing
- card widths
- aspect ratios
- list item padding
- divider treatment

---

## Typography Consistency

For every screen, verify semantic hierarchy rather than individual font declarations.

Example hierarchy:

```text
Page Title
Section Title
Card Title
Body
Secondary / Metadata
Caption
```

Do not solve typography inconsistencies by changing random individual widgets. Fix the shared style definition whenever the issue is systemic.

Also check:

- font family
- font weight
- font size
- line height
- letter spacing
- text color
- capitalization
- truncation
- max lines

---

## Color Consistency

Avoid:

```dart
Color(0xFF...)
```

inside normal screen widgets when the value belongs to the product design system.

Prefer semantic theme values or shared tokens.

Use local overrides only for genuinely unique content or states.

Also check contrast and ensure state colors are used consistently across equivalent components.

---

## Responsive Design

The unified system must work across reasonable Flutter device sizes.

Check:

- narrow phones
- standard phones
- large phones
- tablets where the app supports them
- portrait/landscape where applicable

Do not hard-code dimensions that unnecessarily break responsiveness.

Prefer:

- `Expanded`
- `Flexible`
- `ConstrainedBox`
- `LayoutBuilder`
- `MediaQuery` only where appropriate
- adaptive padding/layout tokens

Avoid using device width calculations everywhere when a simpler constraint-based layout works.

---

## State Consistency

Standardize the visual treatment of:

- loading
- skeleton/loading placeholders
- empty states
- errors
- retry actions
- disabled controls
- pressed controls
- selected controls
- focused inputs
- validation errors

A user should recognize the state treatment immediately regardless of which screen they are on.

---

## Flutter-Specific Refactoring Rules

- Prefer `const` constructors and widgets whenever possible.
- Keep widgets focused and readable.
- Extract repeated UI into reusable widgets rather than deeply nested screen files.
- Avoid unnecessary rebuilds introduced by visual refactoring.
- Preserve existing state-management patterns unless they are directly preventing consistency.
- Use `ThemeData`, `ColorScheme`, `TextTheme`, and component themes when they fit the existing project architecture.
- Prefer theme/component-level styling over repetitive per-widget decoration.
- Do not introduce a large dependency solely for visual consistency when existing Flutter capabilities are sufficient.
- Keep accessibility in mind, especially text scaling, semantic labels, and touch target size.

---

## Visual Audit Checklist

Before considering a screen complete, audit it against the Home Screen:

### Spacing
- [ ] Same outer margins
- [ ] Same section rhythm
- [ ] Same component internal padding
- [ ] No unexplained one-off spacing

### Typography
- [ ] Same semantic text hierarchy
- [ ] Same font family
- [ ] Same weights
- [ ] Same line heights
- [ ] Same text colors for equivalent semantics

### Components
- [ ] Same buttons
- [ ] Same cards
- [ ] Same inputs
- [ ] Same chips/tabs
- [ ] Same section headers
- [ ] Same app bars/navigation patterns

### Visual language
- [ ] Same radii
- [ ] Same borders
- [ ] Same shadows/elevation
- [ ] Same icon scale
- [ ] Same image treatment
- [ ] Same surface/background hierarchy

### Behavior
- [ ] Same interaction states
- [ ] Same loading patterns
- [ ] Same empty/error patterns
- [ ] Same responsive behavior

### Code quality
- [ ] Tokens are centralized
- [ ] Reusable widgets are actually reused
- [ ] No unnecessary duplicated styling
- [ ] No unrelated business-logic changes
- [ ] `const` usage is improved where appropriate
- [ ] No dead components left behind

---

## Exception Policy

Consistency is the default, not an absolute rule.

A screen may intentionally differ when there is a clear reason, such as:

- a specialized workflow,
- a full-screen immersive experience,
- a platform-specific interaction,
- accessibility requirements,
- materially different content density,
- or a deliberate product decision.

When keeping an exception, make it explicit and localized rather than allowing accidental drift.

---

## Definition of Done

The refactor is complete only when:

1. The Home Screen's visual language has been identified and documented in code.
2. Shared tokens exist for recurring spacing, typography, colors, radii, shadows, and dimensions.
3. Equivalent UI patterns use the same reusable components.
4. Screens no longer contain unnecessary one-off styling.
5. Visual hierarchy is consistent across the app.
6. Responsive layouts remain stable.
7. Loading, empty, error, and interaction states feel like the same product.
8. Existing application functionality still works.
9. The resulting code is easier to extend without introducing new visual inconsistency.

---

## Expected Claude Code Behavior

When this skill is invoked:

1. **Analyze the repository first.**
2. **Find and inspect the Home Screen.**
3. **Extract the current visual system from real code; do not invent a new aesthetic without evidence.**
4. **Identify inconsistencies across the app.**
5. **Create/consolidate design tokens and shared components.**
6. **Refactor screens incrementally toward the shared system.**
7. **Prefer fixing the source component/theme over patching each screen individually.**
8. **Keep business logic and behavior intact.**
9. **Run formatting, analyzer/tests, and relevant checks after changes.**
10. **Report the major consistency improvements and any intentional exceptions.**

### Important constraint

Do not make the app visually consistent by making every screen look identical.

Make it consistent by ensuring that **the same design rules produce appropriately different layouts for different content and workflows**.

The desired result is a Flutter app that feels like it was designed by one system and implemented by one team.
