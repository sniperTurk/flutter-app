# V131 Changelog

- Replaced the duplicated inline MRAD→MOA wind-display constant in `ballistics_screen.dart` with the canonical `Units.mradToMoa()` helper.
- Added the explicit `core/units.dart` import.
- Added a regression test that prevents reintroducing the duplicated conversion constant and wired it into iOS CI.
- This is a maintainability/consistency fix; it intentionally does not change the ballistic result.
- No Flutter/Dart/Xcode build or runtime result is claimed in this environment.
