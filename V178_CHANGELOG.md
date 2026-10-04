# V178

Continues directly from v177; no project restart. No catalog data, ballistics
or app behaviour changed.

## Fixed: iOS integration smoke test could never pass on the Catalog screen

`integration_test/app_launch_test.dart` asserted
`find.text('PCP Mühimmat')` and `find.text('Dürbünler')` with `findsOneWidget`.
`lib/features/catalog/catalog_screen.dart` renders those section headers with a
record-count suffix (`PCP Mühimmat (N)`, `Dürbünler (N)`), and `find.text` is an
exact match, so the macOS/Simulator smoke step would have failed on a healthy
build. Both assertions now use `find.textContaining(...)`.
Found by cross-checking every string/key the integration test expects against
`lib/` (all other strings and both SharedPreferences keys exist in source).

`tools/test_ios_integration_smoke_contract.py` gained
`test_count_suffixed_catalog_headers_use_containing_matchers`, which ties the
integration test to the screen's real header format so this cannot silently
regress before a real Simulator run exists.

## Restored: structural checks in `tools/offline_dart_lint.py`

v167 replaced the v166 lexer with a stray-backslash-only checker. A deleted `}`
or `)`, an unterminated string, or an unterminated block comment therefore
passed the entire offline chain (verified against v177 before this change) and
would only surface in a real `flutter analyze`.

Added `structural_problems(text)` (the v167 API - `stray_backslashes`,
`scan(root)`, `main` - is unchanged) and wired it into `scan()`. It reports:
unclosed / stray / mismatched `{ } [ ] (`, unterminated single-line and
triple-quoted strings, unterminated `${...}` interpolation, and unterminated
(nestable) block comments, with line:col. It understands raw strings, escapes,
`${...}` and `$identifier` interpolation, and ignores delimiters inside strings
and comments. It has no type/symbol knowledge and does not replace
`flutter analyze`.

Tests (`tools/test_offline_dart_lint.py`, +20): legal Dart that must stay clean
(nested comments, raw strings, nested interpolation, triple-quoted strings,
escaped quotes/dollars), each error class with exact line numbers, `scan(root)`
integration, and real-file mutations (delete the last `}` of
`catalog_screen.dart`, delete a closing quote in `catalog_integrity.dart`).

## Verification (executed here)

- `compileall tools`: PASS; `bash -n` on all three shell scripts: PASS.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: **137 tests, OK**
  (v177: 116).
- `verify_production_gate.py`: CLOSED. `offline_dart_lint.py`: 53 files, 0 issues
  (no false positives on the real tree).
- Mutations on temp copies of `lib/`: newline replaced by literal `\n`, deleted
  `)`, deleted closing quote, opened block comment - all four detected.

## Not verified

No Flutter/Dart SDK or network egress here (`github.com` returns 403), so
`flutter analyze`, `flutter test`, the iOS Simulator run (including the
integration-test fix above) and any device/signing/TestFlight step were NOT
run. Run `tools/claude_bootstrap_and_verify.sh` or the `ios-ci.yml` workflow on
a Flutter/macOS host.
