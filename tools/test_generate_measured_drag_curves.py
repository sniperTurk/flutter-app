"""Regression tests for tools/data_gen/generate_measured_drag_curves.py.

Only measured curves with reuse permission, full subsonic-to-supersonic
coverage and an exact bullet-library match may reach the app (owner,
2026-10-11).
"""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    'generate_measured_drag_curves',
    ROOT / 'tools' / 'data_gen' / 'generate_measured_drag_curves.py')
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)

LIBRARY = """
    LibraryBullet('Acme', 'Acme .308 175 gr Match', '', 7.82, 7.823, 175.0, 0.5, 0.25, BallisticModel.g7, 0.25, [], null, AmmunitionType.bullet, WeaponPlatform.firearm, 'https://acme.example/b'),
    LibraryBullet('Hornady', '30 Cal .308 225 gr ELD Match (1 in 10" twist)', '', 7.82, 7.823, 225.0, 0.777, 0.391, BallisticModel.g7, 0.391, [], null, AmmunitionType.bullet, WeaponPlatform.firearm, 'https://www.hornady.com/bc'),
    LibraryBullet('O\\'Brien', 'O\\'Brien 6mm 105 gr', '', 6.17, 6.172, 105.0, null, 0.27, BallisticModel.g7, 0.27, [], null, AmmunitionType.bullet, WeaponPlatform.firearm, 'https://ob.example'),
"""

POINTS = [[0.5, 0.15], [0.8, 0.16], [0.95, 0.25], [1.0, 0.36], [1.2, 0.38],
          [1.6, 0.34], [2.0, 0.31], [2.5, 0.28]]


def _rec(**over):
    base = dict(
        id='acme-175', brand='Acme', bullet='.308 175 gr Match',
        diameter_mm=7.823, weight_gr=175.0, method='doppler-radar',
        coefficient='CD0', points=POINTS,
        source_url='https://acme.example/doppler.pdf',
        source_title='Acme Doppler sheet', license='cc-by-4.0',
        license_note='CC BY 4.0 on the sheet', use_in_app=True,
        library=dict(brand='Acme', name='Acme .308 175 gr Match', grain=175.0))
    base.update(over)
    return base


class LibraryParseTest(unittest.TestCase):
    def test_parses_brand_name_grain_with_escapes(self):
        lib = gen.parse_library(LIBRARY)
        self.assertIn(('Acme', 'Acme .308 175 gr Match', 175.0), lib)
        self.assertIn(("O'Brien", "O'Brien 6mm 105 gr", 105.0), lib)
        self.assertEqual(len(lib), 3)

    def test_real_library_parses(self):
        text = (ROOT / 'lib' / 'data' / 'bullet_library.dart').read_text()
        # Every entry is read (the library repeats a few brand/name/grain keys).
        self.assertEqual(len(list(gen._ENTRY.finditer(text))),
                         text.count('LibraryBullet(\''))
        self.assertGreater(len(gen.parse_library(text)), 1500)


class ValidateTest(unittest.TestCase):
    def setUp(self):
        self.lib = gen.parse_library(LIBRARY)

    def test_accepts_complete_permitted_curve(self):
        self.assertIsNone(gen.reject_reason(_rec(), self.lib))

    def test_rejects_when_not_for_app(self):
        self.assertIn('use_in_app', gen.reject_reason(_rec(use_in_app=False), self.lib))

    def test_rejects_unknown_or_missing_license(self):
        for lic in ('free-download', '', None, 'proprietary'):
            self.assertIn('lisans', gen.reject_reason(_rec(license=lic), self.lib))

    def test_rejects_non_https_source(self):
        self.assertIn('kaynak', gen.reject_reason(
            _rec(source_url='http://acme.example/x.pdf'), self.lib))

    def test_rejects_missing_subsonic_or_supersonic_coverage(self):
        self.assertIn('Mach', gen.reject_reason(_rec(points=POINTS[2:]), self.lib))
        self.assertIn('Mach', gen.reject_reason(_rec(points=POINTS[:-2]), self.lib))

    def test_rejects_bad_points(self):
        unordered = [POINTS[1], POINTS[0]] + POINTS[2:]
        self.assertIn('nokta', gen.reject_reason(_rec(points=unordered), self.lib))
        bad_cd = [[m, 2.5 if i == 3 else c] for i, (m, c) in enumerate(POINTS)]
        self.assertIn('nokta', gen.reject_reason(_rec(points=bad_cd), self.lib))
        self.assertIn('nokta', gen.reject_reason(_rec(points=POINTS[:4]), self.lib))

    def test_rejects_without_exact_library_match(self):
        self.assertIn('kütüphane', gen.reject_reason(_rec(library=None), self.lib))
        wrong_grain = dict(brand='Acme', name='Acme .308 175 gr Match', grain=168.0)
        self.assertIn('kütüphane', gen.reject_reason(_rec(library=wrong_grain), self.lib))


class RenderTest(unittest.TestCase):
    def test_renders_const_entries_with_source_and_license(self):
        out = gen.render([_rec(library=dict(
            brand="O'Brien", name="O'Brien 6mm 105 gr", grain=105.0))])
        self.assertIn('Do not edit by hand', out)
        self.assertIn("brand: 'O\\'Brien'", out)
        self.assertIn("sourceUrl: 'https://acme.example/doppler.pdf'", out)
        self.assertIn("license: 'cc-by-4.0'", out)
        self.assertIn('[0.5, 0.15]', out)
        self.assertIn('[2.5, 0.28]', out)

    def test_empty_list_still_valid_dart(self):
        out = gen.render([])
        self.assertIn('const measuredDragCurves = <MeasuredDragCurve>[\n];', out)


class RepoDataTest(unittest.TestCase):
    def test_every_record_has_source_and_license_note(self):
        files = sorted((ROOT / 'data' / 'drag-curves' / 'measured').glob('*.json'))
        self.assertTrue(files)
        for f in files:
            r = json.loads(f.read_text())
            self.assertEqual(r['id'], f.stem)
            self.assertTrue(r['source_url'].startswith('https://'), f)
            self.assertTrue(r['license_note'].strip(), f)
            if not r['use_in_app']:
                self.assertTrue(r['use_in_app_reason'].strip(), f)

    def test_generated_file_is_in_sync(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / 'measured_drag_curves.dart'
            gen.main(['--out', str(out)])
            self.assertEqual(
                out.read_text(),
                (ROOT / 'lib' / 'data' / 'measured_drag_curves.dart').read_text())

    def test_m855_reference_record_stays_out_of_the_app(self):
        lib = gen.parse_library(
            (ROOT / 'lib' / 'data' / 'bullet_library.dart').read_text())
        r = json.loads((ROOT / 'data' / 'drag-curves' / 'measured' /
                        'arl-tr-5182-m855.json').read_text())
        self.assertIsNotNone(gen.reject_reason(r, lib))
        # Even if flagged for the app, the Mach 1.18 floor keeps it out.
        self.assertIn('Mach', gen.reject_reason(dict(r, use_in_app=True), lib))


if __name__ == '__main__':
    unittest.main()
