from pathlib import Path
import re
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):
        p=Path(__file__).resolve().parents[1]/'lib/data/catalog_repository.dart'
        s=p.read_text(encoding='utf-8')
        expected={
        'bushnell-xrs3-6-36-g4p':['elevationRangeMrad:29','windageRangeMrad:15',"sourceName:'Bushnell'"],
        'bushnell-dmr3-3-5-21-g4p':['elevationRangeMrad:32','windageRangeMrad:20',"sourceName:'Bushnell'"],
        'nightforce-nx8-4-32-f1':['elevationRangeMrad:26','windageRangeMrad:20',"sourceName:'Nightforce Optics'"],
        'element-titan-5-25-ffp':['elevationRangeMrad:26.2','windageRangeMrad:14.5',"sourceName:'Element Optics'"],
        'element-titan-3-18-ffp':['elevationRangeMrad:43.6','windageRangeMrad:14.5',"sourceName:'Element Optics'"],
        'primary-arms-glx-4-5-27-athena':['elevationRangeMrad:34.9066','windageRangeMrad:24.4346',"sourceName:'Primary Arms'"],
        'us-optics-fdn-25x':['tubeDiameterMm:34','minMagnification:5','maxMagnification:25',"sourceName:'U.S. Optics'"],
        }
        for ident, needles in expected.items():
            start=s.index("id:'"+ident+"'")
            block=s[start:s.index('    ),',start)+6]
            for n in needles: assert n in block,(ident,n)
        ids=[]
        ids=re.findall(r"ScopeOptic\(\s*\n?\s*id:'([^']+)'",s)
        assert len(ids)==len(set(ids)), 'duplicate scope ids'
        print(f'PASS v157 official scope expansion: {len(expected)} records; {len(ids)} total scopes')


if __name__ == '__main__':
    unittest.main()
