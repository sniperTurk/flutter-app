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

    def test_wind_mrad_is_rendered_only_in_drag_mode(self):
        # Gate opened in V355: wind comes only from the validated drag solver.
        for forbidden in ('otherCorrection', 'MenzilReticle'):
            self.assertNotIn(forbidden, self.text)
        # The table cell is inside the `if (drag)` branch of the row.
        self.assertEqual(self.text.count('p.windMrad'), 1)
        idx = self.text.index('p.windMrad')
        self.assertIn('if (drag)', self.text[max(0, idx - 120):idx])
        # Two readers of shot.windMrad, both drag-only:
        # 1. the status card, after the vacuum early return
        #    (`if (!_dragMode) { ... KİLİTLİ ... return }`);
        # 2. V372 interactive scope: required windage is 0.0 unless the
        #    basis is a drag solve.
        self.assertEqual(self.text.count('shot.windMrad'), 2)
        card = self.text.index('Widget _windStatusCard(')
        card_read = self.text.index('shot.windMrad', card)
        self.assertLess(self.text.index('if (!_dragMode) {', card), card_read)
        dial = self.text.index('Widget _scopeDial(')
        dial_read = self.text.index('shot.windMrad', dial)
        guard = self.text[dial:dial_read]
        self.assertIn('!basis.drag', guard)
        self.assertIn('? 0.0', guard)

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
