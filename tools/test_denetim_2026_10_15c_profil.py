"""Tests for tools/denetim_2026_10_15c_profil.py (pre-TestFlight audit
2026-10-15c, PROFIL: #327 Tür/Kalibre, #329 summary line, #344/#346/#322/
#350/#351 screened).

Catalog parsing of lib/data/*.dart, hand calculations from unit definitions
and source scans of the whole profiles_screen.dart library. No Flutter.

Run: python3 -m unittest discover -s tools -p 'test_denetim_2026_10_15c_profil.py'
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15c_profil as d  # noqa: E402
import denetim_2026_10_15b_profil as prev  # noqa: E402


class CatalogParsing(unittest.TestCase):
    """The parser sees every record (one constructor line per record)."""

    def test_counts_match_the_constructor_lines(self):
        def lines(rel, token):
            text = (d.ROOT / rel).read_text(encoding='utf-8')
            # The class's own constructor line is not a record.
            return sum(1 for ln in text.splitlines()
                       if token in ln and 'const ' not in ln)
        self.assertEqual(len(d.firearm_cartridges()), 168)
        self.assertEqual(len({n for n, _ in d.firearm_cartridges()}), 168)
        self.assertEqual(len(d.pcp_calibers()), 10)
        self.assertEqual(len(d.rifle_library()),
                         lines('lib/data/rifle_library.dart', 'LibraryRifle('))
        self.assertEqual(len(d.factory_ammo()),
                         lines('lib/data/factory_ammo_library.dart',
                               'FactoryAmmo('))
        self.assertEqual(len(d.bullet_library()),
                         lines('lib/data/bullet_library.dart',
                               'LibraryBullet('))


class Prf7Prf8AllCalibers(unittest.TestCase):
    """#327: stored caliber -> solver diameter is the chosen caliber's on
    every path (Kalibre list, Marka/Model variant, Fabrika fişeği)."""

    @classmethod
    def setUpClass(cls):
        cls.fa = dict(d.firearm_cartridges())
        cls.pcp = [mm for mm, _ in d.pcp_calibers()]

    def test_every_listed_firearm_rifle_has_its_cartridge_diameter(self):
        bad = [r for r in d.rifle_library() if r['platform'] == 'firearm'
               and (r['cartridge'] not in self.fa
                    or abs(self.fa[r['cartridge']] - r['diameter'])
                    >= d.SAME_DIAMETER)]
        self.assertEqual(bad, [])

    def test_every_listed_pcp_rifle_diameter_is_a_pcp_kalibre(self):
        bad = [r for r in d.rifle_library() if r['platform'] == 'pcp'
               and not any(abs(r['diameter'] - v) < d.SAME_DIAMETER
                           for v in self.pcp)]
        self.assertEqual(bad, [])

    def test_every_factory_round_has_its_cartridge_diameter(self):
        bad = [a for a in d.factory_ammo()
               if a['cartridge'] not in self.fa
               or abs(self.fa[a['cartridge']] - a['diameter'])
               >= d.SAME_DIAMETER]
        self.assertEqual(bad, [])

    def test_no_pcp_caliber_is_a_firearm_diameter(self):
        # A changed Tür therefore always empties the other list's Kalibre.
        hits = [(v, n) for v in self.pcp for n, mm in self.fa.items()
                if abs(v - mm) < d.SAME_DIAMETER]
        self.assertEqual(hits, [])

    def test_bullet_diameters_off_the_kalibre_list(self):
        # PRF-8 remainder (known, not in #327): an El dolumu bullet of these
        # diameters shows "<mm> mm (kayıtlı)"; its diameter is still stored.
        diam = set(self.fa.values())
        off = {b['caliber'] for b in d.bullet_library()
               if b['platform'] == 'firearm'
               and not any(abs(b['caliber'] - x) < d.SAME_DIAMETER
                           for x in diam)}
        self.assertIn(8.15, off)
        self.assertGreater(len(off), 30)

    def test_tur_resets_kalibre_only_when_it_changes(self):
        self.assertTrue(d.tur_clears_only_when_changed())

    def test_kalibre_shown_after_tur_is_the_picked_name(self):
        # Same Tür: nothing in the handler runs, _caliberKey returns the
        # kept _cartridge. Before #327 it was _cartridgeFor(diameter):
        fa = d.firearm_cartridges()
        self.assertEqual(d.cartridge_for(7.82, fa), '.308 Win')
        self.assertEqual(d.cartridge_for(6.71, fa), '6.5 Creedmoor')
        self.assertIsNone(d.cartridge_for(8.15, fa))


class Prf11Reload(unittest.TestCase):
    """PRF-11 (medium): the cartridge name is not saved."""

    def test_rifle_record_has_no_cartridge_field(self):
        self.assertFalse(d.cartridge_saved())

    def test_typed_rifle_reload_names(self):
        shadow = d.prf11_typed_shadowed()
        self.assertIn('.300 Win Mag', shadow)
        self.assertNotIn('.308 Win', shadow)
        self.assertEqual(len(shadow), 131)

    def test_listed_rifle_reload_anschutz_1782_classic(self):
        rifles = d.rifle_library()
        saved = next(r for r in rifles if r['brand'] == 'Anschütz'
                     and r['model'] == '1782 Classic'
                     and r['cartridge'] == '.300 Win Mag')
        self.assertEqual(saved['twist'], 10.0)
        back = d.reload_variant(saved, rifles, d.cartridge_name_map())
        self.assertEqual(back['cartridge'], '.30-06 Springfield')
        self.assertEqual(back['diameter'], saved['diameter'])  # 7.82 both

    def test_listed_rifle_reload_counts(self):
        aff = d.prf11_listed_affected()
        self.assertGreater(len(aff), 800)
        self.assertGreater(len(d.prf11_muh1_bypass(aff)), 800)
        # The diameter, hence the stored number, never changes.
        fa = dict(d.firearm_cartridges())
        for _, _, saved, back in aff:
            self.assertLess(abs(fa[saved] - fa[back]), d.SAME_DIAMETER)

    def test_muh1_guard_lost_on_reload(self):
        aguila = next(a for a in d.factory_ammo()
                      if a['cartridge'] == '.300 Win Mag'
                      and a['bc'] is not None and a['model'] is not None)
        self.assertEqual(aguila['brand'], 'Aguila')
        self.assertEqual(aguila['model'], 'g1')
        self.assertIsNone(aguila['bcG7'])
        # Correct cartridge: G7 empties the box; PRF-11: G1 0.425 stays.
        self.assertEqual(d.muh1_box_after_g7(aguila, listed=True), '')
        self.assertEqual(d.muh1_box_after_g7(aguila, listed=False), '0,425')


class SummaryLine(unittest.TestCase):
    """#329 profileListSummary, from unit definitions."""

    def test_examples(self):
        self.assertEqual(d.summary_line(6.35, 25, 'meter', 274.32, 0.08, 'g1'),
                         '6,35 mm, sıfır 25 m, 900 fps, BC 0,08 G1')
        self.assertEqual(d.summary_line(7.82, 100 * d.M_PER_YD, 'yard',
                                        2650 * d.M_PER_FT, 0.5, 'g7'),
                         '7,82 mm, sıfır 100,0 yd, 2650 fps, BC 0,5 G7')
        self.assertEqual(d.summary_line(7.82, 100, 'meter', 822.96, 0.475,
                                        'g1'),
                         '7,82 mm, sıfır 100 m, 2700 fps, BC 0,475 G1')
        self.assertEqual(d.summary_line(7.82, 300 * d.M_PER_YD, 'yard',
                                        800, None, None),
                         '7,82 mm, sıfır 300,0 yd, 2625 fps')

    def test_prf12_curve_sd_shown_as_bc(self):
        sd = d.sectional_density(175, 7.82)
        self.assertAlmostEqual(sd, 0.26375089, places=7)
        # DragCurve.sectionalDensity doc: 168 gr .308 -> 0.253.
        self.assertAlmostEqual(d.sectional_density(168, 7.82), 0.2532, 4)
        self.assertTrue(d.summary_shows_curve_sd())
        self.assertEqual(d.trim_num(sd), '0,2637508912160438')


class Screened(unittest.TestCase):
    def test_344_travel_rounding_bound(self):
        # Half of a 1/4 MOA click in mrad.
        self.assertAlmostEqual(d.quarter_moa_half_click_mrad(), 0.036361,
                               places=6)

    def test_351_bc_examples_are_valid_and_typical(self):
        for name, (example, (lo, hi)) in d.INFO_BC_EXAMPLES.items():
            text = f'{example:.3f}'.replace('.', ',')
            self.assertTrue(d.info_example_present(name, text), name)
            self.assertTrue(0.005 <= example <= 1.5, name)  # _bcError range
            self.assertTrue(lo <= example <= hi, name)

    def test_prf9_still_open(self):
        # PRF-9 (2026-10-15b) is not fixed on main e7b29bf: its skipped
        # Dart test stays skipped.
        self.assertTrue(prev.prf9_present())


if __name__ == '__main__':
    unittest.main()
