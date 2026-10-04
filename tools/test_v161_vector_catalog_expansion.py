import re, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
TEXT=(ROOT/'lib/data/catalog_repository.dart').read_text()
class V161VectorExpansion(unittest.TestCase):
  def test_new_official_vector_records(self):
    ids=['vector-continental-x6-6-36-scff93','vector-veyron-gen2-3-12-scff72','vector-veyron-gen2-4-16-scff78','vector-tauron-5-25-scff71','vector-tauron-4-16-scff80','vector-tauron-6-24-scff82','vector-sentinel-6-24-scff57','vector-sentinel-5-25-scff58','vector-orion-pro-max-6-24-scff44','vector-orion-pro-max-3-18-scol57','vector-continental-x6-3-18-scff43','vector-continental-1-6-scoc44']
    for i in ids:
      self.assertEqual(TEXT.count("id:'%s'"%i),1,i)
    self.assertGreaterEqual(TEXT.count("sourceName:'Vector Optics'"), 21)
  def test_scope_ids_unique(self):
    block=TEXT.split('static const scopes = <ScopeOptic>[',1)[1].split('];',1)[0]
    ids=re.findall(r"id:'([^']+)'",block)
    self.assertEqual(len(ids),len(set(ids)))
if __name__=='__main__': unittest.main()
