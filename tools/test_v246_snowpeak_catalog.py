from pathlib import Path
import re
import unittest

TEXT = (Path(__file__).resolve().parents[1] / 'lib/data/catalog_repository.dart').read_text()
ENTRIES = re.findall(r"Rifle\(id:'snowpeak-[^\n]+", TEXT)

class SnowpeakCatalogTests(unittest.TestCase):
    def test_official_variants_unique_and_sourced(self):
        self.assertEqual(len(ENTRIES), 21)
        self.assertEqual(len(set(re.findall(r"id:'([^']+)'", '\n'.join(ENTRIES)))), 21)
        self.assertTrue(all("sourceName:'Snowpeak'" in e and 'snowpeaksports.com/series/details/' in e for e in ENTRIES))

    def test_max2_tb_capacity(self):
        entries = [e for e in ENTRIES if "id:'snowpeak-max2-tb-" in e]
        self.assertEqual(len(entries), 5)
        self.assertTrue(all('airCapacityCc:790' in e for e in entries))

    def test_no_co2_or_spring_mislabeled(self):
        self.assertFalse(any(x in e for e in ENTRIES for x in ['cr600', 'cr650', 'gr800', 'su1200']))
