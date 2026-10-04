from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / 'lib/services/manual_catalog_store.dart').read_text(encoding='utf-8')

class ManualCatalogIdentityValidationTest(unittest.TestCase):
    def test_brand_is_required_not_merely_a_string(self):
        self.assertIn("for (final field in ['id', 'brand', 'model'])", SRC)
        self.assertIn("value.trim().isEmpty", SRC)

    def test_identity_fields_have_bounded_length(self):
        self.assertIn("value.length > 100", SRC)
        self.assertIn("for (final field in ['id', 'brand', 'model'])", SRC)

if __name__ == '__main__':
    unittest.main()
