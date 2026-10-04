# V346

- `test_v345_vacuum_click_suppression.py` read `lib/...` relative to the current directory and without an encoding, so it failed (FileNotFoundError) whenever the suite was started from any directory other than the repository root, and would decode the Turkish source with the locale encoding on some systems. It now resolves the path from `__file__` and reads UTF-8, like the other contract tests.
- Reviewed the V345 UI change (Klik column and click computation removed from the vacuum table): no unused variables/imports left behind, no Dart test references the column. Dart code was not run: no Flutter SDK here.
