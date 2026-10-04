# SNIPER TÜRK V1 — v146

## Production change
- Replaced the hand-maintained Python unittest module list in iOS CI with `unittest discover -s tools -p 'test_*.py'`.
- This closes a release-gate gap where a newly added offline regression test could exist in the source archive but never run on the real macOS CI because its filename was not manually appended to the workflow.
- Added a regression guard that requires discovery-based CI wiring and rejects reintroduction of the old manual unittest list.

## Verification performed in this environment
- Complete offline Python regression suite executed via the exact discovery command now used by CI.
- Python verification tools compiled locally.
- GitHub Actions YAML parsed locally.
- iOS bootstrap shell syntax checked locally.
- G1/G7 production gate checked locally.
- App Store source preflight remains blocked by real unresolved prerequisites: resolver-generated `pubspec.lock`, a real public privacy-policy URL, and the generated iOS scaffold.
- No real hosted macOS CI, Flutter/Xcode build, Simulator/device run, signing, TestFlight, or App Store upload is claimed.
