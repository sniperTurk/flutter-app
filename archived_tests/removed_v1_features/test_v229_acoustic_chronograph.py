from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V229AcousticChronograph(unittest.TestCase):
    def test_core_and_tests_present(self):
        core=(ROOT/'lib/core/acoustic_chronograph.dart').read_text()
        test=(ROOT/'test/acoustic_chronograph_test.dart').read_text()
        self.assertIn('eventDeltaSeconds - soundReturn', core)
        self.assertIn('331.3 + (0.606 * temperatureC)', core)
        self.assertIn("velocity > 1500", core)
        self.assertIn('removes sound return time', test)
    def test_not_claimed_as_muzzle_velocity(self):
        core=(ROOT/'lib/core/acoustic_chronograph.dart').read_text()
        self.assertIn('average velocity estimate, not a muzzle-velocity measurement', core)
if __name__=='__main__': unittest.main()
