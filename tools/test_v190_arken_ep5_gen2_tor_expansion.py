import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'lib/data/catalog_repository.dart'


class ArkenEp5Gen2TorExpansionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = CATALOG.read_text(encoding='utf-8')

    def _record(self, scope_id):
        match = re.search(r"ScopeOptic\(\s*id:'" + re.escape(scope_id) + r"'.*?\),", self.text, re.S)
        self.assertIsNotNone(match, scope_id)
        return match.group(0)

    def test_7_35_tor_mil_matches_current_official_product_page(self):
        record = self._record('arken-ep5-gen2-7-35-tor-mil')
        for field in (
            "model:'EP-5 GENII 7–35×56 FFP TOR (MRAD)'", 'objectiveDiameterMm:56',
            'clickValue:0.1', 'clickUnit:AngularUnit.mrad', 'tubeDiameterMm:34',
            'minMagnification:7', 'maxMagnification:35', 'elevationRangeMrad:30',
            'windageRangeMrad:15', 'lengthMm:406.4', 'weightG:1190.68',
            'firstFocalPlane:true', 'zeroStop:true', "reticle:'TOR-MIL'",
            "sourceName:'Arken Optics USA'", 'verified 2026-09-28',
        ):
            self.assertIn(field, record)

    def test_5_25_tor_mil_matches_current_official_product_page(self):
        record = self._record('arken-ep5-gen2-5-25-tor-mil')
        for field in (
            "model:'EP-5 GENII 5–25×56 FFP TOR (MRAD)'", 'objectiveDiameterMm:56',
            'clickValue:0.1', 'clickUnit:AngularUnit.mrad', 'tubeDiameterMm:34',
            'minMagnification:5', 'maxMagnification:25', 'elevationRangeMrad:28',
            'windageRangeMrad:12', 'lengthMm:396.24', 'weightG:1168.0',
            'firstFocalPlane:true', 'zeroStop:true', "reticle:'TOR-MIL'",
            "sourceName:'Arken Optics USA'", 'verified 2026-09-28',
        ):
            self.assertIn(field, record)

    def test_ep5_genii_7_35_vpr_name_and_provenance_are_current(self):
        record = self._record('arken-ep5')
        self.assertIn("model:'EP-5 GENII 7–35×56 FFP VPR (MRAD)'", record)
        self.assertNotIn('GEN2 7–35', record)
        self.assertIn('verified 2026-09-28', record)

    def test_scope_ids_remain_unique(self):
        ids = re.findall(r"ScopeOptic\(\s*id:'([^']+)'", self.text)
        self.assertEqual(len(ids), len(set(ids)))


if __name__ == '__main__':
    unittest.main()
