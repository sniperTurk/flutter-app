# V98 change log

## Production progress

- Expanded the iOS integration smoke test from a first-frame launch check into a
  production route smoke test.
- The test still enters through `main()`, preserving catalog startup validation
  and real persistent-store/plugin wiring.
- It now opens the Catalog route on a clean install and verifies the PCP rifle,
  PCP ammunition, and optics surfaces before returning home.
- It then opens Settings, exercising SharedPreferences-backed settings startup,
  returns home, and checks for uncaught Flutter exceptions after each route.
- Ballistics remains intentionally excluded from this clean-install smoke test:
  production correctly gates that route until a valid active profile exists.

## Verification boundary

This environment does not provide Flutter/Dart/Xcode. The updated integration
smoke test is source-reviewed here but is not reported as passing until it runs
successfully on the macOS/iOS CI runner.
