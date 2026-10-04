import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'lib' / 'data' / 'catalog_repository.dart'


class AeaCatalogProvenanceTest(unittest.TestCase):
    def test_challenger_pro_635_is_no_longer_an_unsourced_stub(self):
        text = CATALOG.read_text(encoding='utf-8')
        line = next((ln for ln in text.splitlines() if "id:'aea-challenger-pro-635'" in ln), '')
        self.assertTrue(line, 'missing AEA Challenger Pro 6.35 record')
        for fragment in (
            "model:'Challenger Pro'",
            'magazineCapacity:10',
            'barrelLengthMm:610',
            'airCapacityCc:350',
            'overallLengthMm:840',
            'weightKg:3.72',
            "rail:'Picatinny/Weaver'",
            "sourceName:'Airgun Armoury'",
            'verified 2026-09-27',
        ):
            self.assertIn(fragment, line)
        self.assertNotIn("sourceName:'AEA'", line)


if __name__ == '__main__':
    unittest.main()
