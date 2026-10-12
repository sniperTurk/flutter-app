"""Mühimmat tamamlama (2026-10-12): new makers from data/muhimmat reach the
app lists, every record keeps a maker-official source, Applied Ballistics
BCs are not used, and BC-less PCP records of Turkish makers are listed."""
import json
import re
import unittest
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/muhimmat'
AMMO = (ROOT / 'lib/data/factory_ammo_library.dart').read_text()
LIB = (ROOT / 'lib/data/bullet_library.dart').read_text()

# Maker-official hosts per brand (data rule: maker site / catalog only).
OFFICIAL = {
    'PMC': ('pmcammo.com',),
    'Magtech': ('magtechammunition.com',),
    'Aguila': ('aguilaammo.com',),
    'Cutting Edge Bullets': ('cuttingedgebullets.com', 'cdn.shopify.com'),
    'Hammer Bullets': ('hammerbullets.com',),
    'Spoton': ('spoton.com.tr',),
}
FORBIDDEN = ('chairgun', 'strelok', 'appliedballistics', 'jbmballistics', 'quickload', 'grtools',
             'pyramydair', 'amazon.', 'midwayusa', 'opticsplanet', 'forum', 'blog')


def records(sub):
    out = []
    for f in sorted((DATA / sub).glob('*.json')):
        out += json.loads(f.read_text())
    return out


def lib_rows(brand):
    return re.findall(r"LibraryBullet\('" + re.escape(brand) + r"', '((?:[^'\\]|\\.)*)', '(?:[^'\\]|\\.)*', "
                      r"[\d.]+, [\d.]+, [\d.]+, ([\d.]+|null), ([\d.]+|null), BallisticModel\.\w+, ([\d.]+|null), ", LIB)


class SourceRuleTests(unittest.TestCase):
    def test_every_record_has_an_official_https_source(self):
        for sub in ('ammo', 'bullets-firearm', 'bullets-pcp'):
            for r in records(sub):
                url = r['source_url']
                host = urlparse(url).hostname or ''
                self.assertTrue(url.startswith('https://'), url)
                self.assertTrue(any(host == h or host.endswith('.' + h) for h in OFFICIAL[r['brand']]),
                                (r['brand'], url))
                self.assertFalse(any(x in url.lower() for x in FORBIDDEN), url)

    def test_no_applied_ballistics_bc(self):
        for r in records('bullets-firearm'):
            raw = r['notes'].split('Föy ham BC:')[1].split(';')[0] if 'Föy ham BC:' in r['notes'] else ''
            if 'A.B' in raw:
                ab = {float('0' + v) for v in re.findall(r'(\.\d+) \(A\.B\.?\)', raw)}
                self.assertNotIn(r['g1_bc'], ab, r['item_number'])
                self.assertIsNone(r['g7_bc'], r['item_number'])


class FactoryAmmoTests(unittest.TestCase):
    def test_new_makers_listed_with_velocity(self):
        for brand, n in (('PMC', 11), ('Magtech', 35), ('Aguila', 29)):
            rows = re.findall(r"FactoryAmmo\('" + brand + r"', ", AMMO)
            self.assertEqual(len(rows), n, brand)

    def test_unlabelled_bc_note(self):
        row = next(l for l in AMMO.splitlines() if "FactoryAmmo('PMC'" in l and 'X-TAC Match' in l and '168' in l)
        self.assertIn('0.462, BallisticModel.g1', row)
        self.assertIn('G1 kabul edildi', row)

    def test_velocity_inside_app_range(self):
        # Aguila Colibrí / Super Colibrí (420 / 590 fps) stay out (600-4500 fps).
        self.assertNotIn('Colibrí', AMMO)

    def test_aguila_bc_only_from_hunting_sheet(self):
        # BC tamamlama 3 (2026-10-12): Aguila publishes BC (G1-labelled) only in
        # its hunting 'Ballistic Information' PDF; 8 soft/round-nose loads carry
        # it, every other Aguila round stays without BC.
        with_bc = []
        for l in AMMO.splitlines():
            if "FactoryAmmo('Aguila'" in l:
                if ', null, null, ' in l:
                    self.assertRegex(l, r", null, null, [\d.]+, ")
                else:
                    self.assertIn('BallisticModel.g1', l)
                    self.assertNotIn('Full Metal Jacket', l)
                    with_bc.append(l)
        self.assertEqual(len(with_bc), 8)


class BulletLibraryTests(unittest.TestCase):
    def test_new_makers_in_library(self):
        for brand, n in (('Cutting Edge Bullets', 71), ('Hammer Bullets', 16), ('Spoton', 30)):
            self.assertEqual(len(lib_rows(brand)), n, brand)

    def test_bc_less_turkish_pcp_listed(self):
        for brand, n in (('Hatsan', 13), ('My Bullet', 7), ('Spoton', 30)):
            rows = lib_rows(brand)
            self.assertEqual(len(rows), n, brand)
            self.assertTrue(all(bc == 'null' for _, _, _, bc in rows), brand)

    def test_bc_follows_g7_then_g1(self):
        for brand in ('Cutting Edge Bullets', 'Hammer Bullets'):
            for name, g1, g7, bc in lib_rows(brand):
                self.assertEqual(bc, g7 if g7 != 'null' else g1, name)

    def test_existing_bc_rows_untouched(self):
        # 2026-10-11 Zan BC (data/bullets-bc) is still the library value.
        self.assertIn("'ZAN .30 68 gr Slug .300', '', 7.62", LIB)
        new = [k for k in re.findall(r"LibraryBullet\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', "
                                      r"([\d.]+), ([\d.]+), ([\d.]+)", LIB)
               if k[0] in ('Cutting Edge Bullets', 'Hammer Bullets', 'Spoton', 'Hatsan', 'My Bullet')]
        self.assertEqual(len(new), len(set(new)))

    def test_add_script_has_nothing_left_to_add(self):
        import subprocess, sys
        out = subprocess.run([sys.executable, str(ROOT / 'tools/data_gen/add_muhimmat_bullets.py'), '--check'],
                             check=True, capture_output=True, text=True).stdout
        self.assertIn('would add 0', out)

    def test_firearm_rows_all_carry_a_bc(self):
        for brand in ('Cutting Edge Bullets', 'Hammer Bullets'):
            for name, g1, g7, bc in lib_rows(brand):
                self.assertNotEqual(bc, 'null', name)

    def test_no_second_copy_of_reviewed_hn_rows(self):
        self.assertNotIn("'H&N', 'Baracuda Match .177 10.65 gr (kafa", LIB)

if __name__ == '__main__':
    unittest.main()
