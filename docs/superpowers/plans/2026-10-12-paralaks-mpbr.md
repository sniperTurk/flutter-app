# Paralaks mesafesi + Avcı sıfırı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Araçlar altına PCP paralaks mesafe tablosu (Ö8) ve avcı sıfırı / MPBR (Ö7) sayfalarını eklemek.

**Architecture:** İki saf hesap modülü (`parallax_range.dart`, `mpbr.dart`), bir SharedPreferences kaydı, iki araç sayfası. Çözücü değişmez; MPBR çağıranın kurduğu `BallisticInput` ile `BallisticEngine.solveReachable`'ı tarar.

**Tech Stack:** Flutter/Dart, shared_preferences, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-12-paralaks-mpbr-design.md`

## Global Constraints

- Kısa Türkçe; her MenzilInput/MenzilSelect'te `info:`; `helperText`/`hintText` yok; etiketlerde parantez yok; kalın yok.
- Liste kutuları `hint` vermez (varsayılan "Seçiniz").
- İşaret | Mesafe yan yana (`MenzilFieldGrid`); Hedef bölge çapı ve Tekerlek işareti `MenzilFullWidth`.
- Bölge listesi tam olarak: 2,5 / 4 / 10 / 15 / 20 cm.
- MPBR: ICAO hava, profil hızı, standart yerçekimi; profil yazılmaz.
- Paralaks: < 2 farklı işaret → null; aralık dışı uç değer.

## Review Focus

- Aynı işaretin iki kez girilmesi → mesafe güncellenir, liste çift satır göstermez (Task 1 testi).
- Azalan işaret–mesafe ilişkisi (tekerlek ters yönlü) → ara değer yine doğru (Task 1 testi).
- Yard profili → Paralaks/MPBR sonuçları yd, kayıt metre (Task 3 ve 4 testleri).
- BC'siz mühimmat → MPBR çöker değil, vakum çözücüyle sonuç verir (Task 2 testi).
- Bozuk kayıt JSON'u → boş tablo, sayfa açılır (Task 1 testi).

---

### Task 1: Paralaks hesap + kayıt

**Files:** Create `lib/core/parallax_range.dart`, `lib/services/parallax_table_store.dart`; Test `test/parallax_range_test.dart`.

**Interfaces — Produces:**
- `class ParallaxPoint { final double mark; final double distanceM; }`
- `ParallaxRange.distanceAt(List<ParallaxPoint>, double mark) → double?`
- `ParallaxRange.pickMarks(List<ParallaxPoint>) → List<double>` (sıralı işaretler + ardışık orta noktalar)
- `ParallaxRange.upsert(List<ParallaxPoint>, ParallaxPoint) → List<ParallaxPoint>` (işarete göre sıralı)
- `ParallaxTableStore.load(profileId) → Future<List<ParallaxPoint>>`, `save(profileId, points)`; `keyFor(id) = 'sniper_turk.parallax.$id'`

- [ ] Test: `distanceAt([10→20 m, 20→40 m], 15) == 30`; `5 → 20`, `25 → 40`; tek nokta → null; ters yön `[10→40, 20→20], 15 → 30`; `pickMarks([10,20,30]) == [10,15,20,25,30]`; upsert aynı işaret → uzunluk değişmez, mesafe yeni; store bozuk JSON → `[]`.
- [ ] Çalıştır, düşsün; uygula; geçsin; commit.

### Task 2: MPBR tarama

**Files:** Create `lib/core/mpbr.dart`; Test `test/mpbr_test.dart`.

**Interfaces — Produces:**
- `class MpbrGrid { stepM, maxRangeM, zeroStepM }`, `MpbrGrid.pcp = (1, 150, 2)`, `MpbrGrid.firearm = (5, 600, 10)`
- `class MpbrResult { zeroM, nearZeroM?, nearM, farM, apexM }`
- `Mpbr.zoneDiametersCm = [2.5, 4, 10, 15, 20]`
- `Mpbr.solve({required BallisticInput Function(double zeroM, List<double> rangesM) build, required double zoneDiameterM, required MpbrGrid grid}) → MpbrResult?`

Algoritma (D7): yükseklik `h(r) = -dropM`, `h(0) = -sightHeight`. Uygun = tepe ≤ D/2 ve uzak sınır bulundu. Sıfır adımıyla tara; uygun→uygunsuz geçişinde 14 adım ikiye böl. Yakın/uzak sınır ve kesişimler ızgarada doğrusal.

- [ ] Test (bağımsız Python değerleri, spec tablosu): T1 15 cm → zero 203±4, near 0, far 237±5; P1 2,5 cm → zero 40±1,5, nearZero 16±1, near 10,6±1, far 44,6±1; P2 4 cm → zero 50±1,5, far 57±1,5; her sonuçta `apexM ≤ D/2 + 0,001`; BC'siz giriş → null değil.
- [ ] Çalıştır, düşsün; uygula; geçsin; commit.

### Task 3: Paralaks Mesafesi sayfası + Pro düğmesi + hub

**Files:** Create `lib/features/tools/parallax_screen.dart`; Modify `tools_screen.dart`, `home_screen.dart`, `ballistics_screen.dart` (Pro mesafe kartı); Test `test/parallax_screen_test.dart`, `test/tools_hub_order_test.dart`.

**Interfaces — Produces:** `ParallaxScreen({ProfileStore? profileStore, ActiveProfileStore? activeProfileStore, bool returnDistance = false})`; `Navigator.pop<double>(meters)`; `ToolsScreen({onProfilesChanged, WeaponPlatform? activePlatform})`. Anahtarlar: `tool-parallax`, `parallax-mark`, `parallax-distance`, `parallax-save`, `parallax-pick`, `parallax-result`, `parallax-use`, `parallax-need-two`, `pro-range-parallax`.

- [ ] Test: iki işaret kaydet (10→20, 20→40), `parallax-pick`'te 15 seç → "30 m"; returnDistance'ta `parallax-use` 30 döndürür; tek işarette `parallax-need-two`; yard profilinde birim yd; hub: PCP'de `tool-parallax` var, ateşlide yok; Pro PCP'de `pro-range-parallax` var.
- [ ] Çalıştır, düşsün; uygula; geçsin; commit.

### Task 4: Avcı Sıfırı sayfası

**Files:** Create `lib/features/tools/mpbr_screen.dart`; Modify `tools_screen.dart`; Test `test/mpbr_screen_test.dart`.

**Interfaces — Consumes:** Task 2. **Produces:** `MpbrScreen({ProfileStore?, ActiveProfileStore?})`; anahtarlar `tool-mpbr`, `mpbr-zone`, `mpbr-result`, `mpbr-line`, `mpbr-no-profile`.

- [ ] Test: ateşli profil, 15 cm seç → `mpbr-line` "Sıfır … tutuşsuz" içerir; profil deposundaki kayıt değişmez; ⓘ var; hub'da her iki platformda `tool-mpbr`.
- [ ] Çalıştır, düşsün; uygula; geçsin; commit.

### Task 5: Taslaklar, kontroller, PR

- [ ] `docs/paralaks-mpbr/taslak/` altında iki sayfa taslağı (PNG).
- [ ] `python3 tools/offline_dart_lint.py`; `python3 -m unittest discover -s tools -p 'test_*.py'`.
- [ ] Dal push; format, analyze-diag, test-diag; sim-screens en fazla 1 kez.
- [ ] REST ile PR (Türkçe), ekran görüntüleri; merge yok.
