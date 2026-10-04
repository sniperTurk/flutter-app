# V195 — Turkish catalog search hardening

## Production change
- Added dependency-free `CatalogSearch` normalization for Turkish catalog UX.
- Turkish characters (ç, ğ, ı/İ, ö, ş, ü) now fold to ASCII equivalents for search only; canonical catalog/display data is unchanged.
- Multi-term catalog queries are order-independent, so `6.35 hatsan` can match `HATSAN ... 6.35`.
- CatalogScreen now uses the shared search contract for rifle, ammunition and scope filtering.

## Regression protection
- Added Dart tests for Turkish/ASCII matching, order-independent terms and empty queries.
- Added 4 executable offline contract tests protecting the wiring and normalization behavior.

## Verification performed in this environment
- Python offline suite: 206/206 PASS.
- Python compileall: PASS.
- Offline Dart lint: PASS (real Dart formatter/analyzer was not available).
- G1/G7 production gate: CLOSED/PASS.
- Shell syntax: PASS.
- GitHub Actions YAML parse: PASS.

## Still not verified here
Real `dart format`, `flutter analyze`, `flutter test`, iOS build, Simulator, physical iPhone, xcarchive/IPA and App Store submission remain NOT RUN. No success is claimed for those gates.
