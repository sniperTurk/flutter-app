from pathlib import Path
import unittest


class CatalogExpansionRegressionTest(unittest.TestCase):
    def test_catalog_expansion_regression(self):

        ROOT = Path(__file__).resolve().parents[1]
        TEXT = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')

        EXPECTED = {
            'airmaks-krait-mkii-pro-xhp-635': ['magazineCapacity:12', 'barrelLengthMm:700', 'airCapacityCc:700', 'weightKg:4.45', "sourceName:'AirMaks Arms'"],
            'fx-dreamline-classic-45': ['caliberMm:4.5', 'magazineCapacity:22', 'airCapacityCc:220', 'barrelLengthMm:500'],
            'fx-dreamline-classic-55': ['caliberMm:5.5', 'magazineCapacity:18', 'airCapacityCc:220', 'barrelLengthMm:500'],
            'fx-dreamline-classic-635': ['caliberMm:6.35', 'magazineCapacity:16', 'airCapacityCc:290', 'barrelLengthMm:600'],
            'arken-ep5-gen2-5-25': ['elevationRangeMrad:28', 'windageRangeMrad:12', 'tubeDiameterMm:34', 'firstFocalPlane:true'],
            'arken-ep5-gen1-5-25': ['elevationRangeMrad:32', 'windageRangeMrad:16', 'tubeDiameterMm:34', 'firstFocalPlane:true'],
        }

        for record_id, fragments in EXPECTED.items():
            marker = f"id:'{record_id}'"
            assert TEXT.count(marker) == 1, f'{record_id}: expected exactly one record'
            start = TEXT.index(marker)
            end = TEXT.find('\n', start)
            if record_id.startswith('arken-'):
                end = TEXT.find('    ),', start)
            block = TEXT[start:end]
            for fragment in fragments:
                assert fragment in block, f'{record_id}: missing {fragment}'
            assert 'sourceDocument:' in block, f'{record_id}: missing provenance'

        assert TEXT.count('Rifle(id:') >= 81
        assert TEXT.count('ScopeOptic(') >= 7
        print('v154 catalog expansion regression: PASS')


if __name__ == '__main__':
    unittest.main()
