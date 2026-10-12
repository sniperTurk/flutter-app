# Retikül eşleştirme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Profilde seçilen dürbünün retikülü Hedef ekranında üreticinin kaydından çizilsin; eşleşmeyen dürbünleri ölç, eşleştirmeyi tahminsiz düzelt.

**Architecture:** `ReticleCatalog` (lib/data/reticle_catalog.dart) tek eşleştirme kaynağıdır. Ad anahtarı (`nameKey`) yapışık birim/odak düzlemi eklerini de ayıklar; kayıt birimi her zaman dürbünün taret birimiyle aynı olmalıdır; birden çok retikül listeleyen ad ("A / B") tek retikül sayılmaz. Python denetim scripti aynı kuralları yansıtır ve bir Dart testi iki tarafın aynı sonucu verdiğini sabitler.

**Tech Stack:** Dart/Flutter 3.47.2, Python 3 (stdlib).

**Spec:** Görev metni (oturum isteği, 2026-10-11) + CLAUDE.md UI kuralları. Ayrı spec dosyası yok; kararlar PR açıklamasında.

## Global Constraints

- Marka yalnız kendi retikülünü bulur; başka markanın aynı adlı kaydı kullanılmaz.
- Kayıt birimi (mil/moa) dürbünün taret birimiyle (MRAD → mil, MOA/SMOA → moa) uyuşmalı; uyuşmazsa eşleşme yok.
- Tahmin yok: iki kaydı ayırt edemezse veya ad tek retikül değilse genel ızgara.
- Veri eklenmez (data/reticles, scope_library değişmez).
- UI: MenzilSelect, "Seçiniz", ⓘ Türkçe (ne, nerede yazar, örnek), alan altında yardım yazısı yok, etikette parantez yok.

## Review Focus

1. Eski profilde kayıtlı "A / B" retikülü → Hedef genel ızgara çizer, çökmez (Task 2 testi).
2. Ad birim söylüyor ama taret başka birim (ör. "RAPTR-1F", MOA dürbün, kayıt MIL) → eşleşme yok (Task 2).
3. Yapışık ek: "VCT-34FFP", "VEPG-TMIL" ↔ "VEPG-T MIL" → aynı kayıt (Task 2).
4. Vortex: 85 dürbünün hepsi hâlâ eşleşir (mevcut test).
5. Tek retikül listeleyen model seçilince Retikül otomatik dolar; çoklu ise "Seçiniz" ile iki seçenek (Task 3).

---

### Task 1: Denetim scripti

**Files:** Create `tools/reticle_match_audit.py`, `tools/test_reticle_match_audit.py`

**Interfaces:** Produces `parse_scopes(text) -> list[dict]`, `parse_reticles(text) -> list[dict]`, `name_key(name, legacy=False) -> (core, unit)`, `find(name, turret_unit, brand, lib, legacy=False) -> dict|None`, `audit(scopes, lib, legacy) -> dict`; CLI `--json` yazdırır, `--markdown` marka tablosu.

- [ ] Testler: `test_multi_reticle_split`, `test_glued_suffix`, `test_unit_must_match_turret`, `test_other_brand_not_used`, `test_reason_codes` (kayit-yok, birim-farki, cizilemez, coklu).
- [ ] Çalıştır, başarısız gör; uygula; geçir; commit.

### Task 2: ReticleCatalog düzeltmesi

**Files:** Modify `lib/data/reticle_catalog.dart`; Test `test/reticle_scope_match_test.dart`, fixture `test/fixtures/reticle_scope_matches.json` (Task 1 scriptinin `--fixture` çıktısı: dürbün id → kayıt id veya null).

**Interfaces:** `ReticleCatalog.options(String?) -> List<String>`; `find` imzası aynı, kurallar sıkılaşır; `forScope` çoklu adda genel ızgara.

- [ ] Test: fixture'daki her dürbün için `find(option, clickUnit, brand)` id'si fixture ile aynı; örnek vakalar (Review Focus 1–3).
- [ ] Başarısız gör; uygula; geçir (çevrimdışı lint + CI test-diag); commit.

### Task 3: Profil Retikül kutusu

**Files:** Modify `lib/features/profiles/profiles_screen.dart` (`_reticlesOf` → `ReticleCatalog.options`), `lib/features/profiles/profile_field_info.dart` (`reticle` metni); Test `test/profile_lists_test.dart`.

- [ ] Widget testi: Element Optics çoklu retikül modeli → "Seçiniz", iki seçenek, ⓘ; tek retikül modeli → otomatik dolu.
- [ ] Uygula, geçir, commit.

### Task 4: Doğrulama ve PR

- [ ] Çevrimdışı lint, Python suite, test-diag, analyze-diag, biçim, sim-screens; PR (REST) önce/sonra tablosu, kayıt yok listesi.
