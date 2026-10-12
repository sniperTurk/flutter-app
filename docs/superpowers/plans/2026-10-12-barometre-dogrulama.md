# Barometre, çok mesafeli doğrulama ve duyarlılık testleri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ö4 (telefon barometresi), Ö6 (Mach bantlı sürüklenme doğrulaması), Ö13 (duyarlılık testleri + GA saha protokolü).

**Architecture:** Barometre bir port + `sensors_plus` adaptörü, yalnız düğmeyle. Ö6 saf çekirdek `lib/core/drag_band_truing.dart`, Hız Doğrulama sayfasında üçüncü mod. Ö13 yalnız test ve belge. Çözücü değişmez.

**Tech Stack:** Flutter 3.47.2 / Dart, sensors_plus 7.1.1, flutter_test, Python unittest.

**Spec:** `docs/superpowers/specs/2026-10-12-barometre-dogrulama-design.md`

## Global Constraints
- Barometre yalnız düğmeyle; ilk geçerli örnek 300–1100 hPa; 3 sn zaman aşımı; hata → "Basınç okunamadı; elle girin."
- Mach bantları `<1,2 | 1,2–1,5 | 1,5–2 | >2`; `>2` uydurulmaz; geçiş ±0,05 Mach.
- Koruma: ≥3 mesafe; serbest bant ≤ n−1; %10 değişim ≥ 0,05 mrad; σ_gözlem 0,05 mrad, σ_k %5; |k−1| ≤ 0,20; kalan fark > 0,15 mrad → uyarı.
- Duyarlılık toleransı: max(%15, 0,3 cm), işaret aynı.
- UI: ⓘ zorunlu; helper/hint yok; etikette parantez yok; kalın yok; iki kutu yan yana; aç/kapa düğmesi yok; Türkçe kısa.
- Yerel Flutter yok (indirme 403): `python3 tools/offline_dart_lint.py`, Python paketi, CI `test-diag`, `analyze-diag`, format iş akışı.

## Review Focus
- Barometresi olmayan cihaz / simülatör: hata atmadan "okunamadı" → Task 2 testi (adaptör `MissingPluginException` ve boş akış).
- inHg biriminde basınç kutusu: okunan hPa inHg'ye çevrilmeli → Task 2 widget testi (`metric=false` değil; birim dönüşümü saf fonksiyonda test).
- Aynı mesafe iki kez / sıfırdan kısa mesafe → Task 3 testi (`DragTruingFailure`).
- Çoklu BC'li mühimmat → Task 3 testi (red).
- Katalog (kullanıcı girmediği) mühimmat: eğri kaydedilmez → Task 4 widget testi.

---

### Task 1: Ö13 duyarlılık testi ve GA protokolü
**Files:** Create `test/hesap_duyarlilik_test.dart`, `docs/ga-saha-dogrulama-protokolu.md`
- [ ] T1/T2/P1/P2 (spec K11) için `engine.solve` ile `Δcm = (corr_nom − corr_shot)·R/10`; rüzgârda `windMrad·R/10`. Beklenenler rapor 2.1/2.2 (+1 m/s satırı = +10 m/s satırı / 10). Hız satırında `zeroMuzzleVelocityMps` nominal.
- [ ] CI `test-diag files=test/hesap_duyarlilik_test.dart` → PASS. Commit.

### Task 2: Ö4 barometre
**Files:** Create `lib/tools/ports/pressure_sensor.dart`, `lib/tools/adapters/sensors_plus_pressure_sensor.dart`, `test/phone_pressure_test.dart`; Modify `lib/tools/tools_services.dart`, `lib/features/ballistics/ballistics_screen.dart` (`_weatherFillCard`), `lib/features/ballistics/environment_field_info.dart` (`pressure`), `tools/configure_ios_info_plist.py`, `tools/test_configure_ios_info_plist.py`, `test/support/tool_fakes.dart`.
**Interfaces:** `sealed class PressureReading`; `PressureRead(double hpa)`; `PressureUnavailable()`; `abstract interface class PressureSensor { Future<PressureReading> read(); }`; `SensorsPlusPressureSensor({Stream<BarometerEvent> Function()? source, Duration timeout})`; `ToolsServices.pressure`; `TestPressure(PressureReading)` sayaçlı (`reads`).
- [ ] RED testler: açılışta `reads == 0` (otomatik hava açıkken bile); düğme → kutu `912.4`, durum metni; `PressureUnavailable` → "okunamadı", kutu değişmez; adaptör: hata, boş akış, aralık dışı → unavailable, geçerli → read; Info.plist metni "Basıncı telefondan al" içerir.
- [ ] Uygula, lint, commit.

### Task 3: Ö6 çekirdek
**Files:** Create `lib/core/drag_band_truing.dart`, `test/drag_band_truing_test.dart`.
**Interfaces:** `DragBandTruing.solve({required BallisticInput base, required List<DragObservation> observations, required double sectionalDensity, BallisticEngine engine}) → DragBandResult`; `DragObservation(double rangeM, double observedMrad)`; `DragBandResult{List<MachBandScale> bands; List<DragObservationFit> fits; List<DragSample> curve; double sectionalDensity; double maxResidualMrad; bool get inconsistent}`; `MachBandScale{String label; double scale; bool fitted}`; `DragObservationFit{rangeM, observedMrad, beforeMrad, afterMrad}`; `DragTruingFailure(DragTruingRejection)` + `.message`; `DragBandTruing.ownCurve(...)`.
- [ ] RED: k=1 korunumu (özel eğriyle çözüm = G7 çözüm, 1e-6 mrad); sentetik bozulmayı (k 1,03 @1,2–2) 500/700/900 m'den bulur, kalan < 0,03 mrad; `>2` bandı daima 1; az mesafe / aynı mesafe / sıfır altı / çoklu BC / %20 dışı red; 3 mesafede serbest ≤ 2.
- [ ] Uygula, commit.

### Task 4: Ö6 ekran
**Files:** Modify `lib/features/tools/truing_screen.dart`; Test `test/truing_drag_band_test.dart`.
- [ ] RED: mod listesinde "Sürüklenme eğrisi"; 3 satır + "Mesafe ekle" (6'da kaybolur); her kutuda ⓘ; hesap → `truing-drag-result`; katalog mühimmatında kaydet → uyarı, kayıt yok; kişisel mühimmatta onay → `dragCurve` yazılır, `bc` = SD, `bcModel` g1, `bcBands` silinir.
- [ ] Uygula, commit.

### Task 5: Taslaklar, ekran görüntüleri, PR
- [ ] `docs/barometre-dogrulama/taslak/*.png` (Task 2–4'ten önce).
- [ ] CI: test-diag, analyze-diag, format; sim-screens en çok 1 kez; PR (REST), merge yok.
