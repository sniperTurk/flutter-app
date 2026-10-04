# V133 CHANGELOG

- Closed a source-release contract gap between `bootstrap_ios_scaffold.sh` and `app_store_preflight.py`: preflight now also requires the generated Xcode workspace plus Flutter Debug/Release xcconfig files.
- Added fail-closed regression coverage proving a partial `ios/` tree cannot pass source preflight when `Runner.xcworkspace/contents.xcworkspacedata`, `Flutter/Debug.xcconfig`, or `Flutter/Release.xcconfig` is absent.
- No Flutter/Dart/Xcode execution is claimed in this environment. Resolver-generated `pubspec.lock`, a real public privacy-policy URL, generated iOS scaffold, and real build/Simulator/device validation remain open external gates.
