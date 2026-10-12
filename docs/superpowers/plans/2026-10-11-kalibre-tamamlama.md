# Kalibre Tamamlama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kalibre listesine eksik kalibreleri eklemek ve her kalibreye standart ölçüleri (C.I.P./SAAMI/üretici, kaynak URL'li) bağlamak.

**Architecture:** Veri `data/kalibre-tamamlama` dalında `data/calibers/cartridge_specs.json` olarak durur (diğer data/* dalları gibi `tools/data_gen/calibers` worktree'sinden okunur). `generate_profile_lists.py` bu dosyadan yeni kalibreleri `CARTRIDGES`/`PCP`'ye ekler ve `lib/data/cartridge_specs.dart` üretir. UI değişmez.

**Tech Stack:** Python 3 üretici, Dart sabit listeleri, flutter_test.

**Spec:** Sahibin 2026-10-11 görev metni (kalibre tamamlama).

## Global Constraints

- Mevcut kalibre adları ve çapları değiştirilmez; yalnızca ekleme.
- Kaynak: yalnızca C.I.P., SAAMI, üretici resmî sayfası. Bulunamayan değer `null` + not.
- Paralel dallarla çakışmamak için `test/profile_lists_test.dart` ve üreticinin fişek/BC bölümleri değiştirilmez.

## Review Focus

- Yeni kalibre adı mevcut alias'larla çakışmamalı (ör. `8x57 JR` ≠ `8x57 JRS`).
- PCP 11.60 mm, 11.43 mm ile karışmamalı (tolerans 0,06 mm).
- Ölçü kaydı olmayan kalibre (NATO, wildcat) uygulamayı bozmamalı: `CartridgeSpecs.of` null döndürebilir.
- `L3 < L6`, Pmax 500–6000 bar, yiv 1:4–1:30 aralıkları testte kilitli.
- Çekirdek ağırlık aralığı fabrika fişeğinden türetiliyorsa kaynağı belirtilmeli.

---

### Task 1: Veri dalı
- [x] C.I.P. listesi + föyler, SAAMI rimfire, üretici sayfaları → `cartridge_specs.json`, `README.md`.

### Task 2: Üretici + Dart
**Files:** Modify `tools/data_gen/generate_profile_lists.py`; Create `lib/data/cartridge_specs.dart` (generated), `test/cartridge_specs_test.dart`.
- [x] Test: her `Cartridges.firearm` adı ve her PCP etiketi `CartridgeSpecs.all`'da; kaynaklar `https://`; aralıklar; `10.3x60 R` tüfeği, `8x57 JR` fişeği, PCP 11.6 var.
- [x] Üreticiyi çalıştır; `skipped` listesinde 8x57 JR / 10.3x60 R / 11.60 mm kalmamalı.
- [ ] `python3 tools/offline_dart_lint.py`, `python3 -m unittest discover -s tools -p 'test_*.py'`, CI test-diag/analyze-diag.
