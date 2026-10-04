# v271 — V1 scope reduction

- Removed Chronograph and Sight Height navigation cards and screen imports.
- Removed their feature screens, audio/photo adapters, unused iOS microphone bridge and bridge installer.
- Removed image_picker and path_provider dependencies, which were used only by the removed feature.
- Removed microphone, camera and photo library permission descriptions from generated iOS Info.plist.
- Retained ballistic sightHeightMm as a manually entered physical parameter; removing the camera-based measurement feature must not silently alter trajectory calculations.
- Legacy measurement model/store/codec and historical tests remain as compatibility/data migration support, but are no longer reachable from the app UI.
- Flutter SDK and pinned dependency resolution are required before release; pubspec.lock and provenance are still absent.
- Archived historical Python and Dart tests that exclusively target retired screens/adapters. They are retained under archived_tests/removed_v1_features, not counted as current V1 tests.
- Added four current-scope regressions covering home navigation, dependencies/native bridge, iOS permissions and the retained manual ballistic sight-height parameter.
