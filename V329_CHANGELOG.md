# V329 changelog

- Hardened transactional Flutter SDK replacement cleanup for non-directory filesystem entries.
- Added `_remove_path()` so backup/partial cleanup handles directories, regular files and symlinks without following symlinks.
- Fixed a reproduced case where an unexpected pre-existing file at the SDK destination caused a successful replacement to be reported as failed and left a stale backup behind.
- Added regression coverage for file backup cleanup and symlink-safe removal.
- Real Flutter/Xcode/iOS execution remains unverified in this environment.
