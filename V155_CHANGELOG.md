# V155 — DISCOVERYOPT official catalog expansion

- Continued from v154; no project restart/regeneration.
- Added four manufacturer-sourced DISCOVERYOPT FFP optics from discoveryopt.com official product pages:
  - ED-PRS GEN II 5-25x56 FFP-Z MRAD
  - ED-ELR GEN II 5-40x56 FFP-Z MRAD
  - LHD 8-32x56 FFP-Z MRAD
  - HD 2-12x24 FFP MIL
- Preserved existing XED 6-36x56 and HD GEN II 5-30x56 records; no duplicate aliases were created.
- Stored only fields represented by the current ScopeOptic schema: optical/outer objective diameter where unambiguous, tube, magnification, click, MRAD ranges, dimensions, FFP/zero-stop and provenance.
- Added `tools/test_v155_discoveryopt_catalog.py` to lock IDs, core manufacturer specs and provenance.
- Real Flutter/Xcode validation remains unclaimed when unavailable.
