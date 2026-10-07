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
        # V354: elevation is unlocked (vacuum-model estimate); only the WIND
        # status card still reads 'KİLİTLİ', so exactly one literal remains.
        self.assertEqual(self.text.count("'KİLİTLİ'"), 1)
        self.assertIn('Drag doğrulaması bekleniyor', self.text)
        self.assertIn('merkeze kilitlidir', self.text)

    def test_wind_status_card_never_shows_a_click_or_numeric_value(self):
        # Scope the check to the wind _statusCard call specifically (the one
        # titled 'Rüzgâr'), not the whole reference-shot panel: that panel's
        # ELEVATION card is now allowed, by design, to show a real klik value.
        # V355: the card has a vacuum branch (locked) and a drag branch; the
        # locked branch is everything before the drag branch begins.
        start = self.text.index('Widget _windStatusCard')
        start = self.text.index("title: 'Rüzgâr',", start)
        end = self.text.index('if (shot == null) {', start)
        wind_card = self.text[start:end]
        self.assertIn("'KİLİTLİ'", wind_card)
        self.assertNotIn('klik', wind_card.lower())
        self.assertNotIn('clicks(', wind_card)

if __name__ == '__main__':
    unittest.main()
