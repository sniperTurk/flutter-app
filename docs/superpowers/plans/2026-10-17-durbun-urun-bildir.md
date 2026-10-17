# Plan: Dürbün ürün bildirimi (feat/durbun-urun-bildir)

Owner decisions 2026-10-17 22:09–22:15 (Istanbul). Requirements settled in the task; no UI change.

Goal: when a profile with a typed scope is saved, send its technical values once
(fire-and-forget) to the Cloudflare product box; remember a hash per profile so an
unchanged scope is not resent; store the returned id locally.

## Tasks (TDD: test first, then code)
1. Port `lib/tools/ports/product_report_service.dart` (`ProductReportService`,
   `ProductReport`, `ProductReportKind {tufek, muhimmat, durbun}`, `ProductReportFailure`).
   Shared with the ammunition task (same worker): kind decides `tur`.
2. Adapter `lib/tools/adapters/cloudflare_product_report_service.dart`: HTTPS POST
   `/urun`, JSON body, 10 s timeout, parses `{"ok":true,"id":…}`; any other outcome
   throws `ProductReportFailure`. Test with `http/testing.dart` MockClient (no real network).
3. `lib/services/product_report_ledger.dart`: hash (FNV-1a 32 of canonical JSON) per
   profile id + list of `{id, tur, createdAt}` in SharedPreferences; `reportOnce`
   never throws, skips unchanged, in-flight guard.
4. `ToolsServices.productReports` (optional). Production wiring only when the build
   carries `SNIPER_TURK_APP_VERSION` (set only by ios-testflight.yml), so tests,
   simulator and CI builds never call the real worker.
5. Profile editor `_save`: after the records are written and before `Navigator.pop`,
   if the scope is typed (`_scopeTyped`), build `alanlar` from the entered values
   (empty omitted, numbers as numbers) and call the ledger unawaited.
   Reporter read with `getInheritedWidgetOfExactType` (no production fallback).
6. Widget tests `test/durbun_urun_bildir_test.dart` with a fake service.
7. Privacy docs 02 + 03 (TR + EN).
8. Report `docs/reports/durbun_urun_bildir.md`; local lint + python suite; CI.
