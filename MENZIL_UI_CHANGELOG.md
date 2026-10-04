# Menzil UI standardisation (on top of the PRE-V352 candidate)

This is a UI/UX-only change set. It is **not** V352. No solver, catalog,
profile model, persistence, validation policy, tolerance or production-gate
code was changed. The production G1/G7 gate remains CLOSED.

## What changed

- **Design system** (`lib/ui/`): one token layer (`menzil_theme.dart`: colours
  for light/dark, radius, spacing, type, Material `ThemeData`), shared widgets
  (`menzil_widgets.dart`: MenzilTopBar, MenzilBottomNavigation, MenzilCard,
  MenzilInput, MenzilSelect, MenzilFieldGrid, MenzilSectionHeader,
  MenzilMetricGrid/Card, MenzilHoldCard, MenzilAccordion, MenzilNotice,
  MenzilPrimaryButton, MenzilSecondaryButton, MenzilToolTile, MenzilStepButton),
  line icons (`menzil_icons.dart`) (the correction reticle `menzil_reticle.dart` was removed in M1, see M1_CHANGELOG.md).
- **Shell** (`home_screen.dart`): fixed Menzil top bar (brand, active-profile
  selector, unit, theme) and five tabs: Atış, Tablo, Ortam, Profil, Araçlar.
  Active-profile loading/reconciliation code is unchanged.
- **Atış / Tablo / Ortam** (`ballistics_screen.dart`): three views over one
  state object. Parsing, validation, unit conversion and the solver call are
  unchanged. The shot view evaluates the last validated inputs at the dialled
  range through the same `BallisticEngine.solve` call. Turret clicks and wind
  holds stay suppressed for the vacuum baseline (V345 policy).
- **Profil** (`profiles_screen.dart`): embedded tab with active-profile marker,
  Yeni profil / Kopyala / Sil (Sil keeps the confirmation dialog), full-screen
  two-column editor, read-only catalog values. Copy uses the existing
  `ProfileStore.save`.
- **Araçlar** (`features/tools/tools_screen.dart`): Katalog and Ayarlar only.
  Retired tools (chronograph, photo sight height, compass, level) stay absent.
- **Katalog / Ayarlar**: restyled headers and app bars; logic untouched.

## Pre-existing defect fixed

`catalog_screen.dart` used `Wrap(mainAxisSize: ...)` twice. `Wrap` has no
`mainAxisSize` parameter in Flutter 3.47.2, so the source did not compile.
Replaced with `Row(mainAxisSize: MainAxisSize.min, ...)`.

## Tests

- New: `test/menzil_shell_test.dart`, `test/menzil_responsive_test.dart`
  (iPhone SE 320×568, iPhone 15 393×852, Pro Max 430×932; text 1.0× and 1.3×;
  dark theme).
- `test/ballistics_*_wiring_test.dart`: inputs located by key instead of
  label text (label and unit now render above the field). Steps and
  assertions are unchanged.
- `integration_test/app_launch_test.dart` and three Python contracts that
  pinned the old hub navigation labels were updated to the tab flow; their
  intent (catalog route, profile create + platform persistence, DOPE unlock,
  settings route) is unchanged. Python suite still 499 tests.

## Verification status in the authoring environment

| Check | Result |
|---|---|
| Offline Dart lint (`tools/offline_dart_lint.py`) | PASS, 66 files |
| Python suite (`unittest discover -s tools`) | PASS, 499/499 |
| Production gate (`tools/verify_production_gate.py`) | CLOSED |
| Named-parameter / deprecation check against Flutter 3.47.2 source | 0 issues |
| `dart format`, `flutter analyze`, `flutter test`, iOS build | **NOT RUN** — Dart SDK download (storage.googleapis.com) blocked |

Run `tools/claude_bootstrap_and_verify.sh` (or `tools/format_dart.sh` then
`tools/claude_flutter_verify.sh`) on a machine with the pinned SDK before
treating this as verified.

## Fonts

Headings and numbers request Barlow Condensed and fall back to the system
face with tabular figures. To ship the exact face, add the OFL TTFs under
`assets/fonts/` and a `fonts:` entry (family `Barlow Condensed`) in
`pubspec.yaml`; no code change is needed.
