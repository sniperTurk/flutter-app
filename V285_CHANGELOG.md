# V285

- `ballistics_screen.dart`: removed an unnecessary `!` on a non-nullable `double` (`turretCorrection`). The analyzer reports this as `unnecessary_non_null_assertion`, which fails `flutter analyze --fatal-warnings`.
- `profiles_screen.dart`: swipe-to-delete called `removeWhere` on a list returned by `PersistentProfileStore.all()`, which is `List.unmodifiable`. After the store removal succeeded, `onDismissed` threw `UnsupportedError`. The list is now replaced with a filtered copy.
- `manual_catalog_dialog.dart`: for the firearm platform the dialog showed `bullet` but kept the default `pellet`, so `UserCatalogStore.validate` rejected the entry. The default now follows the platform and the saved value is forced to `bullet` for firearms.
- Python tool suite and offline Dart lint re-run (see status below). No claim of Flutter analyze/test, iOS build, Simulator or device validation: no Flutter/Dart SDK was available.
