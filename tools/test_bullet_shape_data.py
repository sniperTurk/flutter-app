"""data/bullet_shape (owner, 2026-10-13): every shape field is cited and the
generated per-brand files match the rules and the libraries."""
import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'data_gen'))
import bullet_shape as bs  # noqa: E402


class BulletShapeDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.recs = bs.load_library()
        cls.result = bs.expand(cls.recs, bs.load_rules())

    def test_generated_files_are_current(self):
        self.assertEqual(bs.write_expanded(self.result, check=True), [])

    def test_every_record_has_one_entry(self):
        n = sum(len(d['records']) for d in self.result.values())
        self.assertEqual(n, len(self.recs))

    def test_fields_are_cited_and_valid(self):
        for d in self.result.values():
            for key, e in d['records'].items():
                for f in bs.FIELDS:
                    v = e.get(f)
                    if not v:
                        continue
                    if f in bs.ALLOWED:
                        self.assertIn(v['value'], bs.ALLOWED[f], key)
                    self.assertTrue(v['source_url'].startswith('http'), key)
                    if v['evidence'] == 'product_name':
                        self.assertTrue(v['quote'], key)
                    else:
                        self.assertEqual(v['read_date'], '2026-10-13', key)
                        self.assertIn(v['evidence'], ('maker_page', 'component_maker_page'), key)

    def test_no_blocked_or_third_party_sources(self):
        blocked = ('jsb-match.com', 'rws-ammunition.com', 'chairgun', 'strelok',
                   'appliedballistics', 'jbmballistics', 'youtube', 'forum')
        for d in self.result.values():
            for s in d['sources']:
                for b in blocked:
                    self.assertNotIn(b, s['url'].lower(), s['url'])

    def test_candidates_are_labelled_estimated(self):
        p = bs.OUT / 'estimated_bc_candidates.json'
        for r in json.loads(p.read_text())['records']:
            self.assertEqual(r['label'], 'tahmini')
            self.assertGreater(r['bc_g1_tahmini'], 0)


if __name__ == '__main__':
    unittest.main()
