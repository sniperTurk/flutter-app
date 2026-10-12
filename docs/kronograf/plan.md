# Kronograf serisi ve Mühimmat sıcaklığı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kronograf hızlarından ortalama/SD/ES/n ve PCP dizi eğimi; profile ve WEZ'e onaylı aktarım; serilerden barut katsayısı; ardından ateşli tüfekte Mühimmat sıcaklığı.

**Architecture:** Saf hesap `lib/core/velocity_series.dart`; seriler `lib/services/chrono_store.dart`; yeni ekran `lib/features/tools/chrono_screen.dart`. Ö1 tek saf fonksiyon (`PowderTemperature.effectiveTempC`) + bir `ShotSettings` alanı + Hava Durumu'nda bir kutu. Çözücü değişmez.

**Tech Stack:** Flutter 3.47.2 / Dart, shared_preferences, flutter_test.

**Spec:** `docs/kronograf/tasarim.md`

## Global Constraints
- Ayırıcılar: satır sonu, boşluk, `;`; virgül ondalık. Geçerli hız 50–1500 m/s.
- SD = örnek SD (n − 1); n < 3 → SD null. ES = max − min.
- Katsayı: ≥ 2 seri, sıcaklık açıklığı ≥ 10 °C, |k| ≤ 10 %/15 °C; n ağırlıklı EKK; T0 = ağırlıklı ortalama sıcaklık; k = b·15/v0·100.
- Katsayı yoksa hız düzeltilmez; varsayılan katsayı yok.
- Dizi eğimi: yalnız PCP ve n ≥ 5.
- Mühimmat sıcaklığı: yalnız ateşli; boş/okunamaz/−50..60 °C dışı → hava sıcaklığı.
- UI: ⓘ zorunlu; helperText/hintText yok; etikette parantez yok; kalın yok; "Seçiniz"; iki kutu yan yana.
- Doğrulama (yerel Flutter yok, indirme engelli): `python3 tools/offline_dart_lint.py`, Python paketi, CI `test-diag`, `analyze-diag`, format iş akışı.

## Review Focus
- fps girilen seri profile m/s yerine fps olarak yazılmamalı → Task 4 testi (fps → profil 2625 fps).
- Katsayılı profilde Mühimmat sıcaklığı boşken profile aktarım reddedilmeli → Task 4 testi.
- Sondaki boş satır / boşluk hata sayılmamalı → Task 1 testi.
- Aynı sıcaklıkta iki seriyle katsayı istenmemeli → Task 1 testi (null) + Task 4 (düğme yok).
- Ateşli tüfekte alanlar boşken sonuçlar değişmemeli → Task 5 testi (DOPE birebir).

---

### Task 1: Seri istatistiği ve katsayı uydurma
**Files:** Create `lib/core/velocity_series.dart`; Test `test/velocity_series_test.dart`
**Interfaces (Produces):**
- `class VelocitySeries { final List<double> mps; int get n; double get meanMps; double? get sdMps; double get esMps; double? get slopeMpsPerShot; static VelocitySeries parse(String text, {required bool fps}); }`
- `class VelocitySeriesFormatException implements Exception { final int line; final String message; }`
- `({double coefPercentPer15C, double referenceC, double v0Mps})? fitPowderCoefficient(List<({double tempC, double meanMps, int n})> sessions)`
- [ ] Testler: `'800\n805\n795'` → mean 800, sd 5, es 10; `'2625;2641'` fps → m/s; `'812,4 811,6'` → 2 değer; `'800\nabc'` → line 2; `'800\n\n805\n'` → n 2; 49 m/s → hata; n = 2 → sd null; `[280,279,278,277,276]` → eğim −1; n < 2 eğim null; katsayı (5, 790, 5) ve (35, 814, 5) → k 1,496 ±0,005, T0 20, v0 802; tek sıcaklık / 8 °C açıklık / k > 10 → null.
- [ ] CI'da FAIL (tanımsız) → yaz → PASS → commit.

