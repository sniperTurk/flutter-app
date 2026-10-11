"""Regression tests for tools/data_gen/generate_scope_library.py.

Merges the checks of the three per-brand generators (Vortex #139, Element
Optics #142, Vector Optics #145) against the single whole-file generator.
"""
from __future__ import annotations

import importlib.util
import json
import re
import tempfile
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    'generate_scope_library', ROOT / 'tools' / 'data_gen' / 'generate_scope_library.py')
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)

OUT = ROOT / 'lib' / 'data' / 'scope_library.dart'
CATALOG = """
  static const scopes = <ScopeOptic>[
    ScopeOptic(
      id:'x-hand', brand:'Acme', model:'Hand 6–24×50 FFP (MRAD)',
      objectiveDiameterMm:50, clickValue:0.1, clickUnit:AngularUnit.mrad,
      minMagnification:6, maxMagnification:24, firstFocalPlane:true,
    ),
    ScopeOptic(id:'x-code', brand:'Acme', model:'Coded 4–16×44 FFP (SCFF-99)', objectiveDiameterMm:44, clickValue:0.1, clickUnit:AngularUnit.mrad, minMagnification:4, maxMagnification:16, firstFocalPlane:true),
    ...ScopeLibrary.all,
  ];
"""


def _rec(**over):
    base = dict(brand='Acme', model='M 3-9x40 SFP', min_mag=3.0, max_mag=9.0,
                objective_mm=40.0, tube_mm=25.4, focal='sfp', click_unit='moa',
                click_value=0.25, elevation_travel_moa=60.0, windage_travel_moa=60.0,
                reticle=None, parallax_min_m=None, length_mm=300, weight_g=400,
                zero_stop=None, source_url='https://example.com/m', notes=None)
    base.update(over)
    return base


def _lines(text):
    return [l for l in text.splitlines() if l.lstrip().startswith('ScopeOptic(')]


