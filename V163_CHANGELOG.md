# V163 changelog

- Fixed a production-blocking source corruption introduced in v161: literal `\\n` escape sequences embedded between Dart catalog declarations were replaced with real newlines.
- Added `tools/test_dart_source_no_literal_newline_escape.py` so the same source corruption fails the unittest discovery suite.
- No catalog records were removed or rewritten; v162 provenance/discovery fixes remain intact.

- Full unittest discovery after the fix: 76/76 PASS.
- `tools/offline_dart_lint.py` is not present in the v162 source package, so no lint PASS is claimed for it.
