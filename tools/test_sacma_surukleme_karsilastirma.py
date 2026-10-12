"""Checks for the pellet drag comparison (saçma sürüklenme, 2026-10-12).

* the sensitivity table is flat at GA's Cd at Mach 0.58 (Ladommatos 2019 test Mach);
* trajectories zero where they should and identical drag laws give no difference;
* the BC refit really matches the reference velocity at 50 m;
* docs/sacma-surukleme/RAPOR.md embeds exactly what the tool prints.
Standard library only.
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as ref  # noqa: E402
import sacma_surukleme_karsilastirma as cmp  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "docs/sacma-surukleme/RAPOR.md"


class SensitivityTable(unittest.TestCase):
    def test_flat_table_is_ga_value_at_reference_mach(self):
        ga_at = ref.Pchip(ref.load_table("ga"))(0.58)
        pts = cmp.flat_table()
        self.assertGreaterEqual(len(pts), 2)
        for _m, cd in pts:
            self.assertAlmostEqual(cd, ga_at, places=12)


class Trajectories(unittest.TestCase):
    def test_drop_is_zero_at_zero_range(self):
        load = cmp.LOADS[0]
        rows = cmp.trajectory("ga", load["bc"], load, wind_mps=0.0, ranges=(load["zero_m"],))
        self.assertAlmostEqual(rows[0].drop_cm, 0.0, places=3)

    def test_same_law_same_bc_gives_identical_rows(self):
        load = cmp.LOADS[0]
        a = cmp.trajectory("g1", load["bc"], load, wind_mps=4.0)
        b = cmp.trajectory(ref.load_table("g1"), load["bc"], load, wind_mps=4.0)
        for ra, rb in zip(a, b):
            self.assertAlmostEqual(ra.drop_cm, rb.drop_cm, places=9)
            self.assertAlmostEqual(ra.drift_cm, rb.drift_cm, places=9)

    def test_drop_grows_with_range_past_zero(self):
        load = cmp.LOADS[0]
        rows = cmp.trajectory("g1", load["bc"], load, wind_mps=0.0)
        past = [r.drop_cm for r in rows if r.range_m > load["zero_m"]]
        self.assertEqual(past, sorted(past))
        self.assertGreater(past[-1], 0.0)

    def test_fit_bc_matches_reference_velocity_at_50m(self):
        load = cmp.LOADS[0]
        target = cmp.trajectory("ga", load["bc"], load, wind_mps=0.0, ranges=(50.0,))[0]
        bc = cmp.fit_bc("g1", target.velocity_mps, load)
        got = cmp.trajectory("g1", bc, load, wind_mps=0.0, ranges=(50.0,))[0]
        self.assertAlmostEqual(got.velocity_mps, target.velocity_mps, delta=0.01)


class Report(unittest.TestCase):
    def test_block_has_every_10m_row(self):
        block = cmp.markdown_block()
        for r in range(10, 101, 10):
            self.assertIn(f"| {r} |", block)

    def test_report_embeds_generated_block_verbatim(self):
        self.assertIn(cmp.markdown_block(), REPORT.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
