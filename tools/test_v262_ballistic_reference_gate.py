import json
import tempfile
import unittest
from pathlib import Path

from validate_ballistic_reference_vectors import validate
from validate_py_ballisticcalc_fixture import POLICY


class GateTest(unittest.TestCase):
    def _fixture(self):
        policy=json.loads(POLICY.read_text(encoding="utf-8"))
        atmos={
            "icao":{"altitude_m":0.0,"temperature_c":15.0,"pressure_hpa":1013.25,"humidity_percent":0.0},
            "hot_high":{"altitude_m":1500.0,"temperature_c":30.0,"pressure_hpa":1013.25,"humidity_percent":0.0},
        }
        specs=[
            ("g1_pcp_baseline","G1","icao",0.12,270.0,51.0,25.0,60.0,[25.,50.,100.,200.,300.]),
            ("g7_rifle_baseline","G7","icao",0.243,800.0,175.0,100.0,45.0,[100.,300.,600.,1000.,1500.]),
            ("g1_pcp_hot_high","G1","hot_high",0.12,270.0,51.0,25.0,60.0,[25.,50.,100.,200.,300.]),
            ("g7_rifle_hot_high","G7","hot_high",0.243,800.0,175.0,100.0,45.0,[100.,300.,600.,1000.,1500.]),
        ]
        cases=[]
        for cid,model,atm,bc,mv,grain,zero,sight,ranges in specs:
            cases.append({"id":cid,"model":model,"atmosphere":atm,"bc":bc,"mv":mv,"grain":grain,"zero":zero,"sight_mm":sight,"points":[{"range_m":r,"height_m":0.0,"velocity_mps":250.0,"time_s":0.1} for r in ranges]})
        return {"schema":1,"generator":"py-ballisticcalc","version":policy["reference"]["version"],"engine":"rk4_engine","acceptance":policy,"atmospheres":atmos,"cases":cases}

    def _validate(self, fixture):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fixture.json'
            path.write_text(json.dumps(fixture), encoding='utf-8')
            return validate(path)

    def test_legacy_entry_point_accepts_current_canonical_fixture(self):
        self.assertEqual([], self._validate(self._fixture()))

    def test_obsolete_vectors_shape_is_rejected(self):
        obsolete = {
            'generated_by_sniper_turk': False,
            'source': {'name': 'independent', 'url': 'https://example.invalid/reference'},
            'vectors': [],
        }
        self.assertTrue(self._validate(obsolete))

    def test_policy_drift_is_rejected(self):
        fixture = self._fixture()
        fixture['acceptance']['tolerances']['height_m_absolute'] = 999
        self.assertTrue(any('acceptance policy' in error for error in self._validate(fixture)))


if __name__ == '__main__':
    unittest.main()
