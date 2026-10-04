from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
TEXT=(ROOT/'lib/data/catalog_repository.dart').read_text()
class RossiCatalogTests(unittest.TestCase):
 def test_expected_records(self):
  ids=['rossi-outlander-55','rossi-outlander-635','rossi-trex-635','rossi-trex-bullpup-635','rossi-outlander-bullpup-55','rossi-outlander-bullpup-635','rossi-kodiak-635','rossi-kodiak-762','rossi-kodiak-90','rossi-dione-pcp-55','rossi-r35-bullpup-55','rossi-r35-bullpup-635']
  for i in ids:
   with self.subTest(i=i): self.assertEqual(TEXT.count("id:'"+i+"'"),1)
 def test_provenance_and_platform(self):
  for line in TEXT.splitlines():
   if "id:'rossi-" in line:
    self.assertIn("brand:'Rossi'",line); self.assertIn('platform:WeaponPlatform.pcp',line); self.assertIn("sourceName:'Rossi'",line); self.assertIn('verified 2026-10-02',line)
if __name__=='__main__': unittest.main()
