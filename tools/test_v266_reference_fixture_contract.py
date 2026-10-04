import json, tempfile, unittest
from pathlib import Path
from validate_py_ballisticcalc_fixture import validate, POLICY

class ReferenceFixtureContractTests(unittest.TestCase):
    def fixture(self):
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

    def run_fixture(self,d):
        with tempfile.TemporaryDirectory() as td:
            p=Path(td)/'v.json'; p.write_text(json.dumps(d)); return validate(p)
    def test_current_generator_contract_shape_passes(self): self.assertEqual([], self.run_fixture(self.fixture()))
    def test_missing_cross_product_fails(self):
        d=self.fixture(); d['cases'].pop(); self.assertTrue(any('missing model-atmosphere' in e for e in self.run_fixture(d)))
    def test_policy_drift_fails(self):
        d=self.fixture(); d['acceptance']['tolerances']['height_m_absolute']=999; self.assertTrue(any('acceptance policy' in e for e in self.run_fixture(d)))
    def test_insufficient_model_range_fails(self):
        d=self.fixture(); g7=next(c for c in d['cases'] if c['model']=='G7'); g7['points'][-1]['range_m']=1200
        self.assertTrue(any('maximum range is below required' in x for x in self.run_fixture(d)))
    def test_duplicate_or_unsorted_points_fail(self):
        d=self.fixture(); d['cases'][0]['id']=d['cases'][1]['id']; d['cases'][1]['points'][1]['range_m']=1
        e=self.run_fixture(d); self.assertTrue(any('duplicate id' in x for x in e)); self.assertTrue(any('strictly increasing' in x for x in e))
if __name__=='__main__': unittest.main()
