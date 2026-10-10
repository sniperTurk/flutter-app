# SNIPER TÜRK V1 — Claude Code verification entry point

Do not restart or regenerate the project. Work from the current source tree.

Before declaring a Flutter change verified, run:

```bash
tools/claude_flutter_verify.sh
```

The script requires the Flutter version pinned in `.fvmrc` and fails closed if the SDK is missing or a different version is active. It runs dependency resolution without lockfile drift, formatting, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test --coverage --reporter=expanded`, the complete offline Python regression suite, and the production G1/G7 gate. On macOS with Xcode it additionally bootstraps the pinned iOS scaffold and performs an iOS Simulator build.

## Environment bootstrap for Claude Code

If the pinned Flutter SDK is not already installed, and the environment has network access, run:

```bash
tools/claude_bootstrap_and_verify.sh
```

This entry point installs/checks out the exact Flutter version from `.fvmrc` into an isolated user directory (or `SNIPER_TURK_FLUTTER_HOME`), bootstraps `pubspec.lock` only when it is genuinely absent, and then delegates to the fail-closed verification chain. If network access, Git, Flutter, dependency resolution, analyzer, tests, or iOS prerequisites fail, report the exact operation as BLOCKED/FAILED; never convert it to PASS.

## First lockfile bootstrap

The repository intentionally must not pretend a lockfile exists. If `pubspec.lock` is absent, install/use the pinned Flutter SDK and run exactly once:

```bash
SNIPER_TURK_BOOTSTRAP_LOCKFILE=1 tools/claude_flutter_verify.sh
```

Review the generated `pubspec.lock` and commit it. Subsequent verification must run without `SNIPER_TURK_BOOTSTRAP_LOCKFILE`; any lockfile drift is a failure.

## CI

The authoritative hosted macOS workflow is `.github/workflows/ios-ci.yml`. Local verification is not evidence that GitHub Actions itself passed. If repository access is available, push/PR the commit and require the `iOS CI / verify` job to finish successfully. Never report CI, Simulator, device, signing, TestFlight, or App Store upload as passed unless that exact operation actually ran successfully.

## Dart formatting
CI runs `dart format --set-exit-if-changed`. The source has never been passed
through the SDK formatter (offline tooling cannot do it). On a machine with the
pinned Flutter/Dart SDK run `tools/format_dart.sh`, review and commit the diff
before expecting the format gate to pass.

## UI rule: explain every entered value (owner, 2026-10-07)
Whenever a page is added or edited, every value the user types or picks
(MenzilInput / MenzilSelect) gets an ⓘ explanation via the `info:` parameter
(`MenzilInfoButton`). Keep the text short, in Turkish, and say what the value
is, where to find it and a typical example. Plain identity fields (brand,
model, name) may skip it. Profil texts live in
`lib/features/profiles/profile_field_info.dart`; follow the same pattern for
other pages.

## UI rule: select over typing, two boxes per row (owner, 2026-10-11)
Typed product names and calibers are mistyped, so a value that can be chosen
from a list is a `MenzilSelect` (Tüfek Marka | Model | Kalibre and Mühimmat
Marka | Model come from `lib/data/rifle_library.dart`,
`factory_ammo_library.dart` and `bullet_library.dart`; typed boxes only after
"Listede yok"). Keep two boxes per row (Marka | Model side by side); Kalibre
and similar long single values take a full row. No helper text under a field:
every explanation goes into its ⓘ. Labels have no parentheses ("Yiv oranı",
not "Yiv oranı (1:…)").
