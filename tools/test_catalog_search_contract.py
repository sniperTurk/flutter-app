from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / 'lib/core/catalog_search.dart'
SCREEN = ROOT / 'lib/features/catalog/catalog_screen.dart'
DART_TEST = ROOT / 'test/catalog_search_test.dart'

class CatalogSearchContractTest(unittest.TestCase):
    def test_catalog_screen_uses_shared_search_contract(self):
        source = SCREEN.read_text(encoding='utf-8')
        self.assertIn("import '../../core/catalog_search.dart';", source)
        self.assertIn('CatalogSearch.matches(value, query)', source)
        self.assertNotIn('value.toLowerCase().contains(query.toLowerCase())', source)

    def test_turkish_ascii_folding_is_explicit(self):
        source = CORE.read_text(encoding='utf-8')
        for pair in ("'ç': 'c'", "'ğ': 'g'", "'ı': 'i'", "'İ': 'i'", "'ö': 'o'", "'ş': 's'", "'ü': 'u'"):
            self.assertIn(pair, source)

    def test_search_is_order_independent_by_terms(self):
        source = CORE.read_text(encoding='utf-8')
        self.assertIn(".split(' ')", source)
        self.assertIn('.every(normalizedHaystack.contains)', source)

    def test_flutter_regression_examples_are_committed(self):
        source = DART_TEST.read_text(encoding='utf-8')
        self.assertIn("CatalogSearch.matches('Huğlu Spark', 'huglu')", source)
        self.assertIn("CatalogSearch.matches('HATSAN Hercules 6.35', '6.35 hatsan')", source)

if __name__ == '__main__':
    unittest.main()
