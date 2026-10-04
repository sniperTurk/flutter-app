# V136 changelog

## App Store preflight is now enforced by iOS CI

- Fixed a release-gate wiring gap: `tools/app_store_preflight.py` existed and was unit-tested but the iOS CI workflow never executed it against the real repository after generating the iOS scaffold.
- CI now runs the fail-closed App Store source preflight after `bootstrap_ios_scaffold.sh` and before any iOS build.
- The real privacy-policy URL must be supplied through the GitHub Actions repository variable `PRIVACY_POLICY_URL`; an unset/empty value remains a deliberate release blocker.
- Added an offline regression test that locks the ordering and variable wiring so the preflight cannot silently disappear from CI.
- This does not claim an iOS build, Simulator/device test, signing, archive, or App Store validation succeeded in this environment.
