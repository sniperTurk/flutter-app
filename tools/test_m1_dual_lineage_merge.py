from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SIGHT = ROOT / 'lib/features/tools/sight_height_screen.dart'
PUBSPEC = ROOT / 'pubspec.yaml'
WEATHER = ROOT / 'lib/tools/adapters/met_no_weather_provider.dart'

class DualLineageMergeContract(unittest.TestCase):
    def test_accessible_marker_fine_adjustment_is_preserved(self):
        text = SIGHT.read_text(encoding='utf-8')
        self.assertIn('_nudgeSelected', text)
        self.assertIn('minWidth: 44', text)
        self.assertIn('Seçili işaret', text)
        self.assertIn('_sameMarks', text)

    def test_m1_production_architecture_is_not_regressed(self):
        pub = PUBSPEC.read_text(encoding='utf-8')
        self.assertIn('camera:', pub)
        self.assertIn('http:', pub)
        # M2: image_picker is allowed ONLY for the Sight Height gallery choice
        # (see test_m2_design_contract.py); never for saving or other tools.
        self.assertIn('image_picker:', pub)
        weather = WEATHER.read_text(encoding='utf-8')
        self.assertIn('api.met.no', weather)
        self.assertNotIn('open-meteo.com', weather)

if __name__ == '__main__':
    unittest.main()
