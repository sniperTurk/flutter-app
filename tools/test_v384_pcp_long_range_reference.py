"""V384: PCP 950 fps cases from 100 m to 600 m are compared with the
independent py-ballisticcalc reference in CI (owner request 2026-10-08)."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / 'validation' / 'pcp_long_range_acceptance.json'
CI = ROOT / '.github' / 'workflows' / 'ios-ci.yml'


class PcpLongRangeReference(unittest.TestCase):
    def test_policy_covers_100_to_600_m_at_950_fps(self):
        policy = json.loads(POLICY.read_text(encoding='utf-8'))
        self.assertEqual(policy['reference']['package'], 'py-ballisticcalc')
        self.assertGreaterEqual(len(policy['cases']), 4)
        for case in policy['cases']:
            self.assertEqual(case['ranges'], [100.0, 200.0, 300.0, 400.0, 500.0, 600.0])
            self.assertAlmostEqual(case['mv'], 950 * 0.3048, places=2)
            self.assertEqual(case['model'], 'G1')
        # Same frozen tolerances as the other reference sets.
        self.assertEqual(policy['tolerances']['height_m_absolute'], 0.01)

    def test_ci_generates_and_compares_it(self):
        ci = CI.read_text(encoding='utf-8')
        self.assertIn(
            'generate_wind_reference_vectors.py validation/pcp_long_range_acceptance.json',
            ci,
        )
        self.assertIn(
            'compare_wind_reference_vectors.dart validation/pcp_long_range_acceptance.json',
            ci,
        )
        self.assertIn('exit "$status"', ci)


if __name__ == '__main__':
    unittest.main()
