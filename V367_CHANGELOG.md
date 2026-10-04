# V367 — independent audit of V366 (Dart defects invisible to the Python suite)

Solver, `validation/acceptance.json` (SHA 1d861282…7c67927d), catalog data, Atış/Tablo KİLİTLİ behaviour and the
closed G1/G7 gate are untouched. Flutter/Dart/Xcode are not available locally: every Dart change below was made by
reading code and is NOT compiled. See V367_DENETIM_RAPORU.md for evidence, severity and what was deliberately left alone.

Fixed: `const … Semantics(` (2 files), missing `dart:ui` FontFeature import, `num` from `double.clamp` (7 sites),
`unnecessary_null_comparison`, `prefer_if_null_operators`, unnecessary `!` (profiles screen), archived tests analysed by
`flutter analyze`, tool-hub tests without Material, `bySemanticsLabel` without semantics, lazy-list catalog tests,
contradictory codec test, racy profile-store test, integration-test scrolling/clean-install, Su Terazisi portrait lock,
Pusula duplicate VoiceOver reading, Hava spoken wind direction + clock-driven freshness + location-failure notice,
camera dispose/flash/preview aspect (resolution preset: V368 restored `high`), Sight Height marking page landscape layout, geometry lower bound,
iOS orientation declaration, bootstrap diagnostics (format patch + logs; still fail-closed), pubspec Dart floor.
