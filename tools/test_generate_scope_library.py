"""Offline checks for tools/data_gen/generate_scope_library.py."""
import importlib.util
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    'generate_scope_library', HERE / 'data_gen' / 'generate_scope_library.py')
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)


def rec(**kw):
    base = {
        'brand': 'Vector Optics', 'model': 'Test 3-9x40 SFP Rifle Scope',
        'min_mag': 3.0, 'max_mag': 9.0, 'objective_mm': 40.0, 'tube_mm': 25.4,
        'focal': 'sfp', 'click_unit': 'moa', 'click_value': 0.25,
        'elevation_travel_moa': 60.0, 'windage_travel_moa': 60.0,
        'reticle': 'Duplex', 'parallax_min_m': None, 'length_mm': None,
        'weight_g': 400.0, 'zero_stop': None,
        'source_url': 'https://www.vectoroptics.com/rifle-scopes/Test-SCOM-99999.html',
        'notes': '',
    }
    base.update(kw)
    return base


class RenderTest(unittest.TestCase):
    def test_moa_travel_becomes_mrad_and_nulls_are_omitted(self):
        line = gen.render([rec()], 'vector_optics', '2026-10-11', {})[0]
        self.assertIn("model:'Test 3-9x40 SFP'", line)
        self.assertIn('elevationRangeMrad:17.45', line)
        self.assertNotIn('lengthMm', line)
        self.assertNotIn('zeroStop', line)
        self.assertIn('firstFocalPlane:false', line)
        self.assertIn('read 2026-10-11', line)

    def test_ids_are_truncated_and_unique(self):
        long = 'X' * 120
        lines = gen.render([rec(model=long), rec(model=long)], 'vector_optics', 'd', {})
        ids = [l.split("id:'")[1].split("'")[0] for l in lines]
        self.assertEqual(len(ids[0]), 74)
        self.assertEqual(ids[1], ids[0] + '-2')

    def test_record_without_click_value_is_skipped(self):
        self.assertEqual(gen.render([rec(click_value=None)], 'vector_optics', 'd', {}), [])

    def test_known_source_keeps_its_read_date(self):
        r = rec()
        line = gen.render([r], 'vector_optics', '2026-10-11', {r['source_url']: '2026-10-10'})[0]
        self.assertIn('read 2026-10-10', line)

    def test_committed_vector_optics_block_is_contiguous(self):
        text = gen.OUT.read_text(encoding='utf-8')
        self.assertEqual(gen.splice(text, 'Vector Optics', [
            l + '\n' for l in text.splitlines()
            if l.lstrip().startswith('ScopeOptic(') and "brand:'Vector Optics'" in l]), text)


if __name__ == '__main__':
    unittest.main()
