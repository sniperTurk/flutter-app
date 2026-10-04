from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CATALOG = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')


class FxCurrentLineupExpansionTests(unittest.TestCase):
    def _row(self, rifle_id: str) -> str:
        match = re.search(r"Rifle\(id:'" + re.escape(rifle_id) + r"'.*?\),", CATALOG)
        self.assertIsNotNone(match, f'{rifle_id} catalog record is missing')
        return match.group(0)

    def test_current_fx_25_models_have_manufacturer_provenance(self):
        expected = {
            'fx-leopard-635': ("model:'Leopard'", 'caliberMm:6.35', 'airCapacityCc:890', 'plenumCc:54', "barrelType:'APB barrel with FX interchangeable liner system'"),
            'fx-panthera-mkii-635': ("model:'Panthera MKII'", 'caliberMm:6.35', "rail:'30 MOA extended scope rail + full-length ARCA + M-LOK'"),
            'fx-dynamic-mkii-635': ("model:'Dynamic MKII'", 'caliberMm:6.35', "rail:'30 MOA extended scope rail + full-length ARCA + M-LOK'"),
        }
        for rifle_id, fields in expected.items():
            with self.subTest(rifle_id=rifle_id):
                row = self._row(rifle_id)
                for field in fields:
                    self.assertIn(field, row)
                self.assertIn("sourceName:'FX Airguns'", row)
                self.assertIn('official product page, verified 2026-09-29', row)
                self.assertEqual(CATALOG.count("id:'" + rifle_id + "'"), 1)

    def test_new_fx_records_do_not_invent_unpublished_numeric_specs(self):
        # The current manufacturer pages expose no stable variant data sheet in
        # their static response for Panthera/Dynamic MKII. Keep unknown values
        # absent rather than filling the catalog from reseller/speculation data.
        for rifle_id in ('fx-panthera-mkii-635', 'fx-dynamic-mkii-635'):
            row = self._row(rifle_id)
            for field in ('magazineCapacity:', 'barrelLengthMm:', 'airCapacityCc:', 'overallLengthMm:', 'weightKg:', 'plenumCc:'):
                self.assertNotIn(field, row)


if __name__ == '__main__':
    unittest.main()
