import copy, json, tempfile, unittest
from pathlib import Path
from validate_py_ballisticcalc_fixture import validate, POLICY

class ReferencePhysicalDomainTest(unittest.TestCase):
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

    def errors(self,d):
        with tempfile.TemporaryDirectory() as td:
            p=Path(td)/"fixture.json"; p.write_text(json.dumps(d),encoding="utf-8"); return validate(p)
    def test_rejects_nonphysical_case_inputs(self):
        for field,value in (("bc",0),("mv",-1),("grain",0),("zero",0),("sight_mm",-1)):
            d=self.fixture(); d["cases"][0][field]=value
            self.assertTrue(any(f"{field} must be > 0" in e for e in self.errors(d)), field)
    def test_rejects_nonphysical_reference_points(self):
        for field,value,msg in (("range_m",0,"range_m must be > 0"),("velocity_mps",0,"velocity_mps must be > 0"),("time_s",-1,"time_s must be > 0")):
            d=self.fixture(); d["cases"][0]["points"][0][field]=value
            self.assertTrue(any(msg in e for e in self.errors(d)), field)
    def test_rejects_invalid_atmosphere_domain(self):
        d=self.fixture(); a=next(iter(d["atmospheres"])); d["atmospheres"][a]["pressure_hpa"]=0
        self.assertTrue(any("pressure_hpa must be > 0" in e for e in self.errors(d)))
        d=self.fixture(); a=next(iter(d["atmospheres"])); d["atmospheres"][a]["humidity_percent"]=101
        self.assertTrue(any("humidity_percent must be within 0..100" in e for e in self.errors(d)))

if __name__ == "__main__": unittest.main()
