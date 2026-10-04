# SNIPER TÜRK V1

SNIPER TÜRK V1 is a Flutter/iOS-first PCP and firearm ballistic companion under active development.

## Current V1 scope
- PCP / firearm platform separation and filtered catalog architecture.
- Persistent rifle profiles and active-profile selection.
- Ballistics / DOPE workflow with validated inputs and an explicitly labelled vacuum/gravity baseline solver while a validated drag/BC solver remains production work.
- Manual scope-axis-height profile input. The user enters the center-to-center value; V1 contains no scope-height calculator, camera estimation, Qwen/Vision workflow, or chronograph workflow.
- Rifle, ammunition, and scope catalog architecture with integrity validation. Bundled branded records must carry provenance; only explicit `Manuel` data-entry templates may be unsourced. Manufacturer-backed rifle variants carry variant-specific metadata, and PCP ammunition coverage includes verified 4.5/5.5/6.35 mm records without invented BC values.
- Offline-first profile/settings persistence.

## Production gaps still open
1. Implement and validate a real G1/G7 (or equivalent validated drag-model) ballistic engine against trusted reference data.
2. Continue expanding global/Türkiye catalog coverage from verified manufacturer data. Provenance is now enforced for every bundled non-manual record; breadth is the remaining catalog gap.
3. Finish production UI/UX and accessibility polish.
4. Run Flutter static analysis/tests and real iOS Simulator/device builds on a Mac/Xcode environment.
5. Complete App Store signing, privacy strings, metadata, screenshots, and release validation.

## Verification status
This source package has been structurally checked in the current environment. Flutter/Dart/Xcode toolchains are not available here, so no claim is made that `flutter test`, iOS Simulator, device build, or App Store archive has passed.

## v28 production hardening
- Profile persistence now maintains a last-known-good backup snapshot and recovers from malformed primary JSON.
- SharedPreferences write failures are surfaced instead of silently treated as successful.
- Added regression tests for backup/recovery behavior.
- Tests are added but not claimed as executed where Flutter/Dart tooling is unavailable.

## v29 production hardening
- Corrupt primary profile storage now self-heals from the last-known-good backup after recovery.
- Duplicate persisted profile ids are deterministically collapsed to the newest record during decoding.
- Added regression tests for self-healing recovery and duplicate-id cleanup.
- Ballistic targeting math was not expanded in this revision; existing solver verification status is unchanged.

## v30 production hardening
- Profile creation no longer silently substitutes fallback velocity/zero values when numeric input is malformed.
- Added a dedicated profile-input validation boundary with decimal-comma normalization, positive finite-number checks, PCP pressure validation, and explicit user-facing validation errors.
- Added regression tests for valid input, malformed numeric input, empty profile names, and PCP/firearm pressure rules.
- Ballistic targeting math was intentionally not expanded in this revision; existing solver verification status is unchanged.

## v31 production hardening
- Home/profile loading now has explicit loading, failure, and retry states instead of leaving an unhandled persistence exception or an indefinite spinner.
- Profile save failures are surfaced to the user and do not pretend the profile was persisted.
- Swipe-to-delete now commits persistence before visually removing the row; failed deletes keep the profile visible and show an error message.
- Ballistic targeting math was intentionally not expanded in this revision; existing solver verification status is unchanged.


## v32 production hardening
- Implemented the previously advertised profile edit workflow: existing profiles can now be opened, edited, and persisted under the same stable profile id rather than creating a duplicate.
- The edit dialog restores rifle, ammunition, scope, numeric fields, PCP pressure, and preserves the profile angular-unit preference.
- Added controller disposal for the profile editor to avoid leaking text controllers across repeated dialog use.
- Added a regression test proving same-id saves replace the existing profile instead of duplicating it.
- Ballistic targeting math was intentionally not expanded in this revision; existing solver verification status is unchanged.


## v33 production hardening
- Removed a stale test import/reference to the deleted `sight_height_geometry.dart` implementation. That stale reference made the test target fail at compile time before tests could run.
- Kept the current V1 product decision intact: Sight Height is a manually entered center-to-center measurement; no geometry calculator was reintroduced.
- Performed a local source import-integrity scan after the cleanup; no unresolved `package:sniper_turk/...` imports remain.
- Flutter/Dart/Xcode toolchains are unavailable in this environment, so `flutter test`, iOS Simulator/device build, and App Store archive are still not claimed as passed.

