import json
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class SamOpticsSourceTest(unittest.TestCase):
    def test_source_is_registered_without_unverified_products(self):
        source = json.loads((ROOT / 'catalog_sources/sam_optics.json').read_text())
        self.assertEqual(source['url'], 'https://samoptics.com/')
        self.assertEqual(source['status'], 'pending_source_verification')
        self.assertEqual(source['verified_products'], [])

    def test_unverified_sam_products_not_in_production_catalog(self):
        catalog = (ROOT / 'lib/data/catalog_repository.dart').read_text()
        self.assertNotIn("sourceName:'SAM Optics'", catalog)
        self.assertNotIn('sam-optics-', catalog)

if __name__ == '__main__':
    unittest.main()
