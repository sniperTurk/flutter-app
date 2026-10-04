from pathlib import Path
import json,unittest
ROOT=Path(__file__).resolve().parents[1]
class ImportTests(unittest.TestCase):
 def test_new_ids_unique(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text();import re
  ids=re.findall(r"(?:Rifle|Ammunition)\(id:'([^']+)'",s)
  self.assertEqual(len(ids),len(set(ids)))
 def test_archival_not_current(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  for name in ['av45-454-rb-137','av45-457-rb-143','av45-166-fp']:
   line=next(x for x in s.splitlines() if "id:'airventuri-"+name+"'" in x)
   self.assertIn('2017 archival',line);self.assertIn('availability unverified',line)
 def test_bb_not_misclassified(self):
  d=json.loads((ROOT/'catalog_sources/air_venturi_2026.json').read_text())
  self.assertTrue(all(x['status']=='excluded_until_BB_type_supported' for x in d['ammunition']['current_site']))
if __name__=='__main__':unittest.main()
