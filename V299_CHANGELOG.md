# V299

- Replaced remaining deprecated `DropdownButtonFormField(value:)` uses in active Dart UI with `initialValue:`.
- Preserved the platform-keyed ammunition dropdown rebuild (`ValueKey`) so switching PCP/firearm cannot retain an invalid selection.
- Added `tools/test_v299_no_deprecated_dropdown_value.py` to prevent the deprecated form-field API from returning.
- No catalog data or persistence schema changes.
