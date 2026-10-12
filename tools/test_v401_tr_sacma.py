"""TR saçma/slug taraması (2026-10-12): PCP pellets/slugs sold in Turkey join
the library from their makers' own sites only, with source and read date,
without duplicates; maker BCs are kept, missing BCs stay null."""
import json
import re
import unittest
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'data/muhimmat/bullets-pcp'
LIB = (ROOT / 'lib/data/bullet_library.dart').read_text()

FILES = {
    'hatsan_apolo.json': ('Hatsan', 'hatsanairgunsusa.com', 35),
    'hn.json': ('H&N', 'www.hn-sport.de', 27),
    'diana.json': ('Diana', 'www.diana-airguns.de', 14),
    'gamo.json': ('Gamo', 'gamousa.com', 32),
    'skypellets.json': ('SkyPellets', 'skypellets.com', 12),
}
PCP_MM = (4.5, 5.0, 5.5, 6.35, 7.62, 9.0, 11.43, 12.7)
FORBIDDEN = ('chairgun', 'strelok', 'appliedballistics', 'jbmballistics', 'quickload', 'grtools',
             'pyramydair', 'izmiravmarket', 'hatsanstore', 'amazon.', 'forum', 'blog')


def rows(name):
    return json.loads((DATA / name).read_text())


def lib_row(brand, name):
    pat = r"LibraryBullet\('" + re.escape(brand.replace("'", "\\'")) + r"', '" + re.escape(name) + r"', .*\n"
    return re.findall(pat, LIB)


class TrSacmaDataTests(unittest.TestCase):
    def test_counts_and_official_hosts(self):
        for f, (brand, host, n) in FILES.items():
            rs = rows(f)
            self.assertEqual(len(rs), n, f)
            for r in rs:
                self.assertEqual(r['brand'], brand)
                self.assertTrue(r['source_url'].startswith('https://'), r['source_url'])
                self.assertEqual(urlparse(r['source_url']).hostname, host, r['source_url'])
                self.assertFalse(any(x in r['source_url'].lower() for x in FORBIDDEN))

    def test_read_date_and_raw_values_in_notes(self):
        for f in FILES:
            for r in rows(f):
                self.assertIn('2026-10-12', r['notes'], r['name'])
                self.assertIn('Ham', r['notes'], r['name'])

    def test_fields(self):
        for f in FILES:
            for r in rows(f):
                self.assertIn(r['caliber_mm'], PCP_MM, r['name'])
                self.assertIn(r['type'], ('pellet', 'slug'))
                self.assertGreater(r['weight_gr'], 0)
                if r['bc'] is None:
                    self.assertIsNone(r['bc_model'], r['name'])

    def test_apolo_named_and_noted(self):
        for r in rows('hatsan_apolo.json'):
            self.assertTrue(r['name'].startswith('Apolo '), r['name'])
            self.assertIn('Apolo Ammo', r['notes'])


class TrSacmaLibraryTests(unittest.TestCase):
    def test_every_record_listed_once(self):
        for f in FILES:
            for r in rows(f):
                found = lib_row(r['brand'], r['name'])
                self.assertEqual(len(found), 1, (r['brand'], r['name']))
                self.assertIn('WeaponPlatform.pcp', found[0])
                self.assertIn(r['source_url'], found[0])

    def test_bc_kept_or_null(self):
        row = lib_row('H&N', 'Rabbit Magnum II .177 15.74 gr')[0]
        self.assertIn(', 15.74, 0.049, null, BallisticModel.g1, 0.049, ', row)
        row = lib_row('SkyPellets', 'Dome Heavy .22 18.13 gr')[0]
        self.assertIn(', 5.5, 5.52, 18.13, null, null, BallisticModel.g1, null, ', row)

    def test_slug_type(self):
        self.assertIn('AmmunitionType.slug', lib_row('Hatsan', 'Apolo Slug .25 40 gr')[0])

    def test_no_duplicate_library_keys(self):
        keys = re.findall(r"LibraryBullet\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'", LIB)
        pcp = [k for k in keys if k[0] in ('Hatsan', 'H&N', 'Diana', 'Gamo', 'SkyPellets')]
        self.assertEqual(len(pcp), len(set(pcp)))

    def test_unverified_brands_not_added(self):
        # No official site with data (TR_SACMA.md): nothing may appear for them.
        for brand in ('JSB', 'Shock', 'Hunthink', 'İnce Mehmet', 'Engin Sak'):
            self.assertNotIn("LibraryBullet('" + brand + "'", LIB)


if __name__ == '__main__':
    unittest.main()
