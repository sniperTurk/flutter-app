# V315 — App Store distribution-profile gate

- Continued from v314 without restarting the project.
- Hardened `verify_signed_app_store_ipa.py` so a merely valid signed IPA cannot be mistaken for an App Store deliverable.
- The signed IPA gate now rejects expired provisioning profiles, device-bound/ad-hoc profiles (`ProvisionedDevices`), enterprise profiles (`ProvisionsAllDevices`), and any signature/profile with debugging enabled (`get-task-allow != false`).
- Added three regression contract tests in `tools/test_v315_app_store_distribution_profile_gate.py`.
- No real signed IPA, Xcode build, Simulator run, or physical-iPhone run is claimed by this source-only change.
