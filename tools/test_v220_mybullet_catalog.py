import csv
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class MyBulletCatalogTests(unittest.TestCase):
 def test_brand_unique_and_sourced(self):
  with (ROOT/'data/global_pcp_ammunition_brands.csv').open(encoding='utf-8',newline='') as f: rows=list(csv.DictReader(f))
  self.assertEqual(len([r for r in rows if r['brand_id']=='my-bullet']),1)
  self.assertEqual(len({r['brand_id'] for r in rows}),len(rows))
  self.assertEqual(next(r for r in rows if r['brand_id']=='my-bullet')['verification_status'],'manufacturer_website_verified')
 def test_four_pcp_models_with_manufacturer_provenance(self):
  text=(ROOT/'lib/data/catalog_repository.dart').read_text(encoding='utf-8')
  for grain in (32,38,45,60):
   self.assertIn(f"id:'mybullet-hp-635-{grain}'",text)
   self.assertIn(f"6.35 mm {grain} grain Hollow Point Slug",text)
  self.assertEqual(text.count("id:'mybullet-hp-635-"),4)
  self.assertNotIn("id:'mybullet-pellet-55",text)
if __name__=='__main__': unittest.main()
