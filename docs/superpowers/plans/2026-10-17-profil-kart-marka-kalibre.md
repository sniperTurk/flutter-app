# Profil kartı: marka, kalibre Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The grey second line of each card in the Profiller list reads "<Tüfek markası>, <kalibre adı>" on exactly one line.

**Architecture:** `profileListSummary(RifleProfile)` in `lib/features/profiles/profiles_screen.dart` is rewritten; the card's `Text` (Key `profile-row-summary`) gets `maxLines: 1`. The cartridge name is resolved like the profile editor resolves the Kalibre of a saved rifle: `RiflePickerScreen.cartridgeName(rifle)`, overridden by the cartridge of the matching `RifleLibrary` variant (exact Marka+Model, else `ProfileCatalogMatch.rifle`, then the diameter/twist variant rule of `_variantFor`).

**Tech Stack:** Flutter 3.47.2, flutter_test.

**Spec:** owner decision 2026-10-17 18:59 Istanbul ("aç görevi"), task text in the session.

## Global Constraints

- Line: "<Marka>, <kalibre adı>", e.g. "Accuracy International, .308 Win". No sıfır, no fps, no BC.
- No name → caliberMm with 2 decimals and a comma: "7,82 mm".
- No brand → only the caliber part; no leading comma; empty when nothing is known (the row then shows only its name, as before).
- `maxLines: 1`, `TextOverflow.ellipsis`, `MenzilType.caption(c.ink2)`, `TextAlign.start`.
- Read only, never feeds the solver; saved data untouched.
- Nothing else changes (first line, top bar, summary cards, Profiller header / Profil ekle).

## Review Focus

- Saved library rifle whose model has no cartridge in its name ("AT-X LE") → name from the library variant (".308 Win"), not "7,82 mm".
- PCP rifle → no cartridge name → "Marka, 6,35 mm".
- Typed (user) rifle with a caliber not in any list → "Marka, 7,82 mm".
- Unknown rifle id → "" (no crash, no ", ").
- Brand of only spaces → caliber only.

---

### Task 1: profileListSummary + one-line Text

**Files:**
- Modify: `lib/features/profiles/profiles_screen.dart` (`_ProfileRow` summary Text and doc; `profileListSummary`)
- Test: `test/profiller_ustte_test.dart`, `test/pcp_muhimmat_tasarim_test.dart` (only the old-text expectations)
- Test: `test/profil_kart_marka_kalibre_test.dart` (new)

- [ ] Step 1: new tests: catalog rifle "ATA Arms, .308 Win"; library rifle "Accuracy International", "AT-X LE", 7.82 → "Accuracy International, .308 Win"; unlisted typed caliber 7.82 → "Marka, 7,82 mm"; PCP → "…, 6,35 mm"; unknown rifle → "" and no leading comma; blank brand → "7,82 mm". Widget: summary Text maxLines 1 + ellipsis; 320 pt × 1.25 with a typed rifle "Accuracy International" whose list name is ".338-378 Weatherby Mag" (Weatherby library variant cartridge via a user rifle brand/model on the library) → no exception, line inside the card, one line high.
- [ ] Step 2: run, expect FAIL.
- [ ] Step 3: implement.
- [ ] Step 4: update old expectations in `profiller_ustte_test.dart` and the velocity case in `pcp_muhimmat_tasarim_test.dart`; run all three files, PASS.
- [ ] Step 5: `tools/claude_flutter_verify.sh`; commit; draft PR; CI; sim-screens.
