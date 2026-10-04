# SNIPER TÜRK V1 — v145

## Production change
- Updated GitHub-hosted JavaScript actions in iOS CI away from Node 20-era majors that are no longer safe to rely on after GitHub's 2026 runner cutoff: checkout v4 → v6, setup-python v5 → v7, upload-artifact v4 → v7.
- Added an offline regression guard that rejects reintroduction of the deprecated official action majors.
- Kept `subosito/flutter-action@v2` unchanged; this change is scoped to the affected official JavaScript actions and does not claim a real hosted CI run.

## Verification performed in this environment
- Offline Python regression suite executed locally.
- Python verification tools compiled locally.
- GitHub Actions YAML parsed locally.
- iOS bootstrap shell syntax checked locally.
- G1/G7 production gate checked locally.
- App Store source preflight remains blocked by the real unresolved release prerequisites (resolver-generated pubspec.lock, real public privacy-policy URL, generated iOS scaffold).
- No real GitHub-hosted macOS CI, Flutter build, Xcode build, Simulator/device test, signing, TestFlight, or App Store upload is claimed.
