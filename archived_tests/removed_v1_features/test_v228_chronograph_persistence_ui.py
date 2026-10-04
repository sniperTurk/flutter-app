import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class V228ChronographPersistenceUiTest(unittest.TestCase):
    def test_save_action_is_reachable_and_visible(self):
        src = (ROOT / 'lib/features/chronograph/chronograph_screen.dart').read_text()
        self.assertIn('onPressed: saving ? null : _saveSession', src)
        self.assertIn("label: Text(saving ? 'Kaydediliyor…' : 'Oturumu kaydet')", src)
        self.assertIn('if (saveMessage != null)', src)
        self.assertIn('await store.saveChronographSession(session)', src)

    def test_save_is_single_flight_and_success_starts_fresh_session(self):
        src = (ROOT / 'lib/features/chronograph/chronograph_screen.dart').read_text()
        self.assertIn('if (readings.isEmpty || saving) return;', src)
        self.assertIn('saving = true', src)
        self.assertIn('readings.clear();', src)
        self.assertIn('saving = false', src)

if __name__ == '__main__':
    unittest.main()
