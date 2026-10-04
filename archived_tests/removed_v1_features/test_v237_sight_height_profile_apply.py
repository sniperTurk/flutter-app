from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
SRC=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
class V237(unittest.TestCase):
 def test_profile_apply_is_wired(self):
  self.assertIn('final ProfileStore profileStore = PersistentProfileStore();', SRC)
  self.assertIn('await profileStore.save(RifleProfile(', SRC)
  self.assertIn('sightHeightMm: measured', SRC)
 def test_fail_closed_range(self):
  self.assertIn('ProductionLimits.maxSightHeightMm', SRC)
  self.assertIn('result <= 0', SRC)
 def test_evidence_precedes_profile_mutation(self):
  self.assertLess(SRC.index('await store.saveSightHeightMeasurement'), SRC.index('await profileStore.save(RifleProfile('))
if __name__=='__main__': unittest.main()
