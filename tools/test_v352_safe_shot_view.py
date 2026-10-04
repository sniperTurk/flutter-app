import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/ballistics/ballistics_screen.dart'

class SafeShotViewTest(unittest.TestCase):
    def setUp(self):
        self.text = SCREEN.read_text(encoding='utf-8')

    def test_safe_shot_view_is_present_and_drag_locked(self):
        self.assertIn("'Atış görünümü'", self.text)
        self.assertIn('class _SafeReticlePainter', self.text)
        self.assertGreaterEqual(self.text.count("'KİLİTLİ'"), 2)
        self.assertIn('G1/G7 kabul testi bekleniyor', self.text)
        self.assertIn('düzeltme işareti merkeze kilitlidir', self.text)

    def test_safe_shot_view_does_not_restore_click_instruction(self):
        panel = self.text[self.text.index('Widget _referenceShotPanel()'):self.text.index('Widget _statusCard(')]
        self.assertNotIn('clicks(', panel)
        self.assertNotIn('klik', panel.lower())

if __name__ == '__main__':
    unittest.main()
