#!/usr/bin/env python3
"""Offline regression guard for catalog provenance wording."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/catalog/catalog_screen.dart"

class CatalogProvenanceUiTest(unittest.TestCase):
    def test_unsourced_rifle_is_never_labeled_verified(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertIn("Kaynak doğrulanmadı • Ayrıntılı teknik veri henüz yok.", text)
        self.assertNotIn("Doğrulanmış ayrıntılı teknik veri henüz yok.", text)

if __name__ == "__main__":
    unittest.main()
