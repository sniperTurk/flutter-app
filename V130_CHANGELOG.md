# V130 — iOS CI source-hygiene blocker fix

- Removed the zero-byte `test/home_active_profile_test.dart.tmp` artifact that v129 accidentally shipped.
- Fixed the iOS CI source-hygiene gate so it checks Git-tracked source with `git ls-files` instead of the mutable worktree.
- This prevents the earlier Python `py_compile` validation step from creating `__pycache__` files that would make the later hygiene gate fail every CI run.
- Added `tools/test_ci_source_hygiene.py` to verify both the tracked-source CI contract and release-tree cleanliness.
- No Flutter/iOS build success is claimed in this environment; Flutter/Dart/Xcode execution remains externally required.
