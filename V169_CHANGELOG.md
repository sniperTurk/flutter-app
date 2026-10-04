# V169 — scope adjustment-range provenance hardening

- Continued directly from v168; no project reset.
- Fixed a provenance semantics gap in `ScopeOptic`: manufacturer values published as strict lower bounds (for example `>17.5 MIL`) can now be represented without silently flattening them into exact values.
- Marked Vector Optics SCFF-66 elevation/windage and the existing SCFF-68 `>30 MIL` ranges as lower bounds.
- Added direct regression coverage for the new semantics and extended the v168 SCFF-66 provenance lock.
- No Flutter/Xcode/Simulator/device result is claimed by this changelog. Those gates require the pinned Flutter/macOS environment.
