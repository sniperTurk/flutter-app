# V120

- Profile persistence now fails closed when both primary and backup snapshots are corrupt instead of treating corruption as an empty profile list.
- Saves no longer overwrite both corrupt snapshots with a fresh collection, preserving evidence for recovery/support.
- Added Flutter regression tests for double-corruption read and save behavior.
- Flutter/Dart/iOS runtime verification remains pending because those SDKs are unavailable in this environment.
