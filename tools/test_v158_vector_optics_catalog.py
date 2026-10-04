from pathlib import Path
import re
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):

        ROOT = Path(__file__).resolve().parents[1]
        TEXT = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')
        EXPECTED = {
         'vector-continental-x6-6-36-scff70': ['SCFF-70', 'elevationRangeMrad:31', "reticle:'VEC-MBR2 MIL'"],
         'vector-continental-x10-1-10-scff68': ['SCFF-68', 'lengthMm:278', 'weightG:651'],
         'vector-tauron-6-24-scff81': ['SCFF-81', 'elevationRangeMrad:32', "reticle:'VTA-3 MIL'"],
         'vector-veyron-gen2-6-24-scff74': ['SCFF-74', 'elevationRangeMrad:25', 'lengthMm:277'],
         'vector-tauron-5-40-scff35': ['SCFF-35', 'lengthMm:365', 'weightG:978'],
         'vector-tauron-3-24-scff33': ['SCFF-33', 'elevationRangeMrad:30', "reticle:'VTA-5 MIL'"],
        }
        for scope_id, tokens in EXPECTED.items():
            assert TEXT.count("id:'" + scope_id + "'") == 1, scope_id
            start=TEXT.index("id:'" + scope_id + "'")
            end=TEXT.index('    ),', start)
            block=TEXT[start:end]
            assert "sourceName:'Vector Optics'" in block
            assert 'verified 2026-09-27' in block
            for token in tokens: assert token in block, (scope_id, token)
        ids=re.findall(r"ScopeOptic\(\s*id:'([^']+)'", TEXT)
        assert len(ids)==len(set(ids)), 'duplicate scope ids'
        assert len(ids) >= 32, len(ids)
        print('PASS: v158 Vector Optics official catalog expansion')


if __name__ == '__main__':
    unittest.main()
