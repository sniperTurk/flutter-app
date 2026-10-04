# V333 Changelog

## PyPI validator bootstrap redirect hardening

- Hardened `tools/bootstrap_reference_validator.py` so both PyPI metadata and wheel downloads use an HTTPS opener whose redirect handler rejects any redirect outside the explicitly trusted `pypi.org` / `files.pythonhosted.org` hosts.
- Initial URLs are validated with the same trusted-origin policy before any network request.
- This closes a gap where the initial wheel URL was host-checked but urllib could automatically follow a later redirect to an untrusted host. Wheel SHA-256 verification remains mandatory.
- Added two offline regression tests proving trusted HTTPS redirects are accepted and untrusted redirect hosts are rejected.

## Verification

- Python: 434/434 tests PASS.
- Offline Dart lint: 59 files, 0 issues.
- Python compileall: PASS.
- Shell syntax (`bash -n`): PASS.
- G1/G7 production gate: CLOSED, as required.
- `offline_solver_crosscheck.py`: PASS, equations-only; not an external acceptance run.
- External py-ballisticcalc bootstrap was attempted but DNS/network access is unavailable in this environment, so no reference fixture was generated and no production gate was opened.
- Flutter SDK/Xcode are unavailable here; `flutter analyze`, `flutter test`, real iOS build, Simulator, and physical-device tests remain unverified.
