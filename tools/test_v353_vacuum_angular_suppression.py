import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/ballistics/ballistics_screen.dart'

class VacuumAngularSuppressionTest(unittest.TestCase):
    def setUp(self):
        self.text = SCREEN.read_text(encoding='utf-8')
        # M1: the Menzil shell splits the screen into Atış/Tablo/Ortam views, so the
        # old 'if (points.isNotEmpty)' slice no longer exists. The guard is now
        # applied to the WHOLE screen source (stricter than the former table slice).
        self.table = self.text

    def test_vacuum_table_does_not_render_angular_aiming_corrections(self):
        self.assertNotIn('displayCorrection', self.table)
        self.assertNotIn('displayWind', self.table)
        self.assertNotIn('p.correctionMoa', self.table)
        self.assertNotIn('p.correctionMrad', self.table)
        self.assertNotIn('p.windMrad', self.table)
        for forbidden in ('shot.correctionMrad', 'shot.correctionMoa', 'shot.windMrad', 'otherCorrection', 'MenzilReticle'):
            self.assertNotIn(forbidden, self.table)

    def test_vacuum_table_is_explicitly_descriptive_only(self):
        self.assertIn("'Vakum düşüşü cm*'", self.table)
        self.assertIn("'Vakum düşüşü in*'", self.table)
        self.assertIn('Açısal düzeltme (MIL/MRAD/MOA)', self.text)
        self.assertIn('Klik/tambur talimatı bu nedenle gösterilmez', self.text)

if __name__ == '__main__':
    unittest.main()
