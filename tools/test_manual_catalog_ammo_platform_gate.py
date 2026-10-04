#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
# The manual-record form lives in its own lifecycle-owned dialog widget.
SOURCE = ROOT / 'lib/features/catalog/manual_catalog_dialog.dart'

class ManualCatalogAmmoPlatformGateTest(unittest.TestCase):
    def test_manual_ammunition_type_is_platform_gated(self):
        text = SOURCE.read_text(encoding='utf-8')
        self.assertIn("selectedPlatform == 'firearm' ? const ['bullet'] : const ['pellet', 'slug']", text)
        self.assertIn("ammoType = selectedPlatform == 'firearm' ? 'bullet' : 'pellet';", text)
        self.assertIn("selectedPlatform == 'firearm' ? 'bullet' : (ammoType == 'bullet' ? 'pellet' : ammoType)", text)
    def test_ammo_type_dropdown_is_rebuilt_when_platform_changes(self):
        text = SOURCE.read_text(encoding='utf-8')
        self.assertIn("key: ValueKey('ammo-type-$selectedPlatform')", text)

if __name__ == '__main__':
    unittest.main()
