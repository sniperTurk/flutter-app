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
"Listede yok"). Keep two boxes per row (Marka | Model side by side); every
row holds two boxes, Kalibre included (e.g. Namlu çıkış hızı | Kalibre share a
row); a long selected value wraps or is shortened inside its box. No helper
text under a field: every explanation goes into its ⓘ. Labels have no parentheses ("Yiv oranı",
not "Yiv oranı (1:…)").

## Working preferences (owner, 2026-10-14)
- Reply to the owner in Turkish, briefly; use Istanbul time.
- "bekle" means stop and wait. "tamam/evet" alone is not always a go-ahead; act on "başla", "yap", "görev aç", "yükle".
- Never add anything the owner did not ask for; do only what was said.
- The owner's main session does not write app code; every code change is a Superpowers task delivering a draft PR with a plain-Turkish report (what, how, why, edge cases, not done, tests, CI links).
- Hide removed features, never delete them: gate behind `bool.fromEnvironment('FLAG')`, default off; keep saved user data.
- Product data comes from manufacturers only (maker sites/PDFs/catalogues). No forum, blog or dealer values (dealer sites only as brand/model hint lists). Never use data from other ballistic apps (ChairGun, Strelok, Applied Ballistics, QuickLOAD, GRT, JBM). AI output is a hint list only. Respect robots.txt.
- Do not add a form field the calculation cannot use (e.g. no "Namlu tipi"; the barrel's effect enters through measured velocity and group size; use one profile per barrel).
- Text is left-aligned everywhere, popups included; only the Hedef page is justified. An open dropdown list is never wider than its box.
- Never report CI, Simulator, TestFlight or App Store as passed unless that exact operation ran successfully.
- Before every TestFlight build, run an end-to-end calculation audit (user input → displayed number) covering all changes merged since the previous TestFlight: compare against independent references (never another ballistic app), check hidden-flag paths, and check interactions between changes (empty fields, defaults, moved fields). It reports only; fixes go to separate tasks. Do not start TestFlight while a high-severity finding is open.
- The audit findings' tests under test/audit_*/ stay in the suite as regression guards; a fixed finding's `skip:` test is un-skipped and must pass.
- Use these plugins while writing and developing the app (owner, 2026-10-15): Frontend Design for any UI work; Exa for research (manufacturer sources only, same source rules as above); Code Review and Security review on every PR before it is merged.