### Task 2: Seri deposu
**Files:** Create `lib/services/chrono_store.dart`; Test `test/chrono_store_test.dart`; Modify `lib/features/profiles/profiles_screen.dart` (silmede `ChronoStore().deleteProfile`, hata yutulur)
**Produces:** `class ChronoSession { DateTime date; double tempC; List<double> mps; }` (+ `toJson`/`fromJson`); `class ChronoStore { const ChronoStore(); static String keyFor(String id) => 'sniper_turk.chrono.$id'; Future<List<ChronoSession>> load(String id); Future<void> add(String id, ChronoSession s); Future<void> removeAt(String id, int index); Future<void> deleteProfile(String id); }`
- [ ] Testler: ekle → yükle; bozuk JSON → boş; `removeAt`; `deleteProfile` → anahtar yok.
- [ ] FAIL → yaz → PASS → commit.

### Task 3: Ö1 saf kısım ve saklama
**Files:** Modify `lib/core/powder_temperature.dart`, `lib/services/shot_settings_store.dart`; Test `test/powder_temperature_profile_test.dart`, `test/shot_settings_test.dart`
**Produces:** `static double PowderTemperature.effectiveTempC({required double airC, double? ammoC})`; `ShotSettings.ammoTempText` (JSON `ammoTemp`, varsayılan `''`).
- [ ] Testler: (18, 33) → 33; (18, null) → 18; (18, 75) → 18; (18, NaN) → 18; JSON gidiş-dönüş; eski JSON → `''`.
- [ ] FAIL → yaz → PASS → commit.

### Task 4: Kronograf ekranı
**Files:** Create `lib/features/tools/chrono_screen.dart`, `lib/features/tools/chrono_field_info.dart`; Modify `lib/features/tools/tools_screen.dart` (kart `tool-chrono`, Hız Doğrulama'nın altında), `lib/features/tools/tool_support.dart` (`apply(..., powderCoef, powderReferenceC)`), `lib/ui/menzil_widgets.dart` (`MenzilInput.minLines/maxLines`), `tools/test_v271_removed_feature_scope.py` (kart sayısı 9); Test `test/chrono_screen_test.dart`, `test/tools_hub_order_test.dart`
**Consumes:** Task 1–3.
**Anahtarlar:** `chrono-unit`, `chrono-ammo-temp`, `chrono-velocities`, `chrono-result`, `chrono-error`, `chrono-apply-velocity`, `chrono-apply-sd`, `chrono-save-series`, `chrono-sessions`, `chrono-fit`, `chrono-apply-coef`, `chrono-confirm`.
- [ ] Testler: üç hız → Ortalama/SD/ES/Atış sayısı; profil hızına aktarım (katsayısız: 800 m/s); fps girişi → profil 2625 fps; katsayılı profil + sıcaklık boş → `chrono-error`, profil değişmez; katsayılı profil 35 °C, k 1,5, T0 20, ortalama 815,4 → profil 815,4/1,015; SD aktarımı → `ShotSettings.sdText` fps; PCP: `chrono-ammo-temp` ve `chrono-save-series` yok, 5 atışta "Dizi eğimi"; iki seri (5 °C, 35 °C) → `chrono-fit` görünür, aktarım profile k/T0/v0 yazar; Araçlar'da `tool-chrono` Hız Doğrulama'nın altında.
- [ ] FAIL → yaz → PASS → commit.

### Task 5: Hava Durumu'nda Mühimmat sıcaklığı
**Files:** Modify `lib/features/ballistics/ballistics_screen.dart`, `lib/features/ballistics/environment_field_info.dart` (`ammoTemperature`); Test `test/ammo_temperature_test.dart`
**Consumes:** Task 3.
- [ ] Testler: ateşli profilde `env-ammo-temp` Sıcaklık ile aynı satırda (aynı dy), PCP'de yok; katsayısız ateşli profilde alan boş ve 36 iken DOPE metni aynı; katsayılı profilde boşken hız eski hesapla aynı, 36 °C'de `pro-powder-today` değişir; değer kaydedilir ve yeniden açılınca gelir.
- [ ] FAIL → yaz → PASS → commit.

### Task 6: Görseller ve doğrulama
- [ ] `docs/kronograf/taslak/` taslakları (kod öncesi).
- [ ] `integration_test/chrono_screens_test.dart`: ateşli profili depoya yazar, Araçlar, Kronograf (dolu), Hava Durumu ekranlarını çeker; sim-screens tek kez.
- [ ] Lint, Python paketi, CI test/analyze/format; PR (Türkçe, önce/sonra görselleri).

Yürütme: Native (sahip yok; görevler sıralı ve yerel Flutter yok, her CI turu pahalı).
