# Pro Ayarlar aralıkları Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pro Ayarlar: "Atış mesafesi" kartının üstü → etiket 20 pt; kapalı açılır kutu başlığı 60 pt.

**Architecture:** Only `lib/features/ballistics/pro_ayarlar_view.dart` changes. The range card's empty top comes from the compact label row (44 pt ⓘ target, label at its bottom, `_CompactLabel` in `lib/ui/menzil_widgets.dart`); the card is rebuilt as a Stack (card surface behind, content in front) so the ⓘ keeps its 44 × 44 pt target, the part of it above the card edge sits in the page's top padding, and the page's top padding is reduced by the same amount so the card does not move. `_proBox` gets no vertical card padding; the header (InkWell) itself is ≥ 60 pt tall, so the whole 60 pt is tappable; the open content keeps its 8 pt gap and 14 pt bottom padding.

**Tech Stack:** Flutter 3.47.2, flutter_test.

**Spec:** owner decision 2026-10-17 20:54–21:01 (task text in the PR).

## Global Constraints

- Card top → "Atış mesafesi" label top = 20 pt (±0,5), text ×1.0 and ×1.3.
- Closed `_proBox` card height = 60 pt (±0,5); header tap target ≥ 44 pt.
- Gap between cards = 8 pt (`MenzilSpace.sm`), unchanged.
- No text, label, ⓘ or open-content change; no other page; shared widgets untouched.

## Review Focus

- ⓘ of Atış mesafesi still 44 × 44 pt and tappable on its top edge (above the card edge).
- Card's position on the page unchanged (page top → card top = 10 pt).
- 320 pt × 1.3: no overflow, title/summary/chevron centred in the header.
- Open box: content unchanged, bottom padding 14 pt.
- Error text under the range box still shown.

### Task 1: Geometry tests + implementation

**Files:**
- Test: `test/pro_aralik_test.dart`
- Modify: `lib/features/ballistics/pro_ayarlar_view.dart` (`_proAyarlarPage`, `_proBox`, range card in `_proSection`)

- [ ] Write `test/pro_aralik_test.dart` (390 / 320 pt, ×1.0 / ×1.3): label top 20, header 60, header InkWell ≥ 44 and = card height, gaps 8, page top → card 10, ⓘ 44 × 44 and a tap 2 pt below its top opens the popup, centred title/summary/chevron, open box bottom padding 14, no exception.
- [ ] Run on CI (`test-diag.yml`, files=test/pro_aralik_test.dart): expect FAIL on main geometry (≈42,4 and 76).
- [ ] Implement.
- [ ] Run full `test-diag.yml files=test`, `analyze-diag.yml`, iOS CI: expect PASS.
- [ ] Commit.
