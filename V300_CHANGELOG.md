# V300

- V299 moved `DropdownButtonFormField` from `value:` to `initialValue:`. `initialValue` is read only when the field state is created, so dropdowns whose selection or item list is changed programmatically kept a stale value.
- `profiles_screen.dart`: switching PCP/firearm replaces the rifle list (and resets rifle/ammo), but the rifle and ammunition fields kept the old selection, which is no longer among the items (DropdownButton "exactly one item" assertion). Added `ValueKey`s derived from platform (rifle) and rifle id (ammunition) so the fields are recreated.
- `home_screen.dart`: keyed the active-profile dropdown by the active profile id.
- Added regression assertions for the keys.
- No Flutter SDK here: Dart code not analyzed or run.
