# V99 changelog

- Hardened the iOS Simulator production gate so CI now installs and launches the exact `Runner.app` produced by `flutter build ios --simulator --debug` before running the Flutter integration smoke test.
- The workflow derives `CFBundleIdentifier` from the built app's `Info.plist` instead of assuming a bundle identifier.
- CI now fails closed when the built `.app` is missing, has no bundle identifier, cannot be installed/launched with `simctl`, or does not return a launch PID.
- The existing source-level integration smoke test remains as a second layer for route navigation and persistence/plugin wiring.
- This change is CI/test infrastructure only; no unexecuted iOS result is claimed as passing.
