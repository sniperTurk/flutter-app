# V295

- `catalog_screen.dart`: the manual ammunition-type dropdown (V294) used `initialValue` with an item list that changes with the platform. `initialValue` is not a live binding, so switching PCP -> firearm could leave the field holding `pellet` while the only item was `bullet`, which trips the DropdownButton "exactly one item with value" assertion. Added `key: ValueKey('ammo-type-$selectedPlatform')` so the field is recreated when the platform changes.
- Added a source regression assertion for the key.
- No Flutter SDK here: Dart code not analyzed or run.
