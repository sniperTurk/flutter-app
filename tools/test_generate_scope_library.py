"""Regression tests for tools/data_gen/generate_scope_library.py."""
from __future__ import annotations

import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    'generate_scope_library', ROOT / 'tools' / 'data_gen' / 'generate_scope_library.py')
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)

OUT = ROOT / 'lib' / 'data' / 'scope_library.dart'


def _rec(**over):
    r = {'brand': 'Vortex', 'model': 'Test 3-15x44 — EBR-4 (MOA)', 'min_mag': 3.0,
         'max_mag': 15.0, 'objective_mm': 44.0, 'tube_mm': 30.0, 'focal': 'sfp',
         'click_unit': 'moa', 'click_value': 0.25, 'elevation_travel_moa': 75.0,
         'windage_travel_moa': 40.0, 'reticle': 'EBR-4 (MOA)', 'parallax_min_m': None,
         'length_mm': 363, 'weight_g': 797, 'zero_stop': None,
         'source_url': 'https://vortexoptics.com/x.html', 'notes': None}
    r.update(over)
    return r


class GenerateScopeLibraryTest(unittest.TestCase):
    def test_moa_travel_is_converted_to_mrad(self):
        text, _ = gen.generate([('v.json', [_rec()])])
        self.assertIn('elevationRangeMrad:21.82', text)
        self.assertIn('windageRangeMrad:11.64', text)
        self.assertIn('firstFocalPlane:false', text)

    def test_incomplete_and_duplicate_records(self):
        text, skipped = gen.generate([('v.json', [_rec(), _rec(), _rec(click_value=None)])])
        ids = re.findall(r"id:'([^']+)'", text)
        self.assertEqual(len(ids), 2)
        self.assertEqual(ids[1], ids[0] + '-2')
        self.assertEqual(len(skipped), 1)

    def test_accessed_date_and_escaping(self):
        text, _ = gen.generate([('v.json', [_rec(model="It's $5", accessed='2026-10-11')])])
        self.assertIn(r"model:'It\'s \$5'", text)
        self.assertIn('read 2026-10-11', text)

    def test_data_dir_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, 'vortex.json').write_text(json.dumps([_rec()]), encoding='utf-8')
            files = gen.load_files(type('A', (), {'data_dir': d, 'branch': None})())
            self.assertEqual(files[0][0], 'vortex.json')

    def test_generated_file_is_well_formed(self):
        text = OUT.read_text(encoding='utf-8')
        self.assertTrue(text.startswith(gen.HEADER))
        self.assertTrue(text.endswith(gen.FOOTER))
        ids = re.findall(r"id:'([^']+)'", text)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreaterEqual(sum('brand:\'Discovery Optics\'' in l for l in text.splitlines()), 34)

    def test_discovery_gen3_and_moa_variants_listed(self):
        text = OUT.read_text(encoding='utf-8')
        for model in ('HD Gen III 5-30x56 SFIR FFP', 'ED-ELR Gen III 5-40x56 SFIR FFP',
                      'ED-PRS Gen II 5-25x56 SFIR FFP Zero Stop MOA',
                      'HD Gen II 5-30x56 SFIR FFP Zero Stop MOA',
                      'ED-ELR Gen II 5-40x56 SFIR FFP Zero Stop MOA',
                      'ED-ELR Gen III 5-40x56 SFIR FFP Zero Stop MOA',
                      'LHD 8-32x56 SFIR FFP Zero Stop MOA'):
            self.assertIn(f"brand:'Discovery Optics', model:'{model}'", text, model)
        # Hand-verified catalog entry (discovery-xed-moa) is not listed twice.
        self.assertNotIn("model:'XED 6-36x56 SFIR FFP Zero Stop MOA'", text)


if __name__ == '__main__':
    unittest.main()
