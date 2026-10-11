"""Tests of tools/reticle_match_audit.py: scope → reticle record matching
mirrors lib/data/reticle_catalog.dart (owner, 2026-10-11)."""

import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import reticle_match_audit as audit  # noqa: E402


def rec(rid, brand, name, unit, family='hash', hash_step=0.2, scopes=()):
    return {
        'scopes': list(scopes),
        'id': rid,
        'brand': brand,
        'name': name,
        'unit': unit,
        'family': family,
        'hashStep': hash_step,
    }


LIB = [
    rec('el-apr1c-moa', 'Element Optics', 'APR-1C MOA', 'moa'),
    rec('el-apr2d-moa', 'Element Optics', 'APR-2D MOA', 'moa'),
    rec('el-raptr1f', 'Element Optics', 'RAPTR-1F', 'mil', family=None),
    rec('vo-vct34', 'Vector Optics', 'VCT-34 FFP (MIL)', 'mil'),
    rec('vo-vepgt', 'Vector Optics', 'VEPG-TMIL', 'mil'),
    rec('vo-g4', 'Vector Optics', 'German #4 MOA', 'moa', 'duplex', None),
    rec('nf-mildot', 'Nightforce', 'Mil-Dot', 'mil'),
    rec('at-aplr2-mil', 'Athlon Optics', 'APLR2 FFP IR MIL', 'mil'),
    rec('at-aplr2-moa', 'Athlon Optics', 'APLR2 FFP IR MOA', 'moa'),
    rec('at-aprs6-ir', 'Athlon Optics', 'APRS6 FFP IR MIL', 'mil',
        scopes=['Cronus BTR GEN2 UHD', 'Helos BTR GEN2']),
    rec('at-aprs6', 'Athlon Optics', 'APRS6 FFP MIL', 'mil',
        scopes=['Midas TAC HD']),
    rec('ka-skmr4', 'Kahles', 'SKMR4', 'mil'),
    rec('ka-skmr4-plus', 'Kahles', 'SKMR4+', 'mil'),
]


class OptionsTest(unittest.TestCase):
    def test_multi_reticle_split(self):
        self.assertEqual(
            audit.options('APR-1C MOA / APR-2D MOA'),
            ['APR-1C MOA', 'APR-2D MOA'],
        )
        self.assertEqual(audit.options('VPR-MIL / FFP'), ['VPR-MIL'])
        self.assertEqual(audit.options(None), [])
        self.assertEqual(audit.options('  '), [])


class NameKeyTest(unittest.TestCase):
    def test_glued_suffix(self):
        self.assertEqual(audit.name_key('VCT-34FFP'), ('VCT34', None))
        self.assertEqual(audit.name_key('VCT-34 FFP (MIL)'), ('VCT34', 'mil'))
        self.assertEqual(audit.name_key('VEPG-TMIL'), ('VEPGT', 'mil'))
        self.assertEqual(audit.name_key('VEPG-T MIL'), ('VEPGT', 'mil'))
        self.assertEqual(audit.name_key('VTA - 9 MIL'), ('VTA9', 'mil'))
        # The old key kept the glued words.
        self.assertEqual(
            audit.name_key('VCT-34FFP', legacy=True), ('VCT34FFP', None)
        )

    def test_unit_words_alone_are_no_name(self):
        self.assertEqual(audit.name_key('MRAD')[0], '')
        # A name that only starts with a unit word keeps it: MIL-C, MOAR.
        self.assertEqual(audit.name_key('MIL-C F1'), ('MILC', None))
        self.assertEqual(audit.name_key('MOAR'), ('MOAR', None))


