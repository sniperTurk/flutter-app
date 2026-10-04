# v117 — App Store release preflight

- Added a fail-closed, offline `tools/app_store_preflight.py` source preflight.
- The preflight validates pubspec version shape, iOS scaffold/release-file presence, app icon metadata presence, and requires an explicit public HTTPS privacy-policy URL rather than inventing one.
- Added regression coverage for valid source state, missing privacy URL, placeholder/non-HTTPS URL, and absent iOS scaffold.
- This does **not** claim App Store readiness: Xcode archive/signing, privacy report, App Store Connect metadata/privacy answers, Simulator and physical-device testing remain external release gates.
