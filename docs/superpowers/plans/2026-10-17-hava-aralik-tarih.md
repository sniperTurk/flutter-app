# Hava Durumu: rüzgâr tarihi solda, bölüm aralıkları Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Under the wind clock the date moves under "Saat N yönünde" (both left); the Hava Durumu sections get the approved visible gaps (card → header text 20 pt, header text → card 8 pt).

**Architecture:** `WindClockPicker` swaps its one-line Row for a two-line Column. `MenzilSectionHeader` gets an opt-in exact-gap mode (`textGapAbove`/`textGapBelow` + `titleInfo` builder) so the 44 pt ⓘ target fits inside the header instead of inflating the gap; only the Hava Durumu pages use it (`_environmentInputs(sectionGaps: true)`), with the cards before a header at margin 0.

**Tech Stack:** Flutter 3.47.2, flutter_test, integration_test (sim-screens.yml).

**Spec:** owner task 2026-10-17 (Istanbul) "fix/hava-aralik-tarih" (decisions 19:23, 20:02, 20:03).

## Global Constraints

- Only `hava_durumu_view.dart`, `wind_clock_picker.dart` and the opt-in header mode; Pro Ayarlar, Profil, Hedef, Balistik / DOPE unchanged.
- No label/text changes; "Hava Durumu" menu label unchanged; no new fields.
- Visible gaps measured as text-box edges, ±0,5 pt; ⓘ tap targets stay 44 × 44 pt and outside the boxes.
- "Rüzgâr yönü" title → clock gap unchanged (title bottom → hour-12 button top = 8 pt).
- Last card → "Pro Ayarlar'a geç" unchanged (10 pt).

## Review Focus

- Pressure warning shown between İrtifa card and Rüzgâr header → no lost gap, no overlap.
- 320 pt and text ×1.3 → no overflow; titles may wrap, gaps stay.
- Empty wind label (no direction yet) → date still on line 2, left.
- No-profile Hava page uses the same inputs → same gaps, no crash.
- Rüzgâr card inner top: 14 pt cannot be reached while the ⓘ keeps a 44 pt target outside the box (box top − 44 lies 9,4 pt above the card); the empty card padding (14 pt) is removed, the ⓘ row stays.

---

### Task 1: Tests (red)

**Files:** Create `test/hava_aralik_tarih_test.dart`, `integration_test/hava_aralik_tarih_screens_test.dart`

- [ ] Widget tests at 390/1.0, 320/1.0, 320/1.3: wind label above date, both left = picker left (±0,5), date top − label bottom = 3; header gaps 20/8 for Basınç Ölçer, İrtifa, Rüzgâr, Hava özeti; Rüzgâr card top = ⓘ target top; wind card → button 10; title → hour 12 = 8; `takeException()` null.
- [ ] Push, run test-diag on the file: expect FAIL (date right, gaps 30/25).

### Task 2: Wind date left

**Files:** Modify `lib/features/ballistics/wind_clock_picker.dart:124-147`

- [ ] Row → Column(start): `_OneLine(label, centerStart)`, `SizedBox(height: 3)`, `_OneLine(date, centerStart)`; comment updated.

### Task 3: Exact header gaps

**Files:** Modify `lib/ui/menzil_widgets.dart` (`MenzilSectionHeader`), `lib/features/ballistics/ballistics_shared_rows.dart` (`_headerWithInfo`), `lib/features/ballistics/hava_durumu_view.dart`

- [ ] `MenzilSectionHeader({double? textGapAbove, double textGapBelow = MenzilSpace.sm, Widget Function(AlignmentGeometry, EdgeInsetsGeometry)? titleInfo})`: text at `textGapAbove` (+ extra so height ≥ 44 with an ⓘ), ⓘ target clamped inside, icon on the first line's centre.
- [ ] `_environmentInputs(..., sectionGaps)`: Hava pages pass true; cards before headers margin 0 (İrtifa keeps md when the pressure warning shows; Rüzgâr header then gapAbove 10); Rüzgâr card top padding 0; `_atmosphereResult(context, gapAbove: 20)` without the extra SizedBox.
- [ ] CI: test-diag (whole suite), analyze-diag, iOS CI, sim-screens 390/320.
