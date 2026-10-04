# M1 — Menzil UI + V1 Araçlar (branch `menzil-araclar-m1`)

Base: v359 acceptance source (unchanged) + Menzil UI. This is NOT v359; v359's
SHA must never be used for this content.

## Scope
Araçlar hub: Kronograf, Sight Height, Pusula, Su Terazisi, Hava & Rüzgâr,
Katalog, Ayarlar. Qwen/Vision is not a tool; it is only a not-connected
"Görsel yardım" note inside Sight Height.

## Architecture
`lib/tools/{ports,domain,adapters,state,config}` + `tools_services.dart`.
UI imports ports/domain/state/services only. Packages (geolocator, sensors_plus,
flutter_compass, camera, http) appear only in `lib/tools/adapters`. No
fake/demo data in `lib/`; test doubles are in `test/support/`.

## New dependencies
geolocator ^14.1.1, sensors_plus ^7.1.1, flutter_compass ^0.8.1,
camera ^0.12.1, http ^1.6.0. `pubspec.lock` is NOT included and must come only
from the pinned-Flutter Actions workflow (Job 1), regenerated for these deps.

## iOS permissions (tools/configure_ios_info_plist.py)
Location When-In-Use (weather), Camera (Sight Height), Motion (Su Terazisi),
Microphone (text states the app records no audio; camera plugin README lists
the key — confirm in archive review). Photo library stays removed.

## Safety / scope unchanged
Solver, `validation/acceptance.json` (SHA 1d861282…7c67927d), production gate
(CLOSED), click ban, V352/V353 vacuum angular suppression. The Atış view keeps
KİLİTLİ reticle (Menzil's holds display was dropped as it contradicts V352/V353).

## Test contracts changed (reasons)
- `test_v271_removed_feature_scope.py`, `test_v274_retired_feature_surface_contract.py`:
  forbade the four tools that are now V1 scope; rewritten to "tools exist only in
  the tools tree/hub", other bans (image_picker, audio, photo library, permission_handler) kept.
- `test_configure_ios_info_plist.py`, `test_app_store_preflight.py`: new keys/motion check.
- New: `test_m1_tools_scope_contract.py`; Dart: `test/tools_domain_test.dart`,
  `test/tools_screens_test.dart`, `test/support/tool_fakes.dart`.

## Placeholders / open items
- `ToolsConfig.metNoUserAgent` contact `CONTACT_REQUIRED`: weather refuses to
  call MET Norway until a real contact is set (fail closed).
- Fonts (Barlow Condensed) not bundled.
- Vision/Qwen: interface only, not connected, nothing uploaded.
- Level/compass sign conventions and the camera flow are unverified without a
  physical iPhone. 0.01° is display resolution, not accuracy. Compass north
  reference (true/magnetic) is not claimed.

## Verification status
Python suite + offline Dart lint + compileall + gate check: run (see delivery
report). `dart format`, `flutter analyze`, `flutter test`, iOS build,
Simulator, physical iPhone: NOT RUN.
