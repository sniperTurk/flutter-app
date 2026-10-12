#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
# The manual-record dialog was removed with the unreachable catalog screen;
# the platform gate is enforced at the persistence boundary.
SOURCE = ROOT / 'lib/services/manual_catalog_store.dart'

class ManualCatalogAmmoPlatformGateTest(unittest.TestCase):
    def test_manual_ammunition_type_is_platform_gated(self):
        text = SOURCE.read_text(encoding='utf-8')
        self.assertIn("(platform == 'firearm' && ammoType != 'bullet')", text)
        self.assertIn("(platform == 'pcp' && ammoType == 'bullet')", text)
        self.assertIn("Invalid ammunition type for platform", text)

if __name__ == '__main__':
    unittest.main()
