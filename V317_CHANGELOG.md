# V317 — iOS bootstrap rerun regression proof

- Added an end-to-end regression fixture for the v316 signing/bootstrap idempotency fix.
- The test runs `bootstrap_ios_scaffold.sh` twice with the same explicit `SNIPER_TURK_IOS_DEVELOPMENT_TEAM`.
- A fake pinned Flutter/Ruby environment generates the minimum iOS scaffold contract, allowing the real bootstrap guard, Info.plist configurator, signing configurator, transaction logic, and post-generation checks to execute together.
- The second run must succeed instead of returning the historical manual-customization `exit 10`, and the regenerated project must still contain the expected Team ID in every Automatic signing build setting.
- No real Flutter/Xcode build, Simulator run, device test, or Apple signing operation is claimed by this fixture.
