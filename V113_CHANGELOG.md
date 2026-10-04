# V113 Changelog

- Fixed active-profile persistence cleanup after the last saved profile is deleted.
- `HomeScreen._load()` now resolves the persisted active profile id to the actual profile collection, including writing `null` when the collection is empty.
- Added a Flutter widget regression test proving a stale active-profile id is cleared when no profiles remain.
- Flutter/Dart tests were not executed in this environment because the SDK is unavailable; the new test is therefore added but not claimed as passing.
