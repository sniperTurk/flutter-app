import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / 'lib/features/catalog/catalog_screen.dart'

class CatalogDetailContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SCREEN.read_text(encoding='utf-8')

    def test_all_three_catalog_collections_open_details(self):
        self.assertIn("key: Key('catalog-rifle-${x.id}')", self.text)
        self.assertIn("key: Key('catalog-ammunition-${x.id}')", self.text)
        self.assertIn("key: Key('catalog-scope-${x.id}')", self.text)
        self.assertEqual(3, self.text.count('onTap: () => _showDetails('))

    def test_detail_sheet_exposes_provenance_document(self):
        self.assertIn("Text('Veri kaynağı'", self.text)
        self.assertIn("SelectableText(sourceDocument)", self.text)
        self.assertIn("sourceName ?? 'Kaynak doğrulanmadı'", self.text)

    def test_scope_details_preserve_lower_bound_semantics(self):
        self.assertIn("scope.elevationRangeIsLowerBound ? '>' : ''", self.text)
        self.assertIn("scope.windageRangeIsLowerBound ? '>' : ''", self.text)

    def test_detail_sheet_is_scrollable_for_small_iphone_screens(self):
        self.assertIn('isScrollControlled: true', self.text)
        self.assertIn('SingleChildScrollView(', self.text)
        self.assertIn('SafeArea(', self.text)

if __name__ == '__main__':
    unittest.main()
