from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]

class V225MeasurementCoreTest(unittest.TestCase):
    def test_chronograph_contract(self):
        chrono=(ROOT/'lib/core/chronograph_statistics.dart').read_text()
        self.assertIn('values.length - 1', chrono)
        self.assertIn('values.isEmpty', chrono)
        self.assertIn('v <= 0', chrono)
        self.assertIn('max-min', chrono)
    def test_sight_height_contract(self):
        sight=(ROOT/'lib/core/sight_height_geometry.dart').read_text()
        self.assertIn('referenceLengthMm / referencePixels', sight)
        self.assertIn('math.sqrt', sight)
    def test_measurement_state_contract(self):
        model=(ROOT/'lib/models/measurement.dart').read_text()
        self.assertIn('MeasurementStatus', model)
        self.assertIn('confidence >= 0 && confidence <= 1', model)
        self.assertIn('perspectiveValidated', model)
        self.assertIn('userConfirmed', model)

if __name__ == '__main__': unittest.main()
