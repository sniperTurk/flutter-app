from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class SightHeightConsistencyTest(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / 'lib/features/sight_height/sight_height_screen.dart').read_text()
    def test_edit_invalidates_previous_result_and_approval(self):
        self.assertEqual(self.source.count('onChanged: (_) => _invalidateCalculation()'), 3)
        self.assertIn('userConfirmed = false;', self.source)
        self.assertIn('perspectiveValidated = false;', self.source)
        self.assertIn('resultMm = null;', self.source)
    def test_save_uses_calculation_snapshot_not_mutable_inputs(self):
        self.assertIn('referenceLengthMm: calculatedReferenceMm', self.source)
        self.assertIn('referencePixels: calculatedReferencePx', self.source)
        self.assertIn('if (saving || resultMm == null', self.source)
        self.assertIn('onPressed: saving ? null : _save', self.source)
if __name__ == '__main__': unittest.main()
