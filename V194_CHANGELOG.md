# V194 — DOPE range guardrail consistency

- Continued directly from V193; no project restart.
- Fixed a real production inconsistency: `DopeRanges.parse()` hard-coded 2000 m while the canonical `ProductionLimits.maxRangeM` and `BallisticInput` allow 3000 m.
- `DopeRanges` now defaults to the single canonical 3000 m production limit.
- Fixed imperial DOPE entry validation: the UI now converts the canonical 3000 m ceiling to yards before validating values displayed in yards, then converts accepted ranges back to metres for the solver.
- Updated the Dart boundary regression to accept 2500 m and 3000 m and reject 3000.1 m.
- Added three offline source-contract regressions so the parser/UI cannot silently drift back to mismatched metric/imperial limits.
- Offline suite: 202/202 PASS. Offline Dart lint: 53 files / 0 issues. Production G1/G7 gate: CLOSED. Shell syntax and both workflow YAML files: PASS.
- Flutter/Dart SDK, Xcode, Simulator, xcarchive and physical-iPhone execution remain NOT RUN / NOT VERIFIED in this Linux environment.
