from pathlib import Path
import json, unittest
ROOT=Path(__file__).resolve().parents[1]
class AirVenturiTests(unittest.TestCase):
 def test_current_verified_rifle(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  matches=[line for line in s.splitlines() if "Rifle(id:'airventuri-" in line]
  self.assertGreaterEqual(len(matches),16)
  self.assertTrue(any('caliberMm:12.7' in m for m in matches)); self.assertTrue(all('airventuri.com/products/' in m for m in matches))
 def test_staged_not_mislabeled_active(self):
  data=json.loads((ROOT/'catalog_sources/air_venturi_2026.json').read_text())
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  self.assertEqual(len(data['staged_rifles_needing_variant_specs']),17)
  self.assertTrue(all("brand:'DNT Optics'" not in line for line in s.splitlines() if "Rifle(id:'airventuri-" in line))
  self.assertEqual(data['ammunition']['status'],'staged_not_current')
 def test_no_unverified_ballistic_ammo(self):
  s=(ROOT/'lib/data/catalog_repository.dart').read_text()
  self.assertNotIn("Ammunition(id:'airventuri-steel-bb",s)
if __name__=='__main__': unittest.main()
