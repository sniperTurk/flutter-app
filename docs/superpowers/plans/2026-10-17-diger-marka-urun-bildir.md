# Plan: Diğer marka + "Aradığın mühimmat listede yok mu?" bildirimi (2026-10-17)

Design approved by the owner 2026-10-17 21:26–21:53 (Istanbul). Branch
`feat/diger-marka-urun-bildir`.

1. Port + adapter (TDD): `lib/tools/ports/product_report.dart`
   (`ProductReportSender`, `ProductReportFailure`), pure body builder and
   weight parser `lib/features/profiles/ammo_report.dart`
   (`readWeightGrain`, `ammoReportBody`), adapter
   `lib/tools/adapters/cloudflare_product_report.dart` (HTTPS POST, 10 s,
   201 + `ok:true` = success). Tests: `test/ammo_report_test.dart`.
2. `ToolsServices.productReport` (production: the adapter; tests: a fake in
   `test/support/tool_fakes.dart`).
3. Mühimmat card: "Diğer marka" last in the Marka select (PCP + firearm),
   read-only Model box "Diğer marka model <kalibre>", typed Ağırlık; delete
   the typed-brand list ("Diğer"), typed Marka/Model boxes, firearm weight
   list, "Listeye dön", AMMO_LISTEDE_YOK and the old link behaviour. Old
   typed profiles open in the Diğer marka state with their saved names.
4. Link at the bottom of the card → `_AmmoReportDialog` (exact text, one
   field, Vazgeç | Gönder, success SnackBar / failure notice).
5. ⓘ texts, privacy docs (TR + EN, label), `APP_BUILD_NUMBER` define in the
   TestFlight build for `uygulamaSurumu`.
6. Tests: `test/diger_marka_test.dart` (widgets, JSON, 320 pt × 1.3,
   solver equality), adapt the tests of the deleted flow; sim screens test.
7. Verify: offline lint, Python suite, CI (verify, dart-checks,
   wind-acceptance), test-diag, analyze-diag, sim-screens 390/320.
