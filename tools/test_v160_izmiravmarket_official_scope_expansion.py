import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')

class IzmirAvMarketOfficialScopeExpansionTests(unittest.TestCase):
    def test_new_official_scope_records_present(self):
        expected = {
            'sightmark-latitude-6-25-25-prs': ['brand:\'Sightmark\'', 'elevationRangeMrad:31', 'windageRangeMrad:20', 'zeroStop:true'],
            'vector-continental-x6-4-24-mbr-scff40': ['elevationRangeMrad:34', 'windageRangeMrad:16', 'weightG:841', "sourceName:'Vector Optics'"],
            'vector-orion-max-3-18-scff49': ['elevationRangeMrad:30', 'windageRangeMrad:16', 'weightG:798', "reticle:'VOR-4 MIL'"],
            'vector-veyron-4-16-scff22': ['elevationRangeMrad:17.5', 'windageRangeMrad:17.5', 'weightG:530', "reticle:'MPR-4 MIL'"],
        }
        for scope_id, markers in expected.items():
            start = CATALOG.index(f"id:'{scope_id}'")
            block = CATALOG[start:CATALOG.index('    ),', start)+6]
            for marker in markers:
                self.assertIn(marker, block, f'{scope_id} missing {marker}')
            self.assertIn('verified 2026-09-27', block)

    def test_scope_ids_remain_unique(self):
        scope_region = CATALOG[CATALOG.index('static const scopes'):]
        ids = re.findall(r"id:'([^']+)'", scope_region)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(len(ids), 39)

if __name__ == '__main__':
    unittest.main()
