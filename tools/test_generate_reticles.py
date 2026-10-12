"""Regression tests for tools/data_gen/generate_reticles.py."""
from __future__ import annotations

import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    'generate_reticles', ROOT / 'tools' / 'data_gen' / 'generate_reticles.py')
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)

DATA = ROOT / 'data' / 'reticles'
OUT = ROOT / 'lib' / 'data' / 'reticle_library.dart'


def _record(**over):
    base = {k: None for k in gen.REQUIRED}
    base.update(name='Test MIL', brand='Test', scopes=[], unit='mil',
                family='hash', hash_step=0.2, source_url='https://example.com',
                notes='')
    base.update(over)
    return base


class GenerateReticlesTest(unittest.TestCase):
    def test_generated_file_is_current(self):
        self.assertTrue(OUT.exists())
        text, skipped = gen.build(gen.load_dir(DATA))
        # A record without a unit (e.g. a caliber-specific BDC whose maker
        # gives no angular values) cannot be drawn; it is skipped, never
        # guessed. Any other reason is a data error.
        self.assertEqual([x for x in skipped if 'unit tanınmıyor (None)' not in x], [])
        self.assertEqual(OUT.read_text(encoding='utf-8'), text,
                         'run python3 tools/data_gen/generate_reticles.py')

    def test_every_record_is_generated_and_nulls_stay_null(self):
        text = OUT.read_text(encoding='utf-8')
        for path in sorted(DATA.glob('*.json')):
            rec = json.loads(path.read_text(encoding='utf-8'))
            if rec.get('unit') is None:
                continue  # skipped by the generator (see above)
            line = next((l for l in text.splitlines()
                         if f"ReticleData(id:'{path.stem}'," in l), None)
            self.assertIsNotNone(line, path.stem)
            for key, dart in [('hash_step', 'hashStep'), ('major_every', 'majorEvery'),
                              ('numbers_every', 'numbersEvery'), ('extent_h', 'extentH'),
                              ('extent_v_up', 'extentUp'), ('extent_v_down', 'extentDown'),
                              ('posts_start', 'postsStart')]:
                got = re.search(rf'\b{dart}:([^,]+),', line).group(1)
                if rec[key] is None:
                    self.assertEqual(got, 'null', f'{path.stem}.{key}')
                else:
                    self.assertEqual(float(got), float(rec[key]), f'{path.stem}.{key}')
            for key, dart in [('center_dot', 'centerDot'),
                              ('floating_center', 'floatingCenter')]:
                got = re.search(rf'\b{dart}:([^,]+),', line).group(1)
                want = 'null' if rec[key] is None else str(rec[key]).lower()
                self.assertEqual(got, want, f'{path.stem}.{key}')
            if rec['tree'] is None:
                self.assertIn('tree:null,', line)
            else:
                for row in rec['tree']['rows']:
                    if row['dot_step'] is None:
                        self.assertIn('dotStep:null)', line, path.stem)

    def test_manufacturer_sources_only(self):
        banned = ('chairgun', 'strelok', 'appliedballistics', 'applied-ballistics',
                  'hornady4dof', 'jbmballistics')
        for path in DATA.glob('*.json'):
            url = (json.loads(path.read_text(encoding='utf-8'))['source_url'] or '').lower()
            for b in banned:
                self.assertNotIn(b, url, path.stem)

    def test_invalid_records_are_skipped_not_repaired(self):
        raw = {
            'ok': _record(),
            'no-unit': _record(unit=None),
            'text-number': _record(hash_step='0.2'),
            'bad-family': _record(family='spiral'),
            'missing-key': {k: v for k, v in _record().items() if k != 'tree'},
            'extra-key': _record(guess=1),
        }
        text, skipped = gen.build(raw)
        self.assertEqual(sorted(s.split(':')[0] for s in skipped),
                         ['bad-family', 'extra-key', 'missing-key', 'no-unit', 'text-number'])
        self.assertIn("ReticleData(id:'ok',", text)
        self.assertEqual(text.count('ReticleData(id:'), 1)

    def test_optional_widths_and_escaping(self):
        text, skipped = gen.build({'w': _record(name="It's $x", line_width=0.04,
                                                post_width=0.3, unit='MRAD')})
        self.assertEqual(skipped, [])
        self.assertIn("name:'It\\'s \\$x'", text)
        self.assertIn('lineWidth:0.04', text)
        self.assertIn('postWidth:0.3', text)
        self.assertIn("unit:'mil'", text)

    def test_check_mode_and_brand_branch_override(self):
        with tempfile.TemporaryDirectory() as d:
            data = Path(d) / 'data'
            data.mkdir()
            (data / 'a.json').write_text(json.dumps(_record()), encoding='utf-8')
            out = Path(d) / 'out.dart'
            self.assertEqual(gen.main(['--data-dir', str(data), '--out', str(out)]), 0)
            self.assertEqual(gen.main(['--data-dir', str(data), '--out', str(out),
                                       '--check']), 0)
            (data / 'a.json').write_text(json.dumps(_record(extent_h=6)), encoding='utf-8')
            self.assertEqual(gen.main(['--data-dir', str(data), '--out', str(out),
                                       '--check']), 1)

    def test_usage_is_documented(self):
        doc = gen.__doc__
        self.assertIn('NASIL ÇALIŞTIRILIR', doc)
        self.assertIn('--from-branches', doc)


if __name__ == '__main__':
    unittest.main()
