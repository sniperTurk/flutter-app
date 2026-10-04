#!/usr/bin/env python3
import json, math, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; POLICY=ROOT/'validation/acceptance.json'
def finite(v): return isinstance(v,(int,float)) and not isinstance(v,bool) and math.isfinite(v)

FROZEN_ATMOSPHERES = {
 'icao': {'altitude_m':0.0,'temperature_c':15.0,'pressure_hpa':1013.25,'humidity_percent':0.0},
 'hot_high': {'altitude_m':1500.0,'temperature_c':30.0,'pressure_hpa':1013.25,'humidity_percent':0.0},
}
FROZEN_CASES = {
 'g1_pcp_baseline':   {'model':'G1','atmosphere':'icao','bc':0.12,'mv':270.0,'grain':51.0,'zero':25.0,'sight_mm':60.0,'ranges':[25.0,50.0,100.0,200.0,300.0]},
 'g7_rifle_baseline': {'model':'G7','atmosphere':'icao','bc':0.243,'mv':800.0,'grain':175.0,'zero':100.0,'sight_mm':45.0,'ranges':[100.0,300.0,600.0,1000.0,1500.0]},
 'g1_pcp_hot_high':   {'model':'G1','atmosphere':'hot_high','bc':0.12,'mv':270.0,'grain':51.0,'zero':25.0,'sight_mm':60.0,'ranges':[25.0,50.0,100.0,200.0,300.0]},
 'g7_rifle_hot_high': {'model':'G7','atmosphere':'hot_high','bc':0.243,'mv':800.0,'grain':175.0,'zero':100.0,'sight_mm':45.0,'ranges':[100.0,300.0,600.0,1000.0,1500.0]},
}
CASE_FIELDS = {'id','model','atmosphere','bc','mv','grain','zero','sight_mm','points'}
POINT_FIELDS = {'range_m','height_m','velocity_mps','time_s'}
TOP_LEVEL_FIELDS = {'schema','generator','version','engine','acceptance','atmospheres','cases'}
def exact_number(v, expected):
 return finite(v) and float(v)==float(expected)
