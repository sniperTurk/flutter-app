# V366 — static-correctness fixes on top of V365

Baseline: V365 (V364 compass wording, V365 bootstrap validation). Solver, `validation/acceptance.json`
(SHA 1d861282…7c67927d), catalog, Atış/Tablo KİLİTLİ behaviour and the closed G1/G7 gate are untouched.

## Defects found and fixed (never compiled before; Flutter/Dart are not available locally)
1. **Compile error** – `_TemplatePainter.shouldRepaint` and `_MarkPainter.shouldRepaint` narrowed the parameter
   type without `covariant` (invalid override). Now `covariant`.
2. **Test infrastructure** – `host()` put `ToolsServicesScope` inside `home:`; pushed routes (camera capture,
   marking page) are siblings of `home`, so they used the real camera plugin instead of the fakes. The scope is now
   installed in `MaterialApp.builder` (as in `lib/main.dart`).
3. **Stale tests** – `menzil_shell_test` still asserted Kronograf/Pusula/Su terazisi are absent from Araçlar; the
   compass "no heading invented" test matched the word "derece" inside the always-visible notice.
4. **Analyzer (`--fatal-infos`)** – generated art const lints (explicit `ignore_for_file`), `prefer_conditional_assignment`
   in `level_screen`, `const` in `chronograph_screen`, `unnecessary_non_null_assertion` risks in
   `sight_height_screen` and `met_no_weather_provider`, potential `unnecessary_import` of `dart:typed_data`.
5. **Runtime** – the objective-diameter dialog disposed its `TextEditingController` while the close transition still
   showed the field (debug assertion). The controller now lives in the dialog's own State.
6. **Compass claim (V364 was wrong)** – V364 asserted iOS reads *magnetic* heading from the changelog line for
   `flutter_compass` 0.4.0. The 0.8.1 iOS source actually reads `CLHeading.trueHeading` (negative when undeterminable).
   Changelog and source contradict each other and nothing is verified on a device, so the UI now claims NEITHER
   true NOR magnetic north, and the "invalid reference" message again explains the location-services cause.
7. **CI** – `bootstrap-lockfile.yml` timeout 15 → 30 min (pub get + format + analyze + full test on a cold macOS
   runner; `ios-ci.yml` already allows 30).
8. Fragile taps: `ensureVisible` before every `Atış ekle` tap.

## Verification
Python suite, offline Dart lint, compileall, production-gate script: see delivery report.
`dart format`, `flutter analyze`, `flutter test`, iOS build, Simulator, physical iPhone: NOT RUN.
