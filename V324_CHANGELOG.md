# V324

- `export_signed_app_store_ipa.sh`: `ROOT` used logical `pwd` while archive/export paths are compared after `realpath`. A checkout under a symlinked parent (e.g. a symlinked home or /tmp) made every legitimate archive fail the v323 safety check. `ROOT` now uses `pwd -P`.
- The export directory is now rejected when it equals or lies inside `build/ios/archive`, or contains the archive. Before, `build/ios/archive` passed the "below build/ios" check and `rm -rf` would delete the archive being exported.
- Added a regression test for the overlap case.
- Removed the stray empty `build/ios/archive` directories from the zip (`build/` is gitignored).
- No Xcode/macOS here: the script was only exercised with stubbed tools.
