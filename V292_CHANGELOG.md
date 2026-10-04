# V292

- Hardened `UserCatalogStore.all()` against malformed persisted user-catalog records.
- Non-map list members now fail closed with a controlled `FormatException` instead of an unchecked cast `TypeError`.
- Persisted records are revalidated on read, preventing invalid platform/ammunition/scope combinations from reaching UI/domain conversion code.
- Added Dart regression coverage for malformed record shape and invalid persisted firearm ammunition type.
- Real Flutter tests remain pending until a Flutter SDK and resolver-produced lockfile are available.
