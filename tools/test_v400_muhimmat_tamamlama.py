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
        for brand, n in (('PMC', 11), ('Magtech', 35), ('Aguila', 31)):
            rows = re.findall(r"FactoryAmmo\('" + brand + r"', ", AMMO)
            self.assertGreaterEqual(len(rows), n - 2, brand)  # de-duplicated variants only

    def test_unlabelled_bc_note(self):
        row = next(l for l in AMMO.splitlines() if "FactoryAmmo('PMC'" in l and 'X-TAC Match' in l and '168' in l)
        self.assertIn('0.462, BallisticModel.g1', row)
        self.assertIn('G1 kabul edildi', row)

    def test_aguila_has_no_bc(self):
        for l in AMMO.splitlines():
            if "FactoryAmmo('Aguila'" in l:
                self.assertRegex(l, r", null, null, [\d.]+, ")


class BulletLibraryTests(unittest.TestCase):
    def test_new_makers_in_library(self):
        for brand, n in (('Cutting Edge Bullets', 155), ('Hammer Bullets', 16), ('Spoton', 30)):
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

    def test_add_script_is_idempotent(self):
        import subprocess, sys
        before = LIB
        subprocess.run([sys.executable, str(ROOT / 'tools/data_gen/add_muhimmat_bullets.py'), '--check'],
                       check=True, capture_output=True)
        self.assertEqual((ROOT / 'lib/data/bullet_library.dart').read_text(), before)


if __name__ == '__main__':
    unittest.main()
