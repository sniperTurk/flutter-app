from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CODEC = (ROOT / 'lib/services/profile_codec.dart').read_text()

class ProfileCodecProductionBoundsTest(unittest.TestCase):
    def test_codec_uses_shared_production_limits(self):
        self.assertIn("import '../core/production_limits.dart';", CODEC)
        for token in [
            'ProductionLimits.maxProfileNameLength',
            'ProductionLimits.maxMuzzleVelocityMps',
            'ProductionLimits.maxRangeM',
            'ProductionLimits.maxSightHeightMm',
            'ProductionLimits.maxPcpPressureBar',
        ]:
            self.assertIn(token, CODEC)

    def test_persisted_values_fail_closed_above_bounds(self):
        self.assertIn("requiredString('name', maxLength: ProductionLimits.maxProfileNameLength)", CODEC)
        self.assertIn("requiredPositive('muzzleVelocityMps', max: ProductionLimits.maxMuzzleVelocityMps)", CODEC)
        self.assertIn("requiredPositive('zeroRangeM', max: ProductionLimits.maxRangeM)", CODEC)
        self.assertIn("requiredPositive('sightHeightMm', max: ProductionLimits.maxSightHeightMm, maxExclusive: true)", CODEC)
        self.assertIn('pressure.toDouble() <= ProductionLimits.maxPcpPressureBar', CODEC)

if __name__ == '__main__': unittest.main()
