# V330 changelog

- Fixed test-only workspace pollution in `tools/test_v323_signed_export_archive_path_safety.py`.
- The signed-export archive safety tests now remove only the empty `build/ios/archive` parent chain they may create.
- Cleanup is deliberately fail-safe: non-empty directories and existing build artifacts are preserved.
- No production `lib/` code changed.
