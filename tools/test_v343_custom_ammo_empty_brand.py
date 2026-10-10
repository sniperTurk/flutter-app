import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / 'lib/services/manual_catalog_store.dart').read_text(encoding='utf-8')


class CustomAmmoEmptyBrandTest(unittest.TestCase):
    def test_store_accepts_an_empty_brand_only_for_custom_ammunition(self):
        self.assertIn("field == 'brand' && kind == 'custom_ammunition'", STORE)
        self.assertTrue(re.search(r"\(!mayBeEmpty && value\.trim\(\)\.isEmpty\)", STORE))

    def test_length_and_type_limits_still_apply_to_every_identity_field(self):
        self.assertIn("value is! String", STORE)
        self.assertIn("value.length > 100", STORE)


if __name__ == '__main__':
    unittest.main()
