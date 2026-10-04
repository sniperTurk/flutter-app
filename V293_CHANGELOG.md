# V293

- `user_catalog_store.dart`: V292 made `all()` return `List.unmodifiable`, but `save()` and `remove()` mutate that list (`removeWhere`/`add`). Every save and remove would have thrown `UnsupportedError`. `all()` now returns the growable validated list.
- Added a Dart regression test that saves two entries and removes one through the store.
- Known limitation: one invalid persisted record makes `all()` throw, so `remove()` cannot delete it either. This is the intended fail-closed behavior; recovery needs a separate repair path.
- No Flutter SDK available here: Dart tests were not run. Python suite and offline Dart lint re-run.