class FindTest(unittest.TestCase):
    def find(self, name, unit, brand):
        hit = audit.find(name, unit, brand, LIB)
        return hit['id'] if hit else None

    def test_glued_names_match(self):
        self.assertEqual(self.find('VCT-34FFP', 'mrad', 'Vector Optics'),
                         'vo-vct34')
        self.assertEqual(self.find('VEPG-T MIL', 'mrad', 'Vector Optics'),
                         'vo-vepgt')

    def test_unit_must_match_turret(self):
        # RAPTR-1F record is MIL; a MOA scope does not get it.
        self.assertIsNone(self.find('RAPTR-1F', 'moa', 'Element Optics'))
        self.assertEqual(self.find('RAPTR-1F', 'mrad', 'Element Optics'),
                         'el-raptr1f')
        # The name says MOA but the turret is MRAD: no match.
        self.assertIsNone(self.find('APR-1C MOA', 'mrad', 'Element Optics'))
        # Two records: the turret unit decides (SMOA is MOA family).
        self.assertEqual(self.find('APLR2', 'smoa', 'Athlon'), 'at-aplr2-moa')
        self.assertEqual(self.find('APLR2', 'mrad', 'Athlon'), 'at-aplr2-mil')

    def test_plus_is_part_of_the_name(self):
        self.assertEqual(self.find('SKMR4+', 'mrad', 'Kahles'), 'ka-skmr4-plus')
        self.assertEqual(self.find('SKMR4', 'mrad', 'Kahles'), 'ka-skmr4')

    def test_record_scope_list_tells_same_names_apart(self):
        # Two APRS6 records: the manufacturer's scope list of each decides.
        lib = LIB
        hit = audit.find('APRS6', 'mrad', 'Athlon', lib,
                         model='HELOS BTR GEN2 6-24x56 APRS6 FFP IR MIL')
        self.assertEqual(hit['id'], 'at-aprs6-ir')
        # The Profil form saves the series with the brand.
        hit = audit.find('APRS6', 'mrad', 'Athlon CRONUS BTR GEN2 UHD IR MIL',
                         lib, model='4,5-29x56 FFP')
        self.assertEqual(hit['id'], 'at-aprs6-ir')
        # No model named: still two records, no pick.
        self.assertIsNone(audit.find('APRS6', 'mrad', 'Athlon', lib))
        # A word only leads a word: "Helos BTR GEN22" is not "GEN2".
        self.assertIsNone(audit.find('APRS6', 'mrad', 'Athlon', lib,
                                     model='Helos BTR GEN22 4-20x50'))

    def test_other_brand_not_used(self):
        self.assertIsNone(self.find('Mil-Dot', 'mrad', 'Vector Optics'))
        self.assertEqual(self.find('Mil-Dot', 'mrad', 'Nightforce Optics'),
                         'nf-mildot')

    def test_multi_name_is_not_one_reticle(self):
        self.assertIsNone(
            self.find('APR-1C MOA / APR-2D MOA', 'moa', 'Element Optics')
        )


class AuditTest(unittest.TestCase):
    def scope(self, sid, brand, reticle, unit, model=''):
        return {'id': sid, 'brand': brand, 'reticle': reticle, 'unit': unit,
                'model': model}

    def test_reason_codes(self):
        scopes = [
            self.scope('a', 'Element Optics', 'APR-1C MOA / APR-2D MOA', 'moa'),
            self.scope('b', 'Element Optics', 'RAPTR-1F', 'moa'),
            self.scope('c', 'Element Optics', 'LPR-1D BDC', 'moa'),
            self.scope('d', 'Vector Optics', 'Mil-Dot', 'mrad'),
            self.scope('e', 'Vector Optics', '', 'mrad'),
            self.scope('f', 'Element Optics', 'RAPTR-1F', 'mrad'),
            self.scope('g', 'Element Optics', 'APR-1C MOA / LPR-1D', 'moa'),
        ]
        rows = {r['id']: r for r in audit.audit(scopes, LIB)['scopes']}
        self.assertEqual(rows['a']['status'], 'eslesti')
        self.assertEqual(rows['a']['records'], ['el-apr1c-moa', 'el-apr2d-moa'])
        self.assertTrue(rows['a']['multi'])
        self.assertEqual(rows['b']['reasons'], ['birim-farki'])
        self.assertEqual(rows['c']['reasons'], ['kayit-yok'])
        self.assertEqual(rows['d']['reasons'], ['baska-marka'])
        self.assertEqual(rows['e']['status'], 'retikul-yok')
        self.assertEqual(rows['f']['status'], 'eslesti')
        self.assertFalse(rows['f']['drawable'])
        self.assertEqual(rows['g']['status'], 'kismi')

    def test_brand_summary(self):
        scopes = [
            self.scope('a', 'Element Optics', 'APR-1C MOA', 'moa'),
            self.scope('b', 'Element Optics', 'LPR-1D BDC', 'moa'),
        ]
        brands = audit.audit(scopes, LIB)['brands']
        self.assertEqual(brands['Element Optics']['toplam'], 2)
        self.assertEqual(brands['Element Optics']['eslesti'], 1)
        self.assertEqual(brands['Element Optics']['eslesmedi'], 1)


class RealDataTest(unittest.TestCase):
    """The generated Dart lists parse completely."""

    ROOT = pathlib.Path(__file__).resolve().parent.parent

    def test_parses_generated_lists(self):
        scopes = audit.parse_scopes(
            (self.ROOT / 'lib/data/scope_library.dart').read_text())
        lib = audit.parse_reticles(
            (self.ROOT / 'lib/data/reticle_library.dart').read_text())
        self.assertGreaterEqual(len(scopes), 482)
        self.assertGreaterEqual(len(lib), 319)
        self.assertTrue(all(s['unit'] in ('mrad', 'moa', 'smoa')
                            for s in scopes))
        self.assertTrue(all(r['unit'] in ('mil', 'moa') for r in lib))

    def test_fixture_is_current(self):
        """test/fixtures/reticle_scope_matches.json is what the audit says
        today, so the Dart test checks the Dart matcher against it."""
        import json
        fixture = self.ROOT / 'test/fixtures/reticle_scope_matches.json'
        self.assertEqual(
            json.loads(fixture.read_text()),
            audit.fixture(self.ROOT),
            'Re-run: python3 tools/reticle_match_audit.py --write-fixture',
        )


if __name__ == '__main__':
    unittest.main()
