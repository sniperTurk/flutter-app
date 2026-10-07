import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/ballistics/ballistics_screen.dart'

class VacuumAngularSuppressionTest(unittest.TestCase):
    """V354 superseded the blanket angular-suppression gate for ELEVATION
    only: `correctionMoa`/`correctionMrad` are valid vacuum trigonometry and
    are now rendered (DOPE table + reference shot panel), with an explicit
    live-fire-confirmation disclaimer. WIND (`windMrad`) must still never be
    rendered: the vacuum model has no aerodynamic coupling to produce a real
    wind value, so that half of the original gate still applies.
    """

    def setUp(self):
        self.text = SCREEN.read_text(encoding='utf-8')

    def test_wind_mrad_is_never_rendered(self):
        for forbidden in ('p.windMrad', 'shot.windMrad', 'otherCorrection', 'MenzilReticle'):
            self.assertNotIn(forbidden, self.text)
        # windMrad is only referenced in the explanatory comment, never
        # passed to a widget/formatter.
        self.assertNotIn('windMrad.toStringAsFixed', self.text)

    def test_elevation_angular_correction_is_now_rendered_with_disclaimers(self):
        self.assertIn('p.correctionMoa.toStringAsFixed(2)', self.text)
        self.assertIn('p.correctionMrad.toStringAsFixed(2)', self.text)
        self.assertIn("'Yükseklik MOA*'", self.text)
        self.assertIn("'Yükseklik mrad*'", self.text)

    def test_dead_code_display_helpers_were_not_reintroduced(self):
        self.assertNotIn('displayCorrection', self.text)
        self.assertNotIn('displayWind', self.text)

if __name__ == '__main__':
    unittest.main()
