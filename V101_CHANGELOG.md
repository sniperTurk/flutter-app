# V101

- Added `tools/bootstrap_ios_scaffold.sh` as the single fail-closed iOS scaffold bootstrap contract.
- The script refuses to generate platform files unless Flutter is exactly 3.47.2, matching `.fvmrc` and CI.
- It generates iOS only when absent, then verifies the Xcode project, workspace, Info.plist, AppDelegate and Flutter xcconfig files.
- It verifies the expected generated bundle identifier before allowing CI to continue.
- CI now calls this checked script instead of embedding an unchecked `flutter create` block.
- No claim is made that the scaffold was generated locally or that an iOS build passed; Flutter/Xcode are unavailable in this environment.