## v37 production hardening
- Fixed three Flutter test files whose newer regression tests had accidentally been appended outside `main()`, which is invalid Dart top-level executable syntax and would block the test target from compiling.
- Affected suites: `core_test.dart`, `ballistic_input_test.dart`, and `profile_store_test.dart`.
- No test pass is claimed: Flutter/Dart/Xcode are not installed in this execution environment.

## v38 production hardening
- Added a macOS GitHub Actions verification pipeline for the checks that cannot be executed in the current environment.
- CI records Flutter/Dart/Xcode versions, resolves dependencies, enforces formatting, runs `flutter analyze`, executes the Flutter test suite, and attempts a release iOS build without code signing.
- Because the repository does not yet contain an iOS runner scaffold, CI explicitly generates the iOS platform files before the build when `ios/` is absent; this makes the missing scaffold visible and reproducible rather than silently treating iOS as tested.
- CI uses read-only repository permissions, cancellation for superseded runs, a 30-minute timeout, and uploads diagnostics on failure.
- Adding CI does not mean any test or iOS build has passed; a real CI run or Mac/Xcode run is still required for that claim.


## v40 V1 scope cleanup
- Removed the stale Settings copy that still described camera/Vision and microphone measurement validation after those workflows were removed from V1.
- Renamed the user-facing manual scope-height field to `Dürbün eksen yüksekliği (mm)` so it is clearly an input, not a Sight Height calculation feature.
- Kept the numeric profile/ballistics field because the ballistic solver requires the user-supplied optical-axis-to-bore-axis height. No calculator, camera estimation, Qwen/Vision, or chronograph workflow was added.
- Flutter/Dart/Xcode execution is still unverified in this environment.

## v41 ballistic foundation
- Added a deterministic moist-air density model for the future aerodynamic solver, using station pressure, temperature, and relative humidity.
- Added density-ratio output normalized to ICAO standard sea-level density (1.225 kg/m³), so a validated drag solver can consume atmospheric density without duplicating environment math.
- Explicitly defines `pressureHpa` as absolute station pressure to prevent accidentally applying altitude correction twice.
- Added regression tests for standard dry-air density, humidity behavior, and invalid atmospheric inputs.
- This does **not** claim G1/G7 drag is implemented; the production gate that rejects unvalidated BC/model trajectories remains in place.

## v45 settings persistence hardening
- Moved unit-setting persistence behind a testable `SettingsStore` boundary.
- Settings load failures now show an explicit retry state instead of leaving an unhandled asynchronous exception or indefinite loading UI.
- Failed SharedPreferences writes are surfaced; the switch no longer changes visually unless persistence succeeds, and duplicate toggles are disabled while a write is in flight.
- Added regression tests for default loading, successful persistence, and failed-write handling.
- Tests are added but are not claimed as executed where Flutter/Dart tooling is unavailable.

## v46 catalog expansion
- Expanded the manufacturer-backed AirMaks Arms 2026 catalog with 6.35 mm Krait PRO and Krait PRO L HP variants.
- Preserved variant-specific magazine capacity, barrel length/type, reservoir capacity, overall length, weight, rail, moderator thread, and source provenance instead of copying values across the family.
- Added a regression test that locks the newly imported manufacturer values to their exact variants.
- The source values come from the user-provided `AMA Catalog 2026.pdf`; this revision does not claim broader global catalog coverage is complete.
- Flutter/Dart/Xcode execution remains unverified in this environment.

## v47 active-profile persistence hardening
- Active-profile persistence now checks the boolean result returned by SharedPreferences and throws on failed writes instead of silently treating them as successful.
- Home active-profile switching commits persistence before changing the visible selection; failed writes keep the previous active profile and show an explicit Turkish error message.
- The selector is disabled while a persistence write is in flight to prevent overlapping selection writes.
- HomeScreen stores are injectable for deterministic widget testing, and a regression test covers the failed-write UI path.
- Flutter/Dart/Xcode execution remains unverified in this environment; the new test is present but is not claimed as passed.


