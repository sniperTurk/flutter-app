import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"

class BallisticsUnitConversionHygieneTest(unittest.TestCase):
    def test_vacuum_ui_does_not_duplicate_or_render_wind_angle_conversion(self):
        source = SCREEN.read_text(encoding="utf-8")
        self.assertNotIn("p.windMrad * 3.437746770784939", source)
        # M1: whole-screen check (the table moved into a separate Tablo view).
        table = source
        self.assertNotIn("Units.mradToMoa(p.windMrad)", table)
        self.assertNotIn("p.windMrad", table)

if __name__ == "__main__":
    unittest.main()
