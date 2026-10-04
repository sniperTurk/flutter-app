#!/usr/bin/env python3
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class V214ProfileOptionalFieldFailClosed(unittest.TestCase):
    def test_present_invalid_optional_fields_are_rejected(self):
        src=(ROOT/'lib/services/profile_codec.dart').read_text(encoding='utf-8')
        self.assertIn("FormatException('Invalid profile field: angularUnit')", src)
        self.assertIn("FormatException('Invalid profile field: pressureBar')", src)
        self.assertIn('if (unitName == null)', src)
        self.assertIn('if (pressure == null)', src)
    def test_flutter_regressions_lock_behavior(self):
        src=(ROOT/'test/profile_codec_test.dart').read_text(encoding='utf-8')
        self.assertIn('legacy profile without angularUnit still migrates to MRAD', src)
        self.assertIn('present invalid angularUnit fails closed', src)
        self.assertIn('present invalid pressure fails closed', src)
if __name__ == '__main__': unittest.main()