## v48 catalog expansion
- Added manufacturer-backed AirMaks Arms Caiman and Caiman X 6.35 mm variants from the user-provided AMA Catalog 2026.
- Imported only values that are unambiguous in the source layout: 8-shot 6.35 magazine, 400 mm choked barrel for Caiman, 520 mm choked barrel for Caiman X, Picatinny 20 MOA rail, and 1/2 UNF moderator thread.
- Deliberately left reservoir/length/weight fields unset where the extracted catalog layout did not make the per-variant mapping sufficiently unambiguous; unknown is preferred to guessed production data.
- Added a regression test locking the imported Caiman variant metadata and provenance.
- Flutter/Dart/Xcode execution remains unverified in this environment; the new test is present but is not claimed as passed.


## v49 accessibility and verification hardening
- Added explicit screen-reader semantics for the active-profile selector and loading states on Home and Settings, including live-region announcements for asynchronous loading.
- CI now collects Flutter test coverage and uploads `coverage/lcov.info` as a diagnostic artifact even when later verification fails.
- Added source-level regression checks that lock the accessibility wiring in place.
- This revision does not claim that Flutter tests, coverage generation, iOS build, Simulator, or device validation passed; those still require an environment with Flutter/Dart/Xcode.

## v50 numerical-ballistics foundation
- Added a UI-independent RK4 integrator, adapted from the useful numerical structure reviewed in the external Swift prototype and independently guarded for finite state/derivative values.
- Added a generic Mach-indexed drag-table interpolator with strict ordering/value validation.
- G1/G7 coefficient rows from the external prototype were deliberately **not** copied into production because their authoritative provenance has not yet been independently verified.
- The production aerodynamic gate remains closed: BC/G1/G7 requests are still rejected rather than silently returning unvalidated DOPE.

## v52 production hardening
- Merged the versioned profile-document persistence/migration envelope with the stricter ballistic input boundary validation.
- Ballistic inputs now reject non-finite and implausible velocity/range/BC/environment/wind values before solver execution.
- Legacy bare-list profile payloads remain readable; new writes use an explicit schema envelope and future unknown schema versions fail closed.
- No unverified G1/G7 coefficients were enabled by this merge.


## v53 ballistic workflow hardening
- Fixed a production workflow bug where selecting catalog ammunition that already had BC/model metadata caused the V1 DOPE screen to trip the intentional unvalidated-G1/G7 safety gate and return no baseline trajectory at all.
- Catalog BC/model metadata remains visible but display-only; the labelled vacuum/gravity baseline now remains usable regardless of whether the selected ammunition has BC metadata.
- The aerodynamic production gate remains closed. No G1/G7 coefficient or unvalidated drag result is consumed by the V1 solver.
- Added a regression guard preventing the Ballistics screen from accidentally wiring catalog BC/model values into the solver before independent reference-vector validation is complete.
- Flutter/Dart/Xcode execution remains unverified in this environment.


## v54 verified HATSAN catalog expansion
- Replaced the placeholder-only 6.35 mm HATSAN Factor Sniper Long, Hercules, and Blitz entries with manufacturer-verified variant metadata from HATSAN's current product pages checked on 2026-09-24.
- Added only fields represented by the existing catalog schema: magazine capacity, barrel length/type, air capacity, overall length, weight, rail information, provenance, and the Factor Sniper Long 1/2 UNF moderator thread explicitly stated by HATSAN.
- Preserved unknown instead of guessing: no moderator thread was assigned to Hercules or Blitz because the checked manufacturer pages do not state one.
- Added regression coverage locking these three 6.35 mm records to their verified manufacturer values.
- Flutter/Dart/Xcode execution remains unverified in this environment; the new regression test is present but is not claimed as passed.


## v55 verified HATSAN catalog expansion
- Expanded the manufacturer-backed 6.35 mm HATSAN catalog with Factor, Factor RC, Factor BP, Factor Sniper S, Blitz BP, Flash, Flash QE, and Repex variants from current HATSAN product pages checked on 2026-09-24.
- Imported only values represented by the existing schema and stated unambiguously for the exact variant; unknown fields remain null rather than inferred from sibling models.
- For Blitz BP, the existing air-capacity field records the manufacturer's stated 580 cc carbon-fiber bottle plus 30 cc auxiliary volume as 610 cc total.
- Added regression coverage locking the imported variant values.
- Flutter/Dart/Xcode execution remains unverified in this environment; the new regression test is present but is not claimed as passed.

