from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V226MeasurementUiTest(unittest.TestCase):
    def test_home_wires_measurement_features(self):
        s=(ROOT/'lib/features/home/home_screen.dart').read_text()
        self.assertIn('ChronographScreen(profile: active!)', s)
        self.assertIn('SightHeightScreen(profile: active!)', s)
        self.assertIn('enabled: active != null && _activeProfileValid', s)
    def test_chronograph_is_truthful_manual_mode(self):
        s=(ROOT/'lib/features/chronograph/chronograph_screen.dart').read_text()
        self.assertIn('Mikrofon ölçümü henüz doğrulanmadı', s)
        self.assertIn('ChronographStatistics.from', s)
        self.assertIn('MeasurementStatus.valid', s)
    def test_sight_height_uses_validated_geometry(self):
        s=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
        self.assertIn('SightHeightGeometry.millimetersPerPixel', s)
        self.assertIn('SightHeightGeometry.measuredMillimeters', s)
        self.assertIn('Kamera ölçümü gerçek fotoğraflar ve cihaz üzerinde henüz doğrulanmadı', s)
if __name__ == '__main__': unittest.main()
