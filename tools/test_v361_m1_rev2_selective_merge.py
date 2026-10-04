import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class V361SelectiveMergeTests(unittest.TestCase):
    def test_compass_has_turkish_spoken_semantics_without_losing_kdgb(self):
        math = (ROOT/'lib/tools/domain/compass_math.dart').read_text(encoding='utf-8')
        screen = (ROOT/'lib/features/tools/compass_screen.dart').read_text(encoding='utf-8')
        self.assertIn('cardinal16Spoken', math)
        self.assertIn("'K', 'KKD', 'KD', 'DKD', 'D', 'DGD', 'GD', 'GGD'", math)
        self.assertIn('CompassMath.cardinal16Spoken(degrees)', screen)
        self.assertIn("{0: 'K', 90: 'D', 180: 'G', 270: 'B'}", screen)

    def test_sight_height_keeps_v360_safety_and_adds_voiceover_hint(self):
        src = (ROOT/'lib/features/tools/sight_height_screen.dart').read_text(encoding='utf-8')
        for token in ('sight-muzzle-warning', 'sight-inclined-mount', 'sight-not-landscape', 'minWidth: 44', 'VoiceOver ile hassas işaretleme zordur'):
            self.assertIn(token, src)

    def test_chronograph_optional_pressure_write_uses_validated_update_path(self):
        chrono = (ROOT/'lib/features/tools/chronograph_screen.dart').read_text(encoding='utf-8')
        support = (ROOT/'lib/features/tools/tool_support.dart').read_text(encoding='utf-8')
        for token in ('chrono-start-bar', 'chrono-end-bar', 'chrono-write-pressure', '_pressureDropBar', '_validStartPressureBar'):
            self.assertIn(token, chrono)
        self.assertIn('pressureBar: pick.writePressure ? _validStartPressureBar : null', chrono)
        self.assertIn('double? pressureBar', support)
        self.assertIn('pressureText: (pressureBar ?? base.pressureBar)?.toString()', support)

if __name__ == '__main__':
    unittest.main()
