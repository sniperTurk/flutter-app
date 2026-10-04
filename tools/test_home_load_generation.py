import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "lib/features/home/home_screen.dart"

class HomeLoadGenerationTests(unittest.TestCase):
    def test_async_profile_load_is_generation_guarded(self):
        text = SOURCE.read_text(encoding="utf-8")
        self.assertIn("int _loadGeneration = 0;", text)
        self.assertIn("final generation = ++_loadGeneration;", text)
        self.assertGreaterEqual(text.count("generation != _loadGeneration"), 3)
        # The first stale-result guard must occur before active-id reconciliation
        # can write back to persistence, not only before setState.
        guard = text.index("generation != _loadGeneration")
        reconcile = text.index("await activeStore.setActiveProfileId(resolvedId)")
        self.assertLess(guard, reconcile)

if __name__ == "__main__":
    unittest.main()
