# V314 — Signed IPA identity/profile verification

- Added `tools/verify_signed_app_store_ipa.py`, a fail-closed macOS verifier for an exported App Store IPA.
- Verification now binds the exact production bundle identifier to the explicit Apple Team ID in both code-signing entitlements and the embedded provisioning profile.
- The signed export gate invokes this verifier before emitting its PASS marker.
- No Apple identity, credential, certificate, provisioning profile, build, Simulator run, or physical-device result is fabricated.
