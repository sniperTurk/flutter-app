import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
CAT=(ROOT/'lib/data/catalog_repository.dart').read_text()

class ReximexCatalogV307Test(unittest.TestCase):
    def test_expected_official_records_present(self):
        models=['meta','tormenta','meta-premium','tormenta-lite','accura','nyx','lyra-bp','accura-carbon','lieva','lyra-k']
        for model in models:
            for cal in ['45','55','635']:
                rid=f"reximex-{model}-{cal}"
                self.assertEqual(CAT.count(f"id:'{rid}'"),1,rid)
        self.assertEqual(CAT.count("brand:'Reximex'"),30)
    def test_all_reximex_records_are_pcp_and_manufacturer_sourced(self):
        lines=[line for line in CAT.splitlines() if "brand:'Reximex'" in line]
        self.assertEqual(len(lines),30)
        for line in lines:
            self.assertIn('platform:WeaponPlatform.pcp',line)
            self.assertIn("sourceName:'Reximex'",line)
            self.assertIn('reximex.com/',line)
            self.assertIn('official manufacturer page',line)
    def test_caliber_distribution(self):
        lines=[line for line in CAT.splitlines() if "brand:'Reximex'" in line]
        for mm in ['4.5','5.5','6.35']:
            self.assertEqual(sum(f'caliberMm:{mm}' in line for line in lines),10)

if __name__=='__main__': unittest.main()
