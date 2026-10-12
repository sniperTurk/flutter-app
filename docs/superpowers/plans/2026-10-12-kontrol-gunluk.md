# Ö11 / Ö10 / Ö9 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** Araçlar altında Atış Öncesi Kontrol, Sıfır Grubu ve Atış Günlüğü sayfaları.
**Spec:** `docs/superpowers/specs/2026-10-12-kontrol-gunluk-design.md` (A1–A15).
**Tech:** Flutter/Dart, shared_preferences, flutter_test. Yerelde Flutter yok:
Dart testleri `test-diag.yml`, analiz `analyze-diag.yml`, biçim `format-fix` (375209577) ile CI'da.

## Global Constraints
- ⓘ her girilen/seçilen değerde; yardım yazısı yok; parantezsiz etiket; hintText yok; kalın yok; listeler "Seçiniz" ile başlar; iki kutu yan yana.
- `lib/features/tools` ve `lib/tools` içinde SharedPreferences adı geçmez; renkler yalnız temadan.
- Sıfır ofseti onaysız yazılmaz; soğuk namlu önerisi eşik + onay olmadan görünmez; ağ yok.

### Task 1: Saf hesaplar (TDD)
- [ ] `test/group_center_test.dart`: 4 noktalı bilinen grup → merkez, σ, σ/√n; n<2 σ yok; klik cm (0,1 mrad @100 m = 1 cm); gereken atış (σ=2 cm, klik 1 cm → 4 toplam); sıfır mesafesine çevirme.
- [ ] `test/cold_bore_test.dart`: <5 ilk atış → öneri yok (neden: az kayıt); 5 tutarlı ilk atış → öneri, işaret ters; gürültülü 5 atış → öneri yok (anlamsız); susturucu ayrımı; ilk atış olmayanlar sayılmaz.
- [ ] `test/preshot_checklist_test.dart`: FFP → 5 madde (SFP yok); SFP/bilinmiyor → 6; birim etiketi.
- [ ] Uygula: `lib/tools/domain/{group_center,cold_bore,preshot_checklist}.dart`.

### Task 2: Depolar (TDD)
- [ ] `test/shot_journal_store_test.dart`: ekle/oku/sil, bozuk JSON, 1000 sınırı, onay bayrağı.
- [ ] `test/shot_settings_zero_offset_test.dart`: `updateZeroOffset` diğer alanları korur, `changes` artar.
- [ ] Uygula.

### Task 3: Sayfalar + hub (TDD widget)
- [ ] `test/kontrol_gunluk_screens_test.dart`: hub'da 3 kart; kontrol listesi sayaç/Hazır; sıfır grubu dokunuş → merkez, "atış daha" metni, Uygula'sız yazmama, Uygula ile yazma; günlük kaydet, eşik altında onay düğmesi yok, onay → bayrak.
- [ ] Python sözleşmesi: hub kart sayısı 8 → 11.
- [ ] `ballistics_screen.dart`: `ShotSettingsStore.changes` dinle; Hedef'te `ColdBoreHint`.

### Task 4: Doğrulama
- [ ] offline lint + unittest; CI test/analyze/format; sim-screens (1 kez, `integration_test/kontrol_gunluk_screens_test.dart`); PR (REST), merge yok.
