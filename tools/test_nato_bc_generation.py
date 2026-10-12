"""NATO standart mermi BC'si (owner, 2026-10-12): MKE/askerî fişeklerin BC'si,
eşlendikleri NATO standart mermisinin resmî raporundan gelir ve
lib/data/factory_ammo_library.dart'ta bcSource: 'nato-standard' ile işaretlenir.
"""
import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib' / 'data' / 'factory_ammo_library.dart'

_spec = importlib.util.spec_from_file_location('nato_bc', ROOT / 'tools' / 'data_gen' / 'nato_bc.py')
nato_bc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(nato_bc)

_APPLIED = {
    'dataset': 'ammo-military', 'record': 'M855', 'nato_standard': 'M855 Ball (5.56×45, SS109 tipi)',
    'match': 'kesin', 'status': 'uygulandı', 'bc': 0.154, 'bc_model': 'g7', 'bc_source': 'nato-standard',
    'source_title': 'Silton, S.I.; Howell, B.E. ... ARL-TR-5182, May 2010',
    'source_url': 'https://apps.dtic.mil/sti/tr/pdf/ADA530895.pdf', 'license': 'us-government-public-release',
}


def _lines():
    return [l for l in LIB.read_text(encoding='utf-8').splitlines() if l.strip().startswith('FactoryAmmo(')]


class NatoEntriesTest(unittest.TestCase):
    def _load(self, entries):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'nato_bc.json'
            p.write_text(json.dumps(entries), encoding='utf-8')
            return nato_bc.nato_entries(p)

    def test_only_applied_entries_with_official_source_are_used(self):
        pending = dict(_APPLIED, record='M193', status='kaynak-okunamadı', bc=None)
        got = self._load([_APPLIED, pending])
        self.assertEqual(list(got), [('ammo-military', 'M855')])
        self.assertEqual(got[('ammo-military', 'M855')]['bc'], 0.154)

    def test_forbidden_or_unlicensed_source_is_refused(self):
        for bad in (dict(_APPLIED, source_url='https://www.jbmballistics.com/x'),
                    dict(_APPLIED, source_url='http://apps.dtic.mil/x.pdf'),
                    dict(_APPLIED, license='unknown'),
                    dict(_APPLIED, bc_model='g2'),
                    dict(_APPLIED, bc=0)):
            with self.assertRaises(ValueError, msg=str(bad)):
                self._load([bad])

    def test_report_id_comes_from_the_title(self):
        self.assertEqual(nato_bc.report_id(_APPLIED), 'ARL-TR-5182')
        self.assertEqual(nato_bc.report_id(dict(_APPLIED, source_title='McCoy. BRL-MR-3733, 1988')),
                         'BRL-MR-3733')

    def test_short_standard_name(self):
        self.assertEqual(nato_bc.short_standard('M855 Ball (5.56×45, SS109 tipi)'), 'M855')
        self.assertEqual(nato_bc.short_standard('M33 Ball (.50)'), 'M33')


class MuzzleBackCalcTest(unittest.TestCase):
    def test_g7_and_g1_bring_23_7_m_velocity_back_to_the_muzzle(self):
        tables = nato_bc.load_tables()
        v1 = nato_bc.muzzle_from(838.0, 23.7, 0.45, 'g1', tables)
        v7 = nato_bc.muzzle_from(838.0, 23.7, 0.23, 'g7', tables)
        self.assertGreater(v1, 838.0)
        self.assertLess(v1, 860.0)
        self.assertGreater(v7, 838.0)
        self.assertLess(v7, 860.0)
        # A lower BC loses more speed over the same 23.7 m.
        self.assertGreater(nato_bc.muzzle_from(838.0, 23.7, 0.20, 'g7', tables), v7)


class GeneratedLibraryTest(unittest.TestCase):
    def test_m855_carries_the_arl_bc(self):
        hits = [l for l in _lines() if "'ABD Ordusu', 'M855'," in l]
        self.assertEqual(len(hits), 1)
        l = hits[0]
        self.assertIn("'5.56x45 NATO', 5.7, 62.0, 0.154, BallisticModel.g7, 3113.0, 20.0,", l)
        self.assertIn("bcSource: 'nato-standard'", l)
        self.assertIn("bcStandard: 'M855'", l)
        self.assertIn("bcReport: 'ARL-TR-5182'", l)
        self.assertIn("bcSourceUrl: 'https://apps.dtic.mil/sti/tr/pdf/ADA530895.pdf'", l)

    def test_every_nato_record_names_its_report_and_url(self):
        nato = [l for l in _lines() if 'nato-standard' in l]
        self.assertGreaterEqual(len(nato), 1)
        for l in nato:
            self.assertRegex(l, r"bcStandard: '[^']+'")
            self.assertRegex(l, r"bcReport: '[^']+'")
            self.assertRegex(l, r"bcSourceUrl: 'https://")
            self.assertNotRegex(l, r", null, null, [\d.]+, ")  # has a BC

    def test_other_records_carry_no_nato_mark(self):
        others = [l for l in _lines() if 'nato-standard' not in l]
        self.assertGreater(len(others), 1000)
        for l in others:
            self.assertNotIn('bcStandard', l)
            self.assertNotIn('bcReport', l)
            self.assertNotIn('bcSourceUrl', l)

    def test_mke_rounds_with_their_own_bc_are_unchanged(self):
        m80 = [l for l in _lines() if "'7.62×51 Normal Fişek (M80)'" in l]
        self.assertEqual(len(m80), 1)
        self.assertIn('148.9, 0.45, BallisticModel.g1, 2803.0, null,', m80[0])
        self.assertNotIn('nato-standard', m80[0])


if __name__ == '__main__':
    unittest.main()
