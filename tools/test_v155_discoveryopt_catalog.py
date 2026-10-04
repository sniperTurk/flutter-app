from pathlib import Path
import re
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):
        ROOT=Path(__file__).resolve().parents[1]
        s=(ROOT/'lib/data/catalog_repository.dart').read_text()
        expected={
        'discovery-ed-prs-gen2-5-25':['elevationRangeMrad:36','windageRangeMrad:17','lengthMm:415','weightG:1260'],
        'discovery-ed-elr-gen2-5-40':['elevationRangeMrad:25','windageRangeMrad:18','lengthMm:423','weightG:1279'],
        'discovery-lhd-8-32-56':['elevationRangeMrad:36','windageRangeMrad:18','lengthMm:378','weightG:1010'],
        'discovery-hd-2-12-24':['elevationRangeMrad:33.8','windageRangeMrad:33.8','lengthMm:215','weightG:470'],
        }
        for ident, fields in expected.items():
            assert s.count("id:'"+ident+"'")==1, ident
            start=s.index("id:'"+ident+"'")
            block=s[start:s.index('    ),',start)+6]
            assert "sourceName:'DISCOVERYOPT'" in block
            assert 'official product page' in block
            for f in fields: assert f in block,(ident,f)
        assert s.count("brand:'Discovery Optics'") >= 6
        print('v155 DISCOVERYOPT catalog expansion: PASS')


if __name__ == '__main__':
    unittest.main()
