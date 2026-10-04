import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'lib' / 'data' / 'catalog_repository.dart'

class AirMaksCatalogProvenanceTest(unittest.TestCase):
    def test_generic_krait_placeholder_is_replaced_by_current_s_variants(self):
        text = CATALOG.read_text(encoding='utf-8')
        self.assertNotIn("id:'airmaks-krait-635'", text)
        expected = {
            'airmaks-krait-s-635': ('Krait S', '14', '400', '300', '610', '2.5', '60'),
            'airmaks-krait-mkii-s-635': ('Krait MK2 S', '12', '400', '300', '640', '3.13', '30'),
        }
        for rid, values in expected.items():
            with self.subTest(rid=rid):
                line = next((ln for ln in text.splitlines() if f"id:'{rid}'" in ln), '')
                self.assertTrue(line, f'missing {rid}')
                model, mag, barrel, air, length, weight, plenum = values
                for fragment in (
                    f"model:'{model}'", f'magazineCapacity:{mag}', f'barrelLengthMm:{barrel}',
                    f'airCapacityCc:{air}', f'overallLengthMm:{length}', f'weightKg:{weight}',
                    f'plenumCc:{plenum}', "sourceName:'AirMaks Arms'", 'verified 2026-09-27',
                ):
                    self.assertIn(fragment, line)

if __name__ == '__main__':
    unittest.main()
