# V290

- Hardened App Store iOS scaffold preflight against symlinked intermediate directories.
- Required release files are now rejected when any path component under `ios/` is a symbolic link, not only when the leaf file itself is a symlink.
- Preflight avoids parsing `project.pbxproj` / `Info.plist` through an unsafe symlinked path.
- Added regression coverage for symlinked `Runner.xcodeproj`, `Runner.xcworkspace`, `Runner`, and `Flutter` directories.
- Offline verification: 349/349 Python tests pass; offline Dart lint 58/58; Python compileall passes.
- Real Flutter/Xcode/Simulator/device validation remains unverified.
