# SNIPER TÜRK V1 — v147

## Production change
- Added a live App Store privacy-policy availability gate instead of treating a syntactically valid HTTPS URL as sufficient release evidence.
- CI now requires the configured privacy page to return HTTP 200 over HTTPS (including redirects), provide HTML/plain-text content, contain substantive text, and include a recognizable privacy-policy term before any iOS build starts.
- Added offline regression coverage for reachable policy pages, dead URLs, HTTPS downgrade redirects, wrong content types, and placeholder/empty content.
- Extended CI ordering regression coverage so the live privacy check cannot silently move after the iOS build.

## Verification performed in this environment
- Complete offline Python regression suite executed with CI's discovery command.
- GitHub Actions YAML parsed locally and bootstrap shell syntax checked locally.
- App Store source preflight remains blocked by the unresolved real prerequisites: resolver-generated `pubspec.lock`, a real configured public privacy-policy URL, and the pinned-Flutter-generated iOS scaffold.
- The new live URL gate was tested with deterministic mocked HTTP responses; no real project privacy URL exists yet, so no live project policy page is claimed verified.
- No hosted macOS CI, Flutter/Xcode build, Simulator/device run, signing, TestFlight, or App Store upload is claimed.
