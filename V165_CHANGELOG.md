# V165 — CI early offline production gates

- Reordered `.github/workflows/ios-ci.yml` so Python compile, full `unittest discover`, and the closed G1/G7 production gate run before Flutter setup/download.
- This keeps catalog provenance/discovery regressions observable even when Flutter bootstrap or network-dependent setup fails.
- Added a wiring regression test that locks the required ordering.
- No application/catalog/ballistic behavior changed in this revision.
