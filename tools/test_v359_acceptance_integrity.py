import copy, importlib.util, json, tempfile, unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
VP=ROOT/'tools'/'validate_py_ballisticcalc_fixture.py'
GP=ROOT/'tools'/'generate_reference_vectors.py'
DP=ROOT/'tools'/'compare_reference_vectors.dart'
spec=importlib.util.spec_from_file_location('fixture_validator',VP); mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

def canonical_fixture():
    policy=json.loads((ROOT/'validation'/'acceptance.json').read_text())
    return {'schema':1,'generator':'py-ballisticcalc','version':policy['reference']['version'],'engine':'rk4_engine','acceptance':policy,
            'atmospheres':copy.deepcopy(mod.FROZEN_ATMOSPHERES),'cases':[
                {'id':cid,**{k:copy.deepcopy(v) for k,v in c.items() if k!='ranges'},'points':[
                    {'range_m':r,'height_m':0.0,'velocity_mps':1.0,'time_s':1.0} for r in c['ranges']]}
                for cid,c in mod.FROZEN_CASES.items()]}

class AcceptanceIntegrityV359(unittest.TestCase):
    def validate(self,d):
        with tempfile.NamedTemporaryFile('w',suffix='.json',delete=False) as f:
            json.dump(d,f); path=f.name
        try:return mod.validate(path)
        finally:Path(path).unlink(missing_ok=True)
    def test_unknown_top_level_fields_fail_closed(self):
        for key in ('wind_mps','provenance'):
            d=canonical_fixture(); d[key]=0 if key=='wind_mps' else 'forged'
            self.assertTrue(self.validate(d),key)
    def test_generator_uses_canonical_frozen_contract(self):
        s=GP.read_text(encoding='utf-8')
        self.assertIn('FROZEN_ATMOSPHERES, FROZEN_CASES, validate',s)
        self.assertIn('ranges_by_case',s)
        self.assertNotIn('ranges_by_model =',s)
    def test_dart_comparator_requires_canonical_validator(self):
        s=DP.read_text(encoding='utf-8')
        self.assertIn('validate_py_ballisticcalc_fixture.py',s)
        self.assertIn("Process.runSync(\n    'python3'",s)
        self.assertIn('canonical fixture validation failed',s)

if __name__=='__main__':unittest.main()