def validate(path, policy_path=POLICY):
 e=[]
 try: d=json.loads(Path(path).read_text()); p=json.loads(Path(policy_path).read_text())
 except Exception as x: return [f'cannot read fixture/policy: {x}']
 if set(d) != TOP_LEVEL_FIELDS:e.append('fixture top-level fields must exactly match fixture contract')
 if d.get('schema')!=1:e.append('fixture schema must be 1')
 if d.get('generator')!='py-ballisticcalc':e.append('generator must be py-ballisticcalc')
 if d.get('engine')!='rk4_engine':e.append('engine must be rk4_engine')
 if d.get('version')!=p.get('reference',{}).get('version'):e.append('fixture version does not match acceptance policy')
 if d.get('acceptance')!=p:e.append('embedded acceptance policy does not exactly match current policy')
 req=p.get('requirements',{}); models=set(req.get('models',[])); atmos=set(req.get('required_atmospheres',[])); defs=d.get('atmospheres',{})
 if not isinstance(defs,dict): e.append('atmospheres object is required'); defs={}
 for a in atmos:
  x=defs.get(a)
  if not isinstance(x,dict): e.append(f'missing atmosphere definition {a}'); continue
  for k in ('altitude_m','temperature_c','pressure_hpa','humidity_percent'):
   if not finite(x.get(k)):e.append(f'atmosphere {a}: invalid {k}')
  if finite(x.get('pressure_hpa')) and x['pressure_hpa'] <= 0:e.append(f'atmosphere {a}: pressure_hpa must be > 0')
  if finite(x.get('humidity_percent')) and not 0 <= x['humidity_percent'] <= 100:e.append(f'atmosphere {a}: humidity_percent must be within 0..100')
 # Freeze the independent acceptance scenario itself, not only its shape/domain.
 # Otherwise a locally edited fixture could change BC/MV/atmosphere/range inputs and
 # both comparators would merely compare against that altered scenario.
 if set(defs) != set(FROZEN_ATMOSPHERES): e.append('atmosphere definitions must exactly match frozen acceptance scenarios')
 for name,want in FROZEN_ATMOSPHERES.items():
  got=defs.get(name)
  if isinstance(got,dict):
   if set(got) != set(want): e.append(f'atmosphere {name}: fields must exactly match frozen acceptance scenario')
   for k,v in want.items():
    if not exact_number(got.get(k),v): e.append(f'atmosphere {name}: {k} differs from frozen acceptance scenario')
 cases=d.get('cases')
 if not isinstance(cases,list): e.append('cases must be a list'); return e
 if len(cases)<int(req.get('minimum_cases',0)):e.append('fixture has fewer than minimum_cases')
 if len(cases)!=len(FROZEN_CASES):e.append('fixture must contain exactly the frozen acceptance cases')
 seen=set(); ids=set(); minp=int(req.get('minimum_points_per_case',0))
 for i,c in enumerate(cases):
  if not isinstance(c,dict):e.append(f'case {i}: must be an object');continue
  cid=c.get('id'); m=c.get('model'); a=c.get('atmosphere')
  if set(c) != CASE_FIELDS:e.append(f'case {i}: fields must exactly match frozen acceptance scenario')
  if not isinstance(cid,str) or not cid:e.append(f'case {i}: id required')
  elif cid in ids:e.append(f'case {i}: duplicate id {cid}')
  else:ids.add(cid)
  if m not in models:e.append(f'case {i}: unsupported model {m}')
  if a not in atmos:e.append(f'case {i}: unsupported atmosphere {a}')
  if m in models and a in atmos:seen.add((m,a))
  for k in ('bc','mv','grain','zero','sight_mm'):
   if not finite(c.get(k)):e.append(f'case {i}: invalid {k}')
  for k in ('bc','mv','grain','zero','sight_mm'):
   if finite(c.get(k)) and c[k] <= 0:e.append(f'case {i}: {k} must be > 0')
  pts=c.get('points')
  if not isinstance(pts,list):e.append(f'case {i}: points must be a list');continue
  frozen=FROZEN_CASES.get(cid)
  if frozen is None:e.append(f'case {i}: id is not a frozen acceptance scenario: {cid}')
  else:
   for k in ('model','atmosphere'):
    if c.get(k)!=frozen[k]:e.append(f'case {i}: {k} differs from frozen acceptance scenario')
   for k in ('bc','mv','grain','zero','sight_mm'):
    if not exact_number(c.get(k),frozen[k]):e.append(f'case {i}: {k} differs from frozen acceptance scenario')
   got_ranges=[q.get('range_m') if isinstance(q,dict) else None for q in pts]
   if len(got_ranges)!=len(frozen['ranges']) or any(not exact_number(g,r) for g,r in zip(got_ranges,frozen['ranges'])):
    e.append(f'case {i}: range grid differs from frozen acceptance scenario')
  if len(pts)<minp:e.append(f'case {i}: fewer than minimum_points_per_case')
  last=-math.inf
  for j,q in enumerate(pts):
   if not isinstance(q,dict):e.append(f'case {i} point {j}: must be an object');continue
   if set(q) != POINT_FIELDS:e.append(f'case {i} point {j}: fields must exactly match fixture contract')
   for k in ('range_m','height_m','velocity_mps','time_s'):
    if not finite(q.get(k)):e.append(f'case {i} point {j}: invalid {k}')
   r=q.get('range_m')
   if finite(r):
    if r <= 0:e.append(f'case {i} point {j}: range_m must be > 0')
    if r<=last:e.append(f'case {i}: ranges must be strictly increasing')
    last=r
   if finite(q.get('velocity_mps')) and q['velocity_mps'] <= 0:e.append(f'case {i} point {j}: velocity_mps must be > 0')
   if finite(q.get('time_s')) and q['time_s'] <= 0:e.append(f'case {i} point {j}: time_s must be > 0')
 range_requirements=req.get('minimum_max_range_m_by_model',{})
 if not isinstance(range_requirements,dict) or set(range_requirements)!=models or any(not finite(v) or v<=0 for v in range_requirements.values()):
  e.append('minimum_max_range_m_by_model must define a positive finite range for every required model')
 else:
  maxima={}
  for c in cases:
   if not isinstance(c,dict):continue
   m=c.get('model'); a=c.get('atmosphere'); pts=c.get('points')
   if m not in models or a not in atmos or not isinstance(pts,list):continue
   rs=[q.get('range_m') for q in pts if isinstance(q,dict) and finite(q.get('range_m'))]
   if rs:maxima[(m,a)]=max(rs)
  for m in models:
   for a in atmos:
    if maxima.get((m,a),-math.inf)<range_requirements[m]:
     e.append(f'{m}/{a}: maximum range is below required {range_requirements[m]} m')
 if req.get('require_model_atmosphere_cross_product') is True:
  missing={(m,a) for m in models for a in atmos}-seen
  if missing:e.append('missing model-atmosphere pairs: '+', '.join(f'{m}/{a}' for m,a in sorted(missing)))
 return e
def main():
 if len(sys.argv)!=2:raise SystemExit('usage: validate_py_ballisticcalc_fixture.py FIXTURE.json')
 e=validate(Path(sys.argv[1]));
 if e: print('\n'.join('ERROR: '+x for x in e));raise SystemExit(1)
 print('PASS: py-ballisticcalc fixture schema/provenance satisfied')
if __name__=='__main__':main()
