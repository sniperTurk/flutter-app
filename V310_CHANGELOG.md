# V310 — iOS CI signing configuration wiring

- Wires the owner-controlled GitHub Actions repository variable `IOS_DEVELOPMENT_TEAM` into the existing v309 deterministic iOS scaffold/signing configuration via `SNIPER_TURK_IOS_DEVELOPMENT_TEAM`.
- Keeps the value optional: absence does not invent a Team ID and does not claim a signed build.
- Invalid configured Team IDs continue to fail closed in `configure_ios_signing.py`.
- Adds regression coverage proving CI and bootstrap use the same signing environment contract.
- This does not provide Apple certificates/provisioning credentials and therefore does not turn the current unsigned archive gate into a verified signed App Store archive.
