"""Audit 2026-10-15 (PRF-6): the hand-calculated numbers the Dart test uses
are reproduced by the independent reference solver, and no API key is
committed."""
import re
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15 as d  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "test" / "audit_2026_10_15" / "prf6_e2e_test.dart"


class Prf6HandCalc(unittest.TestCase):
    def test_observation_and_back_solved_bc_match_the_dart_test(self):
        src = DART.read_text(encoding="utf-8")
        observed = float(re.search(r"_observedMrad = ([0-9.]+);", src).group(1))
        ref_bc = float(re.search(r"_referenceBc = ([0-9.]+);", src).group(1))
        self.assertAlmostEqual(round(d.correction(d.TRUE_BC), 2), observed, places=9)
        self.assertAlmostEqual(d.bc_for(observed), ref_bc, delta=5e-5)

    def test_lower_bc_needs_more_correction(self):
        self.assertGreater(d.correction(0.225), d.correction(0.243))


class NoApiKey(unittest.TestCase):
    def test_no_google_key_in_tracked_files(self):
        files = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True,
                               text=True, check=True).stdout.split()
        pat = re.compile(r"AIza[0-9A-Za-z_\-]{35}")
        hits = []
        for f in files:
            p = ROOT / f
            try:
                if p.stat().st_size > 5_000_000:
                    continue
                if pat.search(p.read_text(encoding="utf-8", errors="ignore")):
                    hits.append(f)
            except OSError:
                continue
        self.assertEqual(hits, [])


if __name__ == "__main__":
    unittest.main()
