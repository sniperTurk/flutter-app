# Saçma sürüklenme tablosu — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the forum-sourced GA (diabolo) Cd–Mach table with one built from scientific sources — only if such a source exists with usable terms; otherwise document why and quantify what is at stake.

**Architecture:** Research first (sources, method, Mach range, licence). Decision gate: a table enters `lib/core/standard_drag_tables.dart` only when a scientific source covers PCP Mach 0.55–1.0 with numeric values and reusable terms. A standard-library Python comparison (`tools/sacma_surukleme_karsilastirma.py`, reusing `tools/formula_reference.py`) produces the 10–100 m drop/drift table that `docs/sacma-surukleme/RAPOR.md` embeds verbatim.

**Tech Stack:** Python 3 stdlib (unittest), Dart/Flutter (only if the gate opens).

**Spec:** owner task 2026-10-12 (scheduled run prompt).

## Global Constraints

- Forbidden sources: ChairGun, Strelok, Applied Ballistics, JBM, QuickLOAD, GRT data/tables; forums, blogs, dealers.
- "Belirsizse EKLEME, rapora yaz."
- G1/G7 results must not change. GA table must not be deleted.
- UI: no parentheses or bold in list labels, short Turkish ⓘ, font Oswald.
- Never merge. PR via REST.

## Review Focus

1. Report numbers drifting from the script → test asserts RAPOR.md contains the generated block verbatim.
2. Same-BC comparison overstating real difference → add a BC-refit row (G1 BC matched to GA velocity at 50 m).
3. Sensitivity scenario mistaken for a new table → clearly labelled, lives only in the tool, never in `lib/`.
4. Zero range check: drop difference at the zero distance ≈ 0.
5. Dart tables untouched → `git diff main -- lib/` empty when the gate stays closed.

---

### Task 1: Source research (done in session; result in RAPOR.md §1–2)

Gate result: **closed** — no source with numeric Cd over Mach 0.6–1.0 for diabolo pellets and reusable terms (details in report).

### Task 2: Comparison tool

**Files:** Create `tools/sacma_surukleme_karsilastirma.py`, Test `tools/test_sacma_surukleme_karsilastirma.py`

**Interfaces — Produces:**
- `flat_table(ref_mach: float = 0.58) -> list[tuple[float, float]]` — constant Cd equal to GA at `ref_mach` (sensitivity only).
- `trajectory(model_or_pts, bc: float, load: dict, wind_mps: float) -> list[Row]` with `Row(range_m, drop_cm, drift_cm, velocity_mps)`.
- `fit_bc(target_pts, ref_rows, load) -> float` — bisection on BC to match velocity at 50 m.
- `markdown_block() -> str` — the exact block embedded in the report.

- [ ] Write failing tests (flat table level, zero-range drop ≈ 0, identical model ⇒ zero difference, fit_bc velocity match ≤ 0.01 m/s, block has rows 10…100 m, report contains block).
- [ ] Run `python3 -m unittest tools/test_sacma_surukleme_karsilastirma.py` → FAIL (module missing).
- [ ] Implement; rerun → PASS.
- [ ] Commit.

### Task 3: Report + PR

- [ ] Write `docs/sacma-surukleme/RAPOR.md` (sources table, decision, embedded block, GA keep/remove options, saved-profile compatibility).
- [ ] Run offline lint, full Python suite, CI diag workflows; open PR (no merge); notify owner.
