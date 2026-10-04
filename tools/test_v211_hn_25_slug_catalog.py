from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEXT = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')

EXPECTED = {
    'hn-slug-hp2-25-28': 28,
    'hn-slug-hp2-25-30': 30,
    'hn-slug-hp2-25-32': 32,
    'hn-slug-hp2-25-34': 34,
    'hn-slug-hp2-25-36': 36,
    'hn-heavy-slug-25-38': 38,
    'hn-heavy-slug-25-42': 42,
    'hn-heavy-slug-25-44': 44,
    'hn-heavy-slug-25-46': 46,
    'hn-heavy-slug-25-48': 48,
}

class Hn25SlugCatalogTest(unittest.TestCase):
    def _row(self, record_id):
        match = re.search(r"Ammunition\(id:'" + re.escape(record_id) + r"'[^\n]+", TEXT)
        self.assertIsNotNone(match, record_id)
        return match.group(0)

    def test_current_hn_25_slug_weights_have_manufacturer_provenance(self):
        for record_id, grain in EXPECTED.items():
            row = self._row(record_id)
            self.assertIn("brand:'H&N Sport'", row)
            self.assertIn('caliberMm:6.35', row)
            self.assertIn(f'grain:{grain}', row)
            self.assertIn('type:AmmunitionType.slug', row)
            self.assertIn("sourceName:'H&N Sport'", row)
            self.assertIn('verified 2026-09-29', row)

    def test_hn_bc_is_not_imported_without_published_drag_model(self):
        for record_id in EXPECTED:
            row = self._row(record_id)
            self.assertNotIn('ballisticCoefficient:', row)
            self.assertNotIn('ballisticModel:', row)

if __name__ == '__main__':
    unittest.main()
