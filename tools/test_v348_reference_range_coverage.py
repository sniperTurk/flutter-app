#!/usr/bin/env python3
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class ReferenceRangeCoverageTests(unittest.TestCase):
    def test_policy_freezes_model_range_coverage(self):
        policy = json.loads((ROOT/'validation/acceptance.json').read_text(encoding='utf-8'))
        self.assertEqual({'G1': 300.0, 'G7': 1500.0}, policy['requirements']['minimum_max_range_m_by_model'])

    def test_generator_uses_long_range_g7_set(self):
        generator = (ROOT/'tools/generate_reference_vectors.py').read_text(encoding='utf-8')
        validator = (ROOT/'tools/validate_py_ballisticcalc_fixture.py').read_text(encoding='utf-8')
        self.assertIn("'ranges':[100.0,300.0,600.0,1000.0,1500.0]", validator.replace(' ', ''))
        self.assertIn('FROZEN_CASES.items()', generator)
        self.assertNotIn('ranges_by_model =', generator)
        self.assertNotIn('PCP case crosses the transonic region', generator)

    def test_both_consumers_enforce_range_policy(self):
        py = (ROOT/'tools/validate_py_ballisticcalc_fixture.py').read_text(encoding='utf-8')
        dart = (ROOT/'tools/compare_reference_vectors.dart').read_text(encoding='utf-8')
        self.assertIn('minimum_max_range_m_by_model', py)
        self.assertIn('maximum range is below required', py)
        self.assertIn("requirements['minimum_max_range_m_by_model']", dart)
        self.assertIn('maximum range is below required', dart)

if __name__ == '__main__':
    unittest.main()
