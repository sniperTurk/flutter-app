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
        start = self.screen.index('Widget _scopeDial(')
        self.dial = self.screen[start:self.screen.index('\n  }\n', start)]

    def test_static_reticles_replaced_by_interactive_view(self):
        self.assertNotIn('class _SafeReticlePainter', self.screen)
        self.assertNotIn('class _HoldReticlePainter', self.screen)
        self.assertIn('ScopeDialView(', self.dial)
        self.assertIn('elevationDrum', self.view)
        self.assertIn('windageDrum', self.view)

    def test_required_windage_only_from_the_drag_solver(self):
        # The vacuum baseline has no wind model: its required windage is 0
        # and its wind card stays locked.
        self.assertIn('!basis.drag', self.dial)
        self.assertIn('? 0.0', self.dial)
        self.assertIn('shot.windMrad', self.dial)
        self.assertEqual(self.screen.count("'KİLİTLİ'"), 1)

    def test_crosswind_labels_come_from_the_solver(self):
        self.assertIn('_evalShot().mpsPerMil', self.dial)
        self.assertIn('basis.drag', self.dial)

    def test_hold_labels_are_not_extrapolated_and_fail_closed(self):
        self.assertIn('never extrapolated', self.core)
        self.assertIn('final holds = req == null', self.view)
        self.assertIn('onPressed: req == null', self.view)

    def test_turret_travel_is_bounded_by_catalog_travel(self):
        self.assertIn('s.elevationRangeMrad', self.dial)
        self.assertIn('s.windageRangeMrad', self.dial)
        self.assertIn('.clamp(-widget.maxClicks, widget.maxClicks)', self.view)

    def test_unit_follows_the_profile_unit(self):
        # V374: the profile's "Dürbün birimi" decides reticle and turret unit.
        self.assertIn('final unit = _scopeUnit;', self.dial)
        self.assertIn('widget.profile?.angularUnit ?? scope?.clickUnit', self.screen)


if __name__ == '__main__':
    unittest.main()
