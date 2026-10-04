import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIELD = ROOT / 'lib/features/field_tools/field_tools_screen.dart'
HOME = ROOT / 'lib/features/home/home_screen.dart'
PUB = ROOT / 'pubspec.yaml'

class FieldToolsPrecisionUiTest(unittest.TestCase):
    def test_field_tools_reachable_and_dependencies_declared(self):
        field = FIELD.read_text(encoding='utf-8'); home = HOME.read_text(encoding='utf-8'); pub = PUB.read_text(encoding='utf-8')
        self.assertIn('class CompassScreen', field); self.assertIn('class SpiritLevelScreen', field)
        self.assertIn('const CompassScreen()', home); self.assertIn('const SpiritLevelScreen()', home)
        self.assertIn('flutter_compass:', pub); self.assertIn('sensors_plus:', pub)

    def test_level_precision_contract(self):
        field = FIELD.read_text(encoding='utf-8')
        for token in ("roll.toStringAsFixed(2)", "pitch.toStringAsFixed(2)", 'roll.abs() <= 0.01', 'pitch.abs() <= 0.01', '0,01° ekran çözünürlüğüdür', 'sensör doğruluğu garantisi değildir'):
            self.assertIn(token, field)

    def test_sensor_streams_are_disposed(self):
        self.assertGreaterEqual(FIELD.read_text(encoding='utf-8').count('_subscription?.cancel()'), 2)

if __name__ == '__main__': unittest.main()
