import re
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class V224CatalogExpansion(unittest.TestCase):
 def test_three_distinct_mevzi_variants(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  for suffix,capacity in [('ii',1160),('iii',1740),('iv',2320)]:
   self.assertRegex(s,rf"id:'hatsan-blitz-mevzi-{suffix}-635'[^\n]*airCapacityCc:{capacity}")
 def test_moa_scope_variant(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  self.assertIn("id:'discovery-xed-moa'",s)
  self.assertRegex(s,r"id:'discovery-xed-moa'[\s\S]*?clickValue:0.25, clickUnit:AngularUnit.moa")
 def test_unique_ids(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  ids=re.findall(r"\bid:'([^']+)'",s)
  self.assertEqual(len(ids),len(set(ids)))
if __name__=='__main__':unittest.main()