## v56 production hardening
- Catalog UI now has an explicit PCP / Ateşli Tüfek platform selector and filters both rifle and ammunition lists from the same platform state. This enforces the V1 catalog-platform separation in the actual UI instead of only in repository helper methods.
- PCP remains the safe/default catalog context; optics stay global by design.
- Manufacturer-backed rifle metadata already present in the catalog is now surfaced in concise catalog rows, while incomplete records are labelled rather than guessed.
- Added widget regression coverage for default PCP isolation, firearm switching, and explicit firearm initial state.
- Flutter/Dart/Xcode toolchains are still unavailable in this environment, so these widget tests are present but are not claimed as executed successfully.


## v57 catalog expansion
- Replaced the ambiguous Huğlu Spark 6.35 placeholder with two manufacturer-backed configurations from Huğlu's 2025 Turkish catalog: Spark 420 (420 mm barrel, 350 cc reservoir, 70 cc power plenum) and Spark 600 (600 mm barrel, 500 cc reservoir, 100 cc power plenum).
- Both verified 6.35 variants retain the manufacturer-listed 10-shot magazine and 1/2 UNF moderator adapter.
- The catalog gives only a 2.75–3.0 kg family weight range, so variant weight is deliberately left unknown instead of assigning an unsupported exact value.
- Added regression coverage that locks barrel/reservoir/plenum pairings and prevents future cross-variant contamination.
- Flutter/Dart/Xcode execution remains unavailable in this environment; the added test is present but is not claimed as passed.


## v58 ballistic workflow safety
- Closed a fail-open path where the Home screen allowed opening Ballistics/DOPE without an active rifle profile and the Ballistics screen then populated plausible-looking fallback velocity, grain, zero, and sight-height values.
- Home now disables the Ballistics/DOPE navigation until an active profile exists and clearly tells the user why.
- BallisticsScreen also independently fails closed when constructed without a profile, so deep-link/future navigation changes cannot silently restore synthetic DOPE inputs.
- Added regression guards for both the Home navigation gate and the BallisticsScreen no-profile state.
- Flutter/Dart/Xcode execution remains unavailable in this environment; the new tests are present but are not claimed as passed.


## v59 production update
- Pinned the project and macOS iOS CI to Flutter 3.47.2 instead of following a floating stable channel.
- Added `.fvmrc` with the same SDK pin so local/FVM and CI environments target one reproducible Flutter toolchain.
- The CI bootstrap now verifies that the generated iOS Xcode project and Info.plist actually exist before attempting the unsigned release build.
- Flutter 3.47.2 was independently confirmed as an August 2026 stable hotfix release before pinning.
- No local Flutter/Xcode build claim is made: this environment still lacks those toolchains.

## v63 verified optics catalog foundation
- Expanded `ScopeOptic` so the production catalog can retain manufacturer-backed tube diameter, magnification range, elevation/windage travel, physical dimensions, FFP/zero-stop state, reticle, and provenance instead of reducing every optic to objective size plus click value.
- Explicitly separated optical objective diameter from physical objective-bell outer diameter. A model marked `56 mm` is no longer structurally treated as having a 56 mm outside housing; the physical value remains null unless the manufacturer publishes it.
- Added current manufacturer-backed metadata for Gazi Sniper 6–36×56 FFP, DISCOVERYOPT XED 6–36×56 FFP MRAD Zero Stop, and Arken EP-5 GENII 7–35×56 FFP VPR-MIL, verified from official product pages on 2026-09-24.
- Added integrity guards for invalid optional optic dimensions/ranges, impossible outer-objective geometry, and incomplete provenance, plus regression coverage locking the verified records.
- This revision does not claim Flutter tests or iOS builds passed; those still require an environment with the pinned Flutter toolchain and Xcode.


## v65 drag-data provenance

Authoritative G1/G7 Cd-vs-Mach reference tables are bundled in `lib/core/standard_drag_tables.dart` from JBM Ballistics BRL-sourced downloads (retrieved 2026-09-24). This does **not** enable aerodynamic DOPE yet: `BallisticEngine.solve` remains fail-closed for G1/G7 until the full solver is independently validated.

## v66 aerodynamic foundation
A unit-BC G-function reference-drag primitive now converts Cd(Mach) to SI drag deceleration using the conventional 1 lb / 1 inch reference projectile geometry. It is deliberately not connected to production DOPE until the full G1/G7 trajectory solver is independently cross-validated. The accompanying tests are source-level additions and must not be reported as passing unless executed in a Flutter/Dart environment.

