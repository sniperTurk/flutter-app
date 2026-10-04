# SNIPER TÜRK V1 — v139

## Production work completed

- Fixed a catalog provenance UI defect: an unsourced rifle record with no detailed metadata was previously shown as “Doğrulanmış ayrıntılı teknik veri henüz yok.” even though no manufacturer/source provenance existed.
- Unsourced rifle records now explicitly render “Kaynak doğrulanmadı • Ayrıntılı teknik veri henüz yok.”; verified records continue to show their actual source name.
- Added `tools/test_catalog_provenance_ui.py` and wired it into iOS CI so the misleading verified wording cannot silently return.

## Verification in this environment

- Offline Python regression suite: 40/40 PASS.
- Python compile for verification tools: PASS.
- GitHub Actions YAML parse: PASS.
- `bootstrap_ios_scaffold.sh` syntax: PASS.
- G1/G7 production gate: CLOSED/PASS.
- Real Flutter/Dart/Xcode execution: NOT AVAILABLE in this environment and is not claimed as successful.
