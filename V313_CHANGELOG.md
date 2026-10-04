# V313 — Signed App Store IPA export gate

- Added `tools/export_signed_app_store_ipa.sh` for the owner-controlled macOS/Xcode release environment.
- The gate consumes only the validated deliberately-unsigned xcarchive, requires a real Apple Team ID, generates deterministic App Store export options, and invokes `xcodebuild -exportArchive`.
- Success is not inferred from xcodebuild alone: the exported IPA is unpacked, its app is verified with `codesign --verify --deep --strict`, and an embedded provisioning profile is required.
- No certificate, Team ID, provisioning profile, IPA, Simulator result, or physical-iPhone result is fabricated by source-only CI.
- Added v313 regression coverage for the fail-closed release contract.