## v67 aerodynamic validation seam
An experimental 2-D RK4 G1/G7 no-wind trajectory integrator now exists in `lib/core/aerodynamic_trajectory_solver.dart`. It solves the low-angle zero numerically and samples requested ranges without enabling production DOPE. `BallisticEngine.solve()` remains fail-closed for G1/G7 until independent reference trajectories are available and matched within an explicit tolerance. Wind is also rejected by the experimental solver until relative-air vector drag is independently validated.

## v68 validation hardening
- Aerodynamic RK4 solver integration step is now explicit and fail-closed outside 0 < dt <= 10 ms.
- Added source-level convergence regression coverage (1.0 ms vs 0.5 ms), BC monotonicity coverage, and invalid-step rejection.
- Production `BallisticEngine.solve()` remains gated: these checks improve numerical confidence but are not a substitute for independent external trajectory cross-validation.

## v69 ballistic audit note
The G1/G7 reference-drag primitive now converts conventional BC units explicitly
from lb/in² to kg/m² (1 lb/in² = 703.0695796391593 kg/m²) before applying the
Cd/Mach reference table. This is algebraically equivalent to the previous
1 lb / 1 inch reference-projectile form, but makes the unit boundary auditable
and regression-testable. Aerodynamic DOPE remains fail-closed in the production
entry point until independent trajectory vectors are available and matched.


## v74 crosswind integration correctness
- Fixed a real defect in the experimental G1/G7 RK4 state derivative: lateral position `z` now integrates `vz` instead of being frozen at zero. Previously crosswind drag could change lateral velocity while reported wind displacement/correction remained falsely zero.
- Added a regression guard requiring a full-value crosswind to produce non-zero lateral correction and greater absolute drift at 100 m than at 50 m. Existing opposite-crosswind sign/symmetry coverage now exercises the corrected position integration path.
- Production `BallisticEngine.solve()` remains fail-closed for G1/G7. Independent reference-vector validation is still required before aerodynamic DOPE is exposed.
- Flutter/Dart/Xcode execution remains unverified in this environment; source tests are present but are not claimed as passed.


## v75 3-D wind-state reporting correctness
- Audited the v74 crosswind fix and found a second vector-state defect: sampled projectile speed used only `vx` and `vy`, even though the experimental wind solver now evolves lateral velocity `vz`.
- Corrected reported aerodynamic velocity/kinetic energy to use the full 3-D ground-speed magnitude `sqrt(vx² + vy² + vz²)`.
- Added a source-level regression guard requiring crosswind trajectory velocity and energy to remain finite and positive.
- Independent reference-vector validation remains the production blocker. The G1/G7 production gate stays closed; no unvalidated aerodynamic DOPE is exposed.
- External review identified Ballistics Lab / py-ballisticcalc as an independent implementation with RK4 engines, G1/G7 drag models, wind support, and Dart bindings suitable for future cross-validation. No numeric equivalence claim is made in this revision.
- Flutter/Dart/Xcode execution remains unavailable here; source tests are not claimed as executed or passed.

## v76 production hardening
- Aerodynamic zero angle is now solved against the standard no-wind zeroing baseline instead of the current shot environment. This prevents headwind/tailwind or weather entered for a shot from silently changing the mechanical sight zero.
- Added a regression test requiring current headwind to affect the trajectory at zero distance rather than being automatically re-zeroed away.
- G1/G7 remains experimental and production-gated pending independent trajectory cross-validation.

## v77 production note
Aerodynamic zeroing now uses an explicit dry standard-atmosphere reference (15 °C, 1013.25 hPa, 0% RH, no wind) instead of the UI-oriented EnvironmentData default (50% RH). Added a regression test preventing current-shot humidity from silently re-zeroing the mechanical sight setting. G1/G7 remains gated from production pending independent trajectory-vector validation.

## v84 independent-validation gate
- Added a pinned, fail-closed external-reference workflow for G1/G7 trajectory cross-validation under `validation/` and `tools/generate_reference_vectors.py`.
- The selected independent implementation is `py-ballisticcalc==2.2.10`; the generator refuses to write fixtures if that exact dependency is unavailable or mismatched.
- No reference vectors are committed yet and the G1/G7 production gate remains closed. In this environment, installation of the independent package was attempted but network/DNS access prevented retrieval, so no equivalence claim is made.
- Acceptance requirements are now documented before comparison results exist, preventing tolerances from being relaxed after seeing failures.

