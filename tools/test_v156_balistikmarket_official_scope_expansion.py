from pathlib import Path
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):
        src=(Path(__file__).parents[1]/'lib/data/catalog_repository.dart').read_text()
        expected={
        'bushnell-match-pro-ed-5-30':'Bushnell',
        'nightforce-atacr-7-35-f1-milc':'Nightforce Optics',
        'element-helix-4-16-ffp-mrad':'Element Optics',
        'dnt-theone-7-35-tor':'DNT Optics',
        'riton-7-conquer-4-32':'Riton Optics',
        'primary-arms-plxc-1-8-griffin':'Primary Arms',
        'elcan-specterdr-1-4':'Armament Technology / ELCAN',
        'meopta-optika6-5-30-mrad':'Meopta',
        }
        for ident, source in expected.items():
            assert src.count("id:'"+ident+"'")==1, ident
            start=src.index("id:'"+ident+"'")
            chunk=src[start:start+1200]
            assert "sourceName:'"+source+"'" in chunk, ident
            assert 'verified 2026-09-27' in chunk, ident
        print(f'PASS: {len(expected)} manufacturer-sourced Balistik Market scope records locked')


if __name__ == '__main__':
    unittest.main()
