from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
TEXT = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')

class V308AselkonCatalogProvenanceTest(unittest.TestCase):
    def test_aselkon_current_variants_are_locked(self):
        models = ['mx10-black','mx10-camo-max5','mx10-wood','mx10-s-black','mx10-s-camo-max5','mx10-s-wood']
        for model in models:
            for caliber in ['45','55','635']:
                self.assertIn(f"id:'aselkon-{model}-{caliber}'", TEXT)
        self.assertEqual(TEXT.count("brand:'Aselkon Arms'"), 18)
        self.assertGreaterEqual(TEXT.count('aselkonarms.com/urun/pcp-'), 18)

    def test_no_unverified_aselkon_family_was_inferred(self):
        for name in ['Ravello RX5','Ravello RX6','EMPERADOR LS1','EMPERADOR LS2','EMPERADOR LS3','EMPERADOR LS4']:
            self.assertNotIn(f"brand:'Aselkon Arms', model:'{name}'", TEXT)

if __name__ == '__main__':
    unittest.main()
