"""ATM-1 (pre-TestFlight audit 2026-10-14b): the restored Hava Durumu is solved.

Copied from audit/testflight-2026-10-14b
(tools/test_denetim_2026_10_14b_atm.py) with its expectedFailure removed,
plus guards for the fix. Stdlib only.

Run: python3 -m unittest tools/test_atm1_acilis_hesabi.py
"""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"
DART_TEST = ROOT / "test/audit_2026_10_14b/atm1_restart_solve_test.dart"


def _method(src: str, signature: str) -> str:
    """Body of a Dart method from its signature to the matching brace."""
    i = src.index(signature)
    j = src.index("{", i)
    depth = 0
    for k in range(j, len(src)):
        if src[k] == "{":
            depth += 1
        elif src[k] == "}":
            depth -= 1
            if depth == 0:
                return src[i:k + 1]
    raise AssertionError(signature)


class Atm1(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src = SCREEN.read_text(encoding="utf-8")
        cls.body = _method(cls.src, "Future<void> _loadShotSettings() async {")

    def test_atm1_saved_weather_is_solved_after_it_is_restored(self):
        # ATM-1: a solve must follow the restore of the saved Hava Durumu.
        self.assertRegex(self.body, r"_quietSolve\(\)|solve\(\)")

    def test_solve_comes_after_the_restore_and_the_mounted_check(self):
        body = self.body
        restore = body.index("_applyWeatherSi(s)")
        solve = body.index("_quietSolve()")
        self.assertLess(restore, solve)
        self.assertLess(body.index("if (!mounted) return;"), solve)

    def test_solve_only_when_something_was_restored(self):
        # Nothing saved: no extra solve, the first automatic one stands.
        block = _method(self.body, "if (s != null) {")
        self.assertIn("_quietSolve()", block)

    def test_no_network_in_the_restore(self):
        for call in ("_fillWeather", "_maybeAutoWeather", "_warmUpPhoneAltitude",
                     "_fillPressure", "Timer("):
            self.assertNotIn(call, self.body, call)

    def test_dart_tests_are_not_skipped(self):
        src = DART_TEST.read_text(encoding="utf-8")
        code = "\n".join(l for l in src.splitlines() if not l.lstrip().startswith("//"))
        self.assertIsNone(re.search(r"\bskip\s*:", code))
        self.assertIn("Hava yoğunluğu after a restart matches the restored boxes", src)
        self.assertIn("Hedef opened directly shows the F1 note for the restored İrtifa", src)


if __name__ == "__main__":
    unittest.main()
