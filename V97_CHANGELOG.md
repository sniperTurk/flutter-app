# V97 change log

## Production progress

- Added a real `integration_test` dependency and `integration_test/app_launch_test.dart`.
- The smoke test enters through `main()` so the bundled-catalog startup guard and
  production persistent-store/plugin wiring are exercised instead of bypassed.
- Extended iOS CI to select and boot an available iOS Simulator, wait for boot,
  enumerate Flutter devices, and execute the launch smoke test on that simulator.
- Included `integration_test` in the CI Dart formatting gate.

## Verification boundary

This environment does not provide Flutter/Dart/Xcode, so the new integration test
and iOS Simulator step have not been executed here. They must not be reported as
passing until the macOS CI runner completes them successfully.
