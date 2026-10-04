from pathlib import Path
import re
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):
        s=(Path(__file__).parents[1]/'lib/data/catalog_repository.dart').read_text()
        expected={
        'element-helix-gen2-4-16-ffp-mrad':['elevationRangeMrad:26.1','windageRangeMrad:13','sourceName:\'Element Optics\''],
        'element-helix-gen2-6-24-ffp-mrad':['elevationRangeMrad:18.9','windageRangeMrad:11.6','sourceName:\'Element Optics\''],
        'arken-ep8-1-8-klgrid-mil':['elevationRangeMrad:30','windageRangeMrad:30','sourceName:\'Arken Optics USA\''],
        }
        for ident, tokens in expected.items():
            start=s.index("id:'"+ident+"'")
            block=s[start:s.index('    ),',start)]
            for t in tokens: assert t in block,(ident,t)
        ids=re.findall(r"ScopeOptic\(\s*id:'([^']+)'",s)
        assert len(ids)==len(set(ids)), 'duplicate scope IDs'
        assert len(ids)>=35, len(ids)
        print('PASS: v159 Bozkurt Av -> official manufacturer scope expansion')


if __name__ == '__main__':
    unittest.main()
