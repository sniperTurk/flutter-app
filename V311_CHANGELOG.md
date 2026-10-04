# V311 — deterministic App Store export-options contract

- Adds `tools/generate_ios_export_options.py` to generate a deterministic, team-bound `ExportOptions.plist` for App Store Connect export.
- Fails closed unless the owner-supplied Apple Team ID is exactly 10 uppercase alphanumeric characters; no Team ID is invented or committed.
- Uses App Store Connect distribution, automatic signing, fixed build/version preservation, Swift symbol stripping, and symbol upload settings.
- Wires generation into iOS CI only when `IOS_DEVELOPMENT_TEAM` is actually configured.
- Adds regression coverage for payload semantics, invalid Team IDs, parseable atomic output, and CI wiring.
- This does **not** install Apple certificates/profiles, sign/export an IPA, upload to App Store Connect, or count as a verified iOS build/device test.
