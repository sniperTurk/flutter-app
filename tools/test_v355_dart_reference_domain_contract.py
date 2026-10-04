import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / 'tools' / 'compare_reference_vectors.dart'

class DartReferenceDomainContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src = DART.read_text(encoding='utf-8')

    def test_positive_physical_inputs_are_fail_closed(self):
        for needle in (
            "_positiveNumber(c['bc'], '$id.bc')",
            "_positiveNumber(c['mv'], '$id.mv')",
            "_positiveNumber(c['grain'], '$id.grain')",
            "_positiveNumber(c['zero'], '$id.zero')",
            "_positiveNumber(c['sight_mm'], '$id.sight_mm')",
            "_positiveNumber(p['range_m'], '$id.range_m')",
            "_positiveNumber(ref['velocity_mps'], '$id[$i].velocity_mps')",
            "_positiveNumber(ref['time_s'], '$id[$i].time_s')",
        ):
            self.assertIn(needle, self.src)

    def test_atmosphere_and_range_order_are_fail_closed(self):
        self.assertIn("pressureHpa <= 0", self.src)
        self.assertIn("humidityPercent < 0 || humidityPercent > 100", self.src)
        self.assertIn("ranges must be strictly increasing", self.src)

    def test_duplicate_case_ids_are_rejected(self):
        self.assertIn("duplicate case id", self.src)

if __name__ == '__main__':
    unittest.main()