class GenerateScopeLibraryTest(unittest.TestCase):
    def build(self, recs, stem='acme', **kw):
        return gen.build({stem: recs}, CATALOG, **kw)

    def test_moa_travel_is_mrad_and_nulls_are_omitted(self):
        text, skipped, n = self.build([_rec()])
        self.assertEqual((n, skipped), (1, []))
        line = _lines(text)[0]
        self.assertIn('elevationRangeMrad:17.45', line)
        self.assertIn('clickUnit:AngularUnit.moa', line)
        self.assertIn('firstFocalPlane:false', line)
        self.assertNotIn('reticle:', line)
        self.assertNotIn('zeroStop', line)
        self.assertIn("id:'lib-acme-m-3-9x40-sfp'", line)
        self.assertIn('official manufacturer page, read 2026-10-10', line)

    def test_vortex_moa_travel_two_decimals(self):
        text, _, _ = self.build([_rec(elevation_travel_moa=75.0, windage_travel_moa=40.0)])
        self.assertIn('elevationRangeMrad:21.82', text)
        self.assertIn('windageRangeMrad:11.64', text)

    def test_mrad_travel_is_kept(self):
        text, _, _ = self.build([_rec(click_unit='mil', click_value=0.1,
                                      elevation_travel_moa=None, windage_travel_moa=None,
                                      elevation_travel_mrad=29.0)])
        line = _lines(text)[0]
        self.assertIn('clickUnit:AngularUnit.mrad', line)
        self.assertIn('elevationRangeMrad:29.0', line)
        self.assertNotIn('windageRangeMrad', line)

    def test_no_click_value_or_objective_is_skipped_never_guessed(self):
        for bad in (dict(click_value=None), dict(objective_mm=None), dict(click_unit=None)):
            _, skipped, n = self.build([_rec(**bad)])
            self.assertEqual(n, 0, bad)
            self.assertEqual(len(skipped), 1, bad)

    def test_hand_catalog_entries_are_not_repeated(self):
        recs = [
            _rec(model='Other 6-24x50', min_mag=6.0, max_mag=24.0, objective_mm=50.0,
                 focal='ffp', click_unit='mrad', click_value=0.1,
                 elevation_travel_moa=None, elevation_travel_mrad=20.0),
            _rec(model='Coded 4-16x44', min_mag=4.0, max_mag=16.0, objective_mm=44.0,
                 focal='ffp', click_unit='mrad', click_value=0.1,
                 source_url='https://example.com/Coded-SCFF-99.html'),
            # Same optics as the coded hand entry but another product code: kept.
            _rec(model='Sibling 4-16x44', min_mag=4.0, max_mag=16.0, objective_mm=44.0,
                 focal='ffp', click_unit='mrad', click_value=0.1,
                 source_url='https://example.com/Sibling-SCFF-98.html'),
            # Same as the hand entry but MOA turrets: a different product.
            _rec(model='Other 6-24x50 MOA', min_mag=6.0, max_mag=24.0,
                 objective_mm=50.0, focal='ffp'),
        ]
        text, _, n = self.build(recs)
        self.assertEqual(n, 2)
        self.assertIn('lib-acme-sibling-4-16x44', text)
        self.assertIn('lib-acme-other-6-24x50-moa', text)

    def test_duplicate_ids_get_a_suffix(self):
        text, _, n = self.build([_rec(), _rec(), _rec()])
        self.assertEqual(n, 3)
        ids = re.findall(r"id:'([^']+)'", text)
        self.assertEqual(ids, ['lib-acme-m-3-9x40-sfp', 'lib-acme-m-3-9x40-sfp-2',
                               'lib-acme-m-3-9x40-sfp-3'])

    def test_ids_are_truncated_to_74_and_unique(self):
        text, _, _ = self.build([_rec(model='X' * 120), _rec(model='X' * 120)])
        ids = re.findall(r"id:'([^']+)'", text)
        self.assertEqual(len(ids[0]), 74)
        self.assertEqual(ids[1], ids[0] + '-2')

    def test_vector_optics_rifle_scope_is_dropped_from_the_name_not_the_id(self):
        text, _, _ = self.build([_rec(brand='Vector Optics',
                                      model='Test 3-9x40 SFP Rifle Scope')], 'vector_optics')
        line = _lines(text)[0]
        self.assertIn("model:'Test 3-9x40 SFP'", line)
        self.assertIn("id:'lib-vector-optics-test-3-9x40-sfp-rifle-scope'", line)
        # Other brands keep the full name.
        text, _, _ = self.build([_rec(model='Test Rifle Scope')])
        self.assertIn("model:'Test Rifle Scope'", text)

    def test_zero_stop_only_when_the_maker_states_it(self):
        text, _, _ = self.build([_rec(zero_stop=True), _rec(zero_stop=False),
                                 _rec(zero_stop='yes')])
        lines = _lines(text)
        self.assertIn('zeroStop:true', lines[0])
        self.assertIn('zeroStop:false', lines[1])
        self.assertNotIn('zeroStop', lines[2])

    def test_accessed_date_and_escaping(self):
        text, _, _ = self.build([_rec(model="It's $5", accessed='2026-10-11')])
        self.assertIn(r"model:'It\'s \$5'", text)
        self.assertIn('read 2026-10-11', text)

    def test_read_date_precedence(self):
        url = 'https://example.com/m'
        known = {url: '2026-10-01'}
        # A source already in the output keeps its first read date.
        text, _, _ = self.build([_rec()], known=known, default_date='2026-10-11')
        self.assertIn('read 2026-10-01', text)
        # A new source gets the date of this run.
        text, _, _ = self.build([_rec(source_url='https://example.com/new')],
                                known=known, default_date='2026-10-11')
        self.assertIn('read 2026-10-11', text)
        # 'accessed' beats everything; a whole re-read brand beats the old date.
        text, _, _ = self.build([_rec(accessed='2026-10-05')], known=known)
        self.assertIn('read 2026-10-05', text)
        text, _, _ = self.build([_rec()], 'element_optics', known=known)
        self.assertIn('read ' + gen.READ_DATES['element_optics'], text)

    def test_known_dates_round_trip(self):
        text, _, _ = self.build([_rec(accessed='2026-10-03')])
        self.assertEqual(gen.known_dates(text), {'https://example.com/m': '2026-10-03'})

    def test_records_without_https_source_are_skipped(self):
        _, skipped, n = self.build([_rec(source_url='http://example.com/m'),
                                    _rec(source_url=None)])
        self.assertEqual(n, 0)
        self.assertEqual(len(skipped), 2)

    def test_files_are_read_in_name_order(self):
        text, _, _ = gen.build({'zeta': [_rec(brand='Zeta')],
                                'alpha': [_rec(brand='Alpha')]}, CATALOG)
        brands = re.findall(r"brand:'([^']+)'", text)
        self.assertEqual(brands, ['Alpha', 'Zeta'])

    def test_data_dir_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, 'vortex.json').write_text(json.dumps([_rec()]), encoding='utf-8')
            raw = gen.load_dir(Path(d))
            self.assertEqual(list(raw), ['vortex'])
            out = Path(d, 'out.dart')
            self.assertEqual(gen.main(['--data-dir', d, '--out', str(out)]), 0)
            self.assertEqual(gen.main(['--data-dir', d, '--out', str(out), '--check']), 0)
            out.write_text(out.read_text(encoding='utf-8') + '//', encoding='utf-8')
            self.assertEqual(gen.main(['--data-dir', d, '--out', str(out), '--check']), 1)

    def test_generated_file_is_sourced_unique_and_contiguous(self):
        text = OUT.read_text(encoding='utf-8')
        self.assertIn('GENERATED by tools/data_gen/generate_scope_library.py', text)
        self.assertTrue(text.startswith('// dart format off\n'))
        ids = re.findall(r"ScopeOptic\(id:'([^']+)'", text)
        self.assertGreater(len(ids), 450)
        self.assertEqual(len(ids), len(set(ids)))
        brands = []
        for line in _lines(text):
            self.assertIn("sourceDocument:'https://", line)
            brand = re.search(r"brand:'([^']+)'", line).group(1)
            if not brands or brands[-1] != brand:
                self.assertNotIn(brand, brands, f'{brand} block is not contiguous')
                brands.append(brand)
        counts = Counter(re.findall(r"ScopeOptic\(id:'[^']+', brand:'([^']+)'", text))
        self.assertGreaterEqual(counts['Vortex'], 85)
        self.assertGreaterEqual(counts['Element Optics'], 30)
        self.assertGreaterEqual(counts['Vector Optics'], 145)
        for line in _lines(text):
            if "brand:'Vector Optics'" in line:
                self.assertNotIn('Rifle Scope', re.search(r"model:'([^']*)'", line).group(1))

    def test_usage_is_documented(self):
        doc = gen.__doc__
        self.assertIn('--branch origin/data/scopes', doc)
        self.assertIn('--check', doc)
        self.assertIn('--read-date', doc)


if __name__ == '__main__':
    unittest.main()