## v86 production validation hardening
- Added `tools/bootstrap_reference_validator.py`: CI now resolves the exact `py-ballisticcalc` release from PyPI metadata, requires the pre-committed universal-wheel SHA-256 from `validation/acceptance.json`, re-hashes the downloaded bytes, and refuses installation on any mismatch.
- iOS CI now attempts to generate the pinned independent G1/G7 reference fixture before Flutter analysis/tests/build and uploads that fixture as a build artifact. A missing dependency, network failure, hash mismatch, generator failure, or empty fixture fails CI rather than being interpreted as validation success.
- This does **not** claim G1/G7 equivalence. The independent fixture still has to be compared with Dart solver output within the frozen tolerances before the production gate can open.

## v101 iOS scaffold gate
The iOS scaffold bootstrap is now centralized in `tools/bootstrap_ios_scaffold.sh`. It requires the pinned Flutter 3.47.2 toolchain, generates `ios/` only when absent, and fail-closes unless the expected Xcode project/workspace, Info.plist, AppDelegate, Flutter xcconfigs, and generated bundle identifier are present. This source environment still cannot generate or build the scaffold because Flutter/Xcode are unavailable here; a real macOS CI run remains required.

## v117 App Store source preflight
- Added `tools/app_store_preflight.py` to make release blockers machine-checkable without pretending that source checks equal an App Store-ready build.
- The check fails closed until a real public HTTPS privacy-policy URL is supplied and a generated iOS scaffold contains the required Xcode/Info.plist/AppDelegate/AppIcon metadata files.
- App Store Connect privacy answers, Xcode privacy report/archive/signing, Simulator and physical-device validation remain required external gates.

## v118 App Store privacy URL preflight hardening
- The release preflight no longer accepts HTTPS URLs merely by string shape: localhost, private/non-global IP addresses, reserved test domains, single-label hosts and credential-bearing URLs are rejected.
- URL reachability is intentionally not claimed by the offline source check; a real hosted privacy policy and App Store Connect/Xcode validation remain release gates.

## v133 iOS scaffold preflight parity
- App Store source preflight now enforces the same generated workspace and Flutter Debug/Release xcconfig files required by the iOS bootstrap contract, preventing a partial `ios/` tree from being misclassified as source-ready.

## v134 protected iOS capability metadata gate
- App Store source preflight now detects common camera, microphone, location, and photo-library references in Dart source and requires the matching non-empty iOS purpose string in generated `Info.plist`.
- This is a fail-closed source guard against release-time permission crashes/review metadata omissions, not a substitute for Xcode privacy reports or App Store Connect privacy declarations.

## v155 catalog source expansion

The bundled optics catalog now includes six DISCOVERYOPT manufacturer-sourced records. v155 adds ED-PRS GEN II 5-25x56, ED-ELR GEN II 5-40x56, LHD 8-32x56 and HD 2-12x24 alongside the existing XED 6-36x56 and HD GEN II 5-30x56 entries. Manufacturer-published optical objective size and physical outer objective diameter are stored separately when both are available. See `V155_CHANGELOG.md` and `tools/test_v155_discoveryopt_catalog.py`.

## v156 catalog provenance rule
Balistik Market may be used to discover Turkish-market scope brands/models, but production technical specifications must come from the manufacturer or its official technical manual/spec sheet. v156 adds eight such manufacturer-backed scope records.

- v160: İzmir Av Market discovery added four manufacturer-verified Sightmark/Vector Optics scope records; retailer data is not treated as manufacturer provenance.


### v161 catalog expansion
The manufacturer-catalog pass now includes 12 additional current Vector Optics riflescopes verified from official product pages. The remaining active manufacturer SKUs stay source-gated: no technical value is guessed from retailer copy.

## v162 test-discovery integrity
All `tools/test_*.py` modules are now required to expose at least one real unittest case. Legacy catalog regression/provenance scripts that relied on module-level or `main()` assertions were converted to `unittest.TestCase`, preventing silent green CI when a test module is invisible to discovery.

- v165: CI now runs offline Python/provenance/production gates before Flutter setup; ordering is regression-tested.
