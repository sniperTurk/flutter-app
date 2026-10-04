# SNIPER TÜRK V1 — v140

## Production work completed

- Hardened the unsigned App Store archive gate so CI now validates the metadata embedded in the built `Runner.app`, not only the archive bundle identifier.
- The archive must contain marketing version `1.0.0`, build number `1`, display name `SNIPER TÜRK`, and `ITSAppUsesNonExemptEncryption=false`; any mismatch fails the release chain before an artifact can be treated as App Store-ready.
- Added `tools/test_ios_ci_archive_metadata_wiring.py` and wired it into the offline/CI regression suite so these archive checks cannot silently disappear.

## Verification in this environment

- Offline Python regression suite: PASS (real count reported by run output).
- Python compile for verification tools: PASS.
- GitHub Actions YAML parse: checked locally with available YAML parser.
- `bootstrap_ios_scaffold.sh` syntax: PASS.
- G1/G7 production gate: CLOSED/PASS.
- Real Flutter/Dart/Xcode execution: NOT AVAILABLE in this environment and is not claimed as successful.
