import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/ballistics/ballistics_screen.dart'
VIEW = ROOT / 'lib/features/ballistics/scope_dial_view.dart'
CORE = ROOT / 'lib/core/scope_dial.dart'


class InteractiveScopeDialContract(unittest.TestCase):
    def setUp(self):
        self.screen = SCREEN.read_text(encoding='utf-8')
        self.view = VIEW.read_text(encoding='utf-8')
        self.core = CORE.read_text(encoding='utf-8')

    def test_static_reticle_replaced_by_interactive_view(self):
        self.assertNotIn('class _SafeReticlePainter', self.screen)
        self.assertIn('ScopeDialView(', self.screen)
        self.assertIn('elevationDrum', self.view)
        self.assertIn('windageDrum', self.view)

    def test_wind_is_never_claimed_as_a_computed_correction(self):
        # The vacuum solver has no wind model: required windage stays 0 and
        # the wind status card stays locked.
        self.assertNotIn('requiredRight:', self.view)
        self.assertNotIn('windMrad', self.view)
        self.assertNotIn('windMrad', self.screen.split('Widget _scopeDial(')[1].split('\n  }\n')[0])
        self.assertEqual(self.screen.count("'KİLİTLİ'"), 1)
        self.assertIn('rüzgâr etkisi', self.screen)

    def test_hold_labels_are_not_extrapolated_and_fail_closed(self):
        self.assertIn('never extrapolated', self.core)
        # No impact marker or labels without a validated solve.
        self.assertIn('final holds = req == null', self.view)
        self.assertIn('onPressed: req == null', self.view)

    def test_turret_travel_is_bounded_by_catalog_travel(self):
        self.assertIn('s.elevationRangeMrad', self.screen)
        self.assertIn('s.windageRangeMrad', self.screen)
        self.assertIn('.clamp(-widget.maxClicks, widget.maxClicks)', self.view)

    def test_unit_follows_the_scope_turret(self):
        self.assertIn('final unit = s.clickUnit;', self.screen)


if __name__ == '__main__':
    unittest.main()
