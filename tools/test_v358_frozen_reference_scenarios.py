import copy, json, tempfile, unittest
from pathlib import Path
from validate_py_ballisticcalc_fixture import validate, POLICY

class FrozenReferenceScenarioTests(unittest.TestCase):
    def fixture(self):
        policy=json.loads(POLICY.read_text(encoding='utf-8'))
        atmos={
            'icao': {'altitude_m':0.0,'temperature_c':15.0,'pressure_hpa':1013.25,'humidity_percent':0.0},
            'hot_high': {'altitude_m':1500.0,'temperature_c':30.0,'pressure_hpa':1013.25,'humidity_percent':0.0},
        }
        specs=[
            ('g1_pcp_baseline','G1','icao',.12,270.,51.,25.,60.,[25.,50.,100.,200.,300.]),
            ('g7_rifle_baseline','G7','icao',.243,800.,175.,100.,45.,[100.,300.,600.,1000.,1500.]),
            ('g1_pcp_hot_high','G1','hot_high',.12,270.,51.,25.,60.,[25.,50.,100.,200.,300.]),
            ('g7_rifle_hot_high','G7','hot_high',.243,800.,175.,100.,45.,[100.,300.,600.,1000.,1500.]),
        ]
        cases=[]
        for cid,model,atm,bc,mv,grain,zero,sight,ranges in specs:
            cases.append({'id':cid,'model':model,'atmosphere':atm,'bc':bc,'mv':mv,'grain':grain,'zero':zero,'sight_mm':sight,'points':[{'range_m':r,'height_m':0.,'velocity_mps':250.,'time_s':.1} for r in ranges]})
        return {'schema':1,'generator':'py-ballisticcalc','version':policy['reference']['version'],'engine':'rk4_engine','acceptance':policy,'atmospheres':atmos,'cases':cases}
    def errors(self,d):
        with tempfile.TemporaryDirectory() as td:
            p=Path(td)/'fixture.json'; p.write_text(json.dumps(d),encoding='utf-8'); return validate(p)
    def test_canonical_frozen_scenarios_pass(self):
        self.assertEqual([], self.errors(self.fixture()))
    def test_rejects_frozen_input_drift(self):
        mutations=[
            lambda d: d['cases'][0].__setitem__('bc',.15),
            lambda d: d['cases'][0].__setitem__('bc',.1200000001),
            lambda d: d['cases'][0].__setitem__('mv',300.),
            lambda d: d['atmospheres']['hot_high'].__setitem__('pressure_hpa',845.6),
            lambda d: d['cases'][1]['points'][0].__setitem__('range_m',101.),
            lambda d: d['cases'][0].__setitem__('id','renamed'),
            lambda d: d['cases'][0].__setitem__('wind_mps',0.),
            lambda d: d['atmospheres']['icao'].__setitem__('extra',0.),
        ]
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                d=self.fixture(); mutate(d); self.assertTrue(self.errors(d))
    def test_case_order_is_not_semantic(self):
        d=self.fixture(); d['cases'].reverse(); self.assertEqual([],self.errors(d))
    def test_rejects_extra_point_field(self):
        d=self.fixture(); d['cases'][0]['points'][0]['wind_mps']=0.; self.assertTrue(self.errors(d))

if __name__=='__main__': unittest.main()
