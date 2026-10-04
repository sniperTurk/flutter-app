# V90 production-hardening changes

- CI now syntax-checks both Python reference-validation tools before network/bootstrap work.
- CI formatting gate now covers `tools/` in addition to `lib/` and `test/`, so the Dart reference comparator cannot bypass formatting enforcement.
- CI explicitly documents and statically verifies that `flutter pub get` precedes the Dart reference comparison, because `dart run` depends on generated package configuration.
- Added `.gitignore` rules for Flutter/Dart build state, Python bytecode, generated independent reference vectors, IDE metadata, and OS artifacts.
- Removed generated `tools/__pycache__` bytecode from the source package.

No Flutter/Dart/iOS build or test pass is claimed by this change. The local environment used to prepare V90 did not provide `flutter`, `dart`, or `xcodebuild`.
