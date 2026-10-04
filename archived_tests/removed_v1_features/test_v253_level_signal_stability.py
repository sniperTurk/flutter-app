#!/usr/bin/env python3
"""Production guard for the spirit-level signal conditioning contract."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "lib/features/field_tools/field_tools_screen.dart"

class LevelSignalStabilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_level_filters_accelerometer_before_angle_calculation(self):
        self.assertIn("static const double _gravityFilterAlpha = 0.18;", self.source)
        self.assertIn("_x = _lowPass(_x, ex);", self.source)
        self.assertIn("_y = _lowPass(_y, ey);", self.source)
        self.assertIn("_z = _lowPass(_z, ez);", self.source)

    def test_non_finite_samples_fail_safe(self):
        self.assertIn("!ex.isFinite || !ey.isFinite || !ez.isFinite", self.source)
        self.assertIn("İvmeölçerden geçersiz örnek alındı.", self.source)

    def test_precision_disclosure_does_not_claim_sensor_accuracy(self):
        self.assertIn("0,01° ekran çözünürlüğüdür; ölçüm filtrelenir, sensör doğruluğu garantisi değildir.", self.source)

if __name__ == "__main__":
    unittest.main()
