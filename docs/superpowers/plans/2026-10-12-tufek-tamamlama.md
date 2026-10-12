# Tüfek tamamlama Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (owner supplied). Steps use checkbox (`- [ ]`) syntax.

**Goal:** RifleLibrary'de (Profil Marka/Model/Kalibre listesi) eksik PCP ve ateşli tüfek üreticilerini/modellerini yalnızca üretici kaynaklarıyla eklemek.

**Architecture:** Kaynak veri `data/rifles` dalındaki `data/rifles/<marka>.json` dosyaları (yeni dal `data/tufek-tamamlama`). `tools/data_gen/generate_profile_lists.py` (main) bu JSON'ları okuyup `lib/data/rifle_library.dart`'ı üretir. Yerli markalar `profiles_screen.dart` `_domesticBrands` kümesinde (feat/tufek-tamamlama).

**Tech Stack:** Python 3 generator, Dart/Flutter app, GitHub Actions diag workflow'ları.

**Spec:** Sahibin 2026-10-12 zamanlanmış görev talimatı (PR açıklamasında özetlenir) + CLAUDE.md.

## Global Constraints
- Kaynak: yalnız üreticinin resmi sitesi/kataloğu/kılavuzu (veya üreticinin resmi ülke iştiraki — önceki turlarla aynı). Forum, blog, bayi, mağaza YOK. ChairGun/Strelok/AB/QuickLOAD/GRT/JBM YOK.
- Bulunamayan alan `null`; notes'ta "resmi kaynakta belirtilmemiş". Uydurma yok.
- Her kayıt `source_url` taşır; tur özeti NOTES.md'ye.
- Şema: brand, model, platform(pcp|firearm), caliber, bullet_diameter_mm, barrel_length_mm, twist_rate_in, twist_direction, magazine_capacity, weight_kg, overall_length_mm, regulator_bar, air_capacity_cc, energy_j, velocity_fps, (fill_pressure_bar), source_url, notes.
- Kalibre adı generator'ın `cartridge()` / `pcp_mm()` eşlemesinden geçmeli; geçmeyen kalibre mevcut desenle (CARTRIDGES.update + çap) eklenir.
- Mevcut kayıtlar silinmez/değiştirilmez (yalnız ekleme). MERGE YOK. PR'lar REST API ile.

## Review Focus
1. Model adında kalibre eki — generator `base_model` kalibreyi kesemezse modeller ikiye bölünür (ör. "Impact M3 .22" vs "Impact M3"). Kontrol: üretim sonrası marka başına model listesi gözle.
2. PCP kalibre ".30"/".35"/".357" çap eşlemesi — 7.62 / 9.0 mm'e düşmeli; düşmeyen kayıt stderr skipped listesinde görünür → sıfır yeni skipped hedefi.
3. Aynı marka iki yazımla ("FX" vs "FX Airguns") — marka adları tekil.
4. Yerli marka `_domesticBrands`'a eklenmezse "Yerli" filtresinde görünmez.
5. Hatve mm→inç dönüşümü (mm/25.4) ve "1:x" yönü yanlış alanlara yazılması.

---

### Task 1: Envanter ve marka listesi
- [x] Mevcut 76 marka dosyası sayıldı; boş dosyalar: airmaks, akdas, ataman, cometa, edgun, fx-airguns, huben, niksan, snowpeak.
- [x] Baseline generator: rifles 4064 (firearm 3698, pcp 366), skipped 17 (değişiklik yok, deterministik).

### Task 2: Araştırma (paralel alt ajanlar, marka grupları)
- [ ] Her grup `scratchpad/out/<marka>.json` + `<marka>.md` (kaynaklar, bulunamayanlar) üretir.

### Task 3: Birleştirme
- [ ] JSON doğrulama scripti: zorunlu alanlar, https kaynak, yasak alan adları (forum/bayi) yok, mevcut kayıtla çakışma yok.
- [ ] `data/rifles/*.json`'a ekle, NOTES.md bölümü; commit (data/tufek-tamamlama).

### Task 4: Üretim ve uygulama
- [ ] Generator → yeni skipped = 0; gerekli kalibre/alias eklemeleri; `_domesticBrands` güncelle; test eşiklerini kontrol et.
- [ ] `python3 tools/offline_dart_lint.py`, `python3 -m unittest discover -s tools -p 'test_*.py'`.
- [ ] Push; CI diag (test-diag, analyze-diag; format gerekirse 375209577).

### Task 5: PR'lar ve bildirim
- [ ] REST ile 2 PR (Türkçe özet). Merge yok. PushNotification.
