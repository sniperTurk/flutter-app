import unittest
from pathlib import Path
from dart_library_source import library_text

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/ballistics/ballistics_screen.dart'

class SafeShotViewTest(unittest.TestCase):
    def setUp(self):
        self.text = library_text(SCREEN)

    def test_safe_shot_view_is_present_and_drag_locked(self):
        # The title moved to the top bar (owner, 2026-10-08); since
        # 2026-10-15 the Hedef page is titled "Hedef", not "Atış Çözümü".
        home = (ROOT / 'lib/features/home/home_screen.dart').read_text(encoding='utf-8')
        self.assertIn("_tabShot: 'Hedef',", home)
        self.assertIn('title: _titles[tab],', home)
        self.assertNotIn("'Atış Çözümü'", home)
        # V372: the static reticle painters were replaced by the interactive
        # turret/reticle view (scope_dial_view.dart); see test_v372.
        self.assertIn('_scopeDial(shot)', self.text)
        # The Yukarı/Aşağı and Rüzgâr boxes were removed from Atış (owner,
        # 2026-10-08). The vacuum notice still says wind is locked.
        self.assertNotIn("'KİLİTLİ'", self.text)
        self.assertIn('Rüzgâr düzeltmesi hiç modellenmez (KİLİTLİ)', self.text)

    def test_wind_status_card_was_removed(self):
        # Owner, 2026-10-08: no separate wind/elevation boxes on Atış; the
        # scope dial (drag-gated windage) is the only place wind is shown.
        self.assertNotIn('Widget _windStatusCard', self.text)
        self.assertNotIn("Key('wind-status-card')", self.text)
        self.assertNotIn("Key('elevation-status-card')", self.text)

if __name__ == '__main__':
    unittest.main()
