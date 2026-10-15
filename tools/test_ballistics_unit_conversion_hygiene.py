import pathlib
import unittest
from dart_library_source import library_text

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"

class BallisticsUnitConversionHygieneTest(unittest.TestCase):
    def test_vacuum_ui_does_not_duplicate_or_render_wind_angle_conversion(self):
        source = library_text(SCREEN)
        self.assertNotIn("p.windMrad * 3.437746770784939", source)
        # M1: whole-screen check (the table moved into a separate Tablo view).
        table = source
        self.assertNotIn("Units.mradToMoa(p.windMrad)", table)
        # V355: the wind column exists, but only in drag mode (see v353).
        self.assertEqual(table.count("p.windMrad"), 1)

if __name__ == "__main__":
    unittest.main()
