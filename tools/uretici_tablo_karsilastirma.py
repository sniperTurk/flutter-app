#!/usr/bin/env python3
"""Üretici tablosu karşılaştırması (docs/hesap-dogrulama/RAPOR.md).

Üreticilerin yayımladığı tablolar (CASES) ile AerodynamicTrajectorySolver'ın
satır satır Python kopyası. Rapordaki sayıları yeniden üretir; asıl doğrulama
test/uretici_tablo_dogrulama_test.dart içinde Dart kodu üzerinde yapılır.
Kullanım: python3 tools/uretici_tablo_karsilastirma.py çıktı.json
"""
# Units: unit 'yd' -> ranges yd, v fps, path in, drift in; 'm' -> m, m/s, mm, mm
HBANDS = lambda b1, b2, b3: [(2512, b1), (2232, b2), (1953, b3)]  # fps thresholds (Hornady /bc page)

CASES = [
 # ---------------- Hornady: 1.5" SH (muzzle -1.5), 200 yd zero, 24" bbl, no wind data
 dict(id='H1', maker='Hornady', name='.308 Win 168 gr ELD Match (80966)', unit='yd', mv=2700, gr=168, sh=1.5, zero=200,
      g1=0.523, g7=0.263, g1b=HBANDS(.523,.516,.498), g7b=HBANDS(.263,.259,.251), primary='g7',
      rows=[(100,2530,2.0),(200,2366,0),(300,2209,-8.2),(400,2057,-23.5),(500,1912,-47.1)]),
 dict(id='H2', maker='Hornady', name='.308 Win 178 gr ELD-X Precision Hunter (80994)', unit='yd', mv=2600, gr=178, sh=1.5, zero=200,
      g1=0.552, g7=0.278, g1b=HBANDS(.552,.543,.538), g7b=HBANDS(.278,.273,.271), primary='g7',
      rows=[(100,2443,2.2),(200,2291,0),(300,2145,-8.8),(400,2004,-25.2),(500,1868,-50.2)]),
 dict(id='H3', maker='Hornady', name='6.5 Creedmoor 140 gr ELD Match (81500)', unit='yd', mv=2710, gr=140, sh=1.5, zero=200,
      g1=0.646, g7=0.326, g1b=HBANDS(.646,.637,.616), g7b=HBANDS(.326,.320,.310), primary='g7',
      rows=[(100,2564,1.9),(200,2422,0),(300,2285,-7.8),(400,2152,-22.3),(500,2023,-44.4)]),
 dict(id='H4', maker='Hornady', name='6.5 Creedmoor 143 gr ELD-X Precision Hunter (81499)', unit='yd', mv=2700, gr=143, sh=1.5, zero=200,
      g1=0.623, g7=0.314, g1b=HBANDS(.623,.604,.584), g7b=HBANDS(.314,.303,.294), primary='g7',
      rows=[(100,2556,1.9),(200,2417,0),(300,2282,-7.9),(400,2151,-22.4),(500,2025,-44.5)]),
 dict(id='H5', maker='Hornady', name='.223 Rem 73 gr ELD Match (80269)', unit='yd', mv=2790, gr=73, sh=1.5, zero=200,
      g1=0.398, g7=0.200, g1b=HBANDS(.398,.389,.382), g7b=HBANDS(.200,.195,.192), primary='g7',
      rows=[(100,2563,1.9),(200,2348,0),(300,2143,-8.2),(400,1949,-24.0),(500,1766,-49.0)]),
 dict(id='H6', maker='Hornady', name='.300 Win Mag 178 gr ELD-X Precision Hunter (82041)', unit='yd', mv=2960, gr=178, sh=1.5, zero=200,
      g1=0.552, g7=0.278, g1b=HBANDS(.552,.543,.538), g7b=HBANDS(.278,.273,.271), primary='g7',
      rows=[(100,2789,1.5),(200,2625,0),(300,2467,-6.6),(400,2314,-18.8),(500,2166,-37.6)]),
 dict(id='H7', maker='Hornady', name='.300 Win Mag 200 gr ELD-X Precision Hunter (82002)', unit='yd', mv=2860, gr=200, sh=1.5, zero=200,
      g1=0.597, g7=0.301, g1b=HBANDS(.597,.588,.578), g7b=HBANDS(.301,.295,.291), primary='g7',
      rows=[(100,2707,1.6),(200,2558,0),(300,2414,-6.9),(400,2274,-19.9),(500,2140,-39.5)]),
 dict(id='H8', maker='Hornady', name='.338 Lapua Mag 285 gr ELD Match (82300)', unit='yd', mv=2745, gr=285, sh=1.5, zero=200,
      g1=0.829, g7=0.417, g1b=HBANDS(.829,.814,.796), g7b=HBANDS(.417,.409,.400), primary='g7',
      rows=[(100,2636,1.8),(200,2530,0),(300,2426,-7.2),(400,2324,-20.3),(500,2225,-39.8)]),
 # ---------------- Federal: 1.5" SH (stated), Long Range = 200 yd zero, Average Range = 100 yd zero, 10 mph wind
 dict(id='F1', maker='Federal', name='.308 Win 175 gr SMK Gold Medal (GM308M2)', unit='yd', mv=2600, gr=175, sh=1.5, zero=200,
      g1=0.505, g7=0.25, primary='g1', wind=10*0.44704,
      rows=[(100,2427,2.2),(200,2262,0),(300,2102,-9.1),(400,1949,-25.8),(500,1803,-51.8)],
      drift=[(100,0.6),(200,2.9),(300,6.9),(400,12.5),(500,20.3)],
      zero2=100, rows2=[(50,None,-0.1),(200,None,-4.4),(300,None,-15.7)]),
 dict(id='F2', maker='Federal', name='6.5 Creedmoor 130 gr Berger Hybrid Gold Medal (GM65CRDBH130)', unit='yd', mv=2875, gr=130, sh=1.5, zero=200,
      g1=0.560, g7=0.287, primary='g1', wind=10*0.44704,
      rows=[(100,2709,1.6),(200,2550,0),(300,2396,-6.9),(400,2247,-20.0),(500,2104,-40.0)],
      drift=[(100,0.6),(200,2.3),(300,5.2),(400,9.7),(500,15.7)],
      zero2=100, rows2=[(50,None,-0.2),(200,None,-3.2),(300,None,-11.8)]),
 dict(id='F3', maker='Federal', name='.223 Rem 69 gr SMK Gold Medal (GM223M)', unit='yd', mv=2950, gr=69, sh=1.5, zero=200,
      g1=0.301, g7=0.165, primary='g1', wind=10*0.44704,
      rows=[(100,2642,1.7),(200,2353,0),(300,2084,-8.1),(400,1832,-24.1),(500,1604,-51.0)],
      drift=[(100,1.0),(200,4.3),(300,10.3),(400,19.3),(500,32.4)],
      zero2=100, rows2=[(50,None,-0.2),(200,None,-3.5),(300,None,-13.3)]),
 dict(id='F4', maker='Federal', name='.300 Win Mag 190 gr SMK Gold Medal (GM300WM)', unit='yd', mv=2900, gr=190, sh=1.5, zero=200,
      g1=0.533, g7=0.275, primary='g1', wind=10*0.44704,
      rows=[(100,2725,1.6),(200,2557,0),(300,2395,-6.9),(400,2239,-19.9),(500,2089,-39.9)],
      drift=[(100,0.6),(200,2.4),(300,5.5),(400,10.1),(500,16.4)],
      zero2=100, rows2=[(50,None,-0.2),(200,None,-3.2),(300,None,-11.6)]),
 dict(id='F5', maker='Federal', name='.338 Lapua Mag 300 gr SMK Gold Medal (GM338LM2)', unit='yd', mv=2580, gr=300, sh=1.5, zero=200,
      g1=0.768, g7=0.387, primary='g1', wind=10*0.44704,
      rows=[(100,2466,2.1),(200,2355,0),(300,2248,-8.5),(400,2143,-23.8),(500,2040,-46.6)],
      drift=[(100,0.4),(200,1.8),(300,4.3),(400,8.0),(500,12.8)],
      zero2=100, rows2=[(50,None,-0.1),(200,None,-4.2),(300,None,-14.7)]),
 dict(id='F6', maker='Federal', name='7.62x39 123 gr JSP Power-Shok (76239B)', unit='yd', mv=2350, gr=123, sh=1.5, zero=200,
      g1=0.274, g7=None, primary='g1', wind=10*0.44704,
      rows=[(100,2055,3.4),(200,1783,0),(300,1539,-14.5),(400,1329,-43.9),(500,1164,-93.3)],
      drift=[(100,1.6),(200,6.7),(300,16.2),(400,30.7),(500,50.8)],
      zero2=100, rows2=[(50,None,0.2),(200,None,-6.7),(300,None,-24.6)]),
 # ---------------- Lapua: 40 mm SH, 4 m/s crosswind, metric, zeros 100/300/600 m
 dict(id='L1', maker='Lapua', name='6.5 Creedmoor 136 gr Scenar-L (4316063)', unit='m', mv=835, gr=136, sh=40, zero=100,
      g1=0.545, g7=0.274, primary='g7', wind=4.0,
      rows=[(100,780,0),(200,725,-122),(300,673,-430),(600,529,-2814),(800,446,-6087),(1000,375,-11351)],
      drift=[(100,19),(200,76),(300,179),(600,807),(800,1564),(1000,2671)],
      zeros=[(300,[(100,143),(200,165),(600,-1953),(800,-4939),(1000,-9916)]),
             (600,[(100,469),(200,816),(300,976),(800,-2335),(1000,-6661)])]),
 dict(id='L2', maker='Lapua', name='.308 Win 185 gr Scenar GB432 (4317523)', unit='m', mv=755, gr=185, sh=40, zero=100,
      g1=0.482, g7=0.242, primary='g7', wind=4.0,
      rows=[(100,697,0),(200,640,-162),(300,585,-563),(600,438,-3735),(800,356,-8288)],
      drift=[(100,21),(200,88),(300,207),(600,963),(800,1898)],
      zeros=[(300,[(100,188),(200,214),(600,-2609),(800,-6787)])]),
 dict(id='L3', maker='Lapua', name='.308 Win 167 gr Scenar GB422 (4317515)', unit='m', mv=820, gr=167, sh=40, zero=100,
      g1=0.446, g7=0.223, primary='g7', wind=4.0,
      rows=[(100,754,0),(200,690,-132),(300,628,-470),(600,459,-3212),(800,364,-7258)],
      drift=[(100,20),(200,85),(300,200),(600,946),(800,1899)],
      zeros=[(300,[(100,157),(200,181),(600,-2271),(800,-6003)]),
             (600,[(100,535),(200,938),(300,1135),(800,-2975)])]),
 dict(id='L4', maker='Lapua', name='.338 Lapua Mag 250 gr Scenar GB488 (4318017)', unit='m', mv=905, gr=250, sh=40, zero=100,
      g1=0.648, g7=0.322, primary='g7', wind=4.0,
      rows=[(100,856,0),(200,808,-93),(300,762,-336),(600,631,-2164),(800,551,-4570),(1000,477,-8274),(1200,409,-13721),(1500,328,-26585)],
      drift=[(100,12),(200,48),(300,112),(600,495),(800,944),(1000,1489),(1200,2489),(1500,4392)],
      zeros=[(300,[(100,112),(200,131),(600,-1493),(800,-3674),(1000,-7155),(1200,-12377),(1500,-24904)]),
             (600,[(100,361),(200,628),(300,746),(800,-1684),(1000,-4667),(1200,-9390),(1500,-21168)])]),
 dict(id='L5', maker='Lapua', name='.338 Lapua Mag 300 gr Scenar GB528 (4318013)', unit='m', mv=820, gr=300, sh=40, zero=100,
      g1=0.736, g7=0.368, primary='g7', wind=4.0,
      rows=[(100,780,0),(200,741,-122),(300,703,-422),(600,597,-2609),(800,532,-5404),(1000,471,-9595),(1200,416,-15565),(1500,344,-29006)],
      drift=[(100,12),(200,47),(300,109),(600,469),(800,880),(1000,1457),(1200,2245),(1500,3852)],
      zeros=[(300,[(100,141),(200,160),(600,-1765),(800,-4278),(1000,-8188),(1200,-13876),(1500,-26894)]),
             (600,[(100,421),(200,725),(300,855),(800,-1865),(1000,-5082),(1200,-10021),(1500,-21766)])]),
 # ---------------- Berger ammo: 26" bbl, sea level, 200 yd zero implied, SH not stated (1.5" assumed)
 dict(id='B1', maker='Berger', name='6.5 Creedmoor 140 gr Hybrid Target (31011)', unit='yd', mv=2750, gr=140, sh=1.5, zero=200,
      g1=0.607, g7=0.311, primary='g7', rows=[(100,2602,1.82),(200,2459,0),(300,2320,-7.58),(400,2186,-21.61)]),
 dict(id='B2', maker='Berger', name='.308 Win 185 gr Juggernaut OTM Tactical (60050)', unit='yd', mv=2608, gr=185, sh=1.5, zero=200,
      g1=0.552, g7=0.283, primary='g7', rows=[(100,2450,2.15),(200,2298,0),(300,2152,-8.73),(400,2011,-24.98)]),
 dict(id='B3', maker='Berger', name='.338 Lapua Mag 300 gr Hybrid OTM Tactical (81110)', unit='yd', mv=2725, gr=300, sh=1.5, zero=200,
      g1=0.822, g7=0.421, primary='g7', rows=[(100,2616,1.78),(200,2509,0),(300,2405,-7.3),(400,2304,-20.6)]),
 # ---------------- Norma Bondstrike: G1 only, 40 mm SH, 100 m zero row
 dict(id='N1', maker='Norma', name='.308 Win 180 gr Bondstrike (20176412)', unit='m', mv=800, gr=180, sh=40, zero=100,
      g1=0.615, g7=None, primary='g1',
      rows=[(50,None,0),(80,None,5),(100,752,0),(150,None,-44),(200,707,-133),(300,662,-464)]),
 dict(id='N2', maker='Norma', name='6.5 Creedmoor 143 gr Bondstrike (20166402)', unit='m', mv=835, gr=143, sh=40, zero=100,
      g1=0.629, g7=None, primary='g1',
      rows=[(50,None,-1),(80,None,4),(100,786,0),(150,None,-38),(200,739,-118),(300,694,-415)]),
 dict(id='N3', maker='Norma', name='.300 Win Mag 180 gr Bondstrike (20176332)', unit='m', mv=940, gr=180, sh=40, zero=100,
      g1=0.615, g7=None, primary='g1',
      rows=[(50,None,-5),(80,None,1),(100,887,0),(150,None,-26),(200,837,-85),(300,788,-310)]),
]
import math, sys, json
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent))
from offline_solver_crosscheck import load_tables, cd_at

T = load_tables()
G = 9.80665; LB = 703.0695796391593; DT = 0.0005
YD = 0.9144; FPS = 0.3048; IN = 0.0254
STD = dict(t=15.0, p=1013.25, rh=0.0)

def air(e):
    tk = e['t'] + 273.15
    pv = 6.112 * math.exp(17.62 * e['t'] / (243.12 + e['t'])) * 100 * e['rh'] / 100
    pt = e['p'] * 100
    rho = (pt - pv) / (287.05 * tk) + pv / (461.495 * tk)
    return rho, math.sqrt(1.4 * pt / rho)

def bcfun(bc, bands):
    if not bands: return lambda v: bc
    b = sorted(bands, key=lambda x: -x[0])
    def f(v):
        for th, val in b:
            if v >= th: return val
        return b[-1][1]
    return f

def deriv(s, tab, bcf, rho, a, w, wdir):
    x, y, z, vx, vy, vz = s
    d = wdir * math.pi / 180
    ax = -w * math.cos(d); az = w * math.sin(d)
    rx, ry, rz = vx - ax, vy, vz - az
    v = math.sqrt(rx*rx + ry*ry + rz*rz)
    cd = cd_at(tab, v / a)
    dec = 0.5 * rho * cd * (math.pi / 4) * v * v / (bcf(v) * LB)
    k = -dec / v if v else 0
    return (vx, vy, vz, k*rx, k*ry - G, k*rz)

def step(s, f):
    k1 = f(s); k2 = f(tuple(a + b*DT/2 for a, b in zip(s, k1)))
    k3 = f(tuple(a + b*DT/2 for a, b in zip(s, k2))); k4 = f(tuple(a + b*DT for a, b in zip(s, k3)))
    return tuple(a + DT/6*(p + 2*q + 2*r + u) for a, p, q, r, u in zip(s, k1, k2, k3, k4))

def solve(model, bc, bands, mv, sh_m, zero_m, ranges, w=0.0, wdir=90.0, env=STD):
    tab = T[model]; bcf = bcfun(bc, bands)
    rho0, a0 = air(STD); rho, a = air(env)
    f0 = lambda s: deriv(s, tab, bcf, rho0, a0, 0, 90)
    def h(ang):
        s = (0, -sh_m, 0, mv*math.cos(ang), mv*math.sin(ang), 0)
        while True:
            p = s; s = step(s, f0)
            if s[0] >= zero_m:
                fr = (zero_m - p[0]) / (s[0] - p[0]); return p[1] + (s[1]-p[1])*fr
    lo, hi = -0.05, 0.25; ylo = h(lo)
    for _ in range(60):
        mid = (lo+hi)/2; ym = h(mid)
        if abs(ym) < 1e-8: break
        if (ym > 0) == (ylo > 0): lo, ylo = mid, ym
        else: hi = mid
    ang = (lo+hi)/2 if abs(ym) >= 1e-8 else mid
    f = lambda s: deriv(s, tab, bcf, rho, a, w, wdir)
    s = (0, -sh_m, 0, mv*math.cos(ang), mv*math.sin(ang), 0); t = 0
    want = sorted(ranges); out = {}; i = 0
    while i < len(want):
        p, pt = s, t; s = step(s, f); t += DT
        while i < len(want) and s[0] >= want[i]:
            r = want[i]; fr = (r - p[0])/(s[0]-p[0]); L = lambda k: p[k] + (s[k]-p[k])*fr
            out[r] = dict(drop=-L(1), z=L(2), v=math.sqrt(L(3)**2+L(4)**2+L(5)**2), t=pt+DT*fr)
            i += 1
    return out

def run_case(c, model, bands=None):
    yd = c['unit'] == 'yd'
    rs = lambda r: r*YD if yd else float(r)
    mv = c['mv']*FPS if yd else c['mv']
    sh = c['sh']*IN if yd else c['sh']/1000
    bc = c[model]
    b = [(th*FPS, v) for th, v in bands] if bands else None
    res = []
    tables = [(c['zero'], c['rows'])]
    if 'zero2' in c: tables.append((c['zero2'], c['rows2']))
    for z, rows in [(c['zero'], c['rows'])] + ([(c['zero2'], c['rows2'])] if 'zero2' in c else []) + [(zz, [(r, None, p) for r, p in rr]) for zz, rr in c.get('zeros', [])]:
        out = solve(model, bc, b, mv, sh, rs(z), [rs(r) for r, _, _ in rows])
        for r, v, p in rows:
            o = out[rs(r)]
            path_m = -o['drop']; pub_m = p*IN if yd else p/1000
            d = path_m - pub_m
            res.append(dict(zero=z, r=r, rm=rs(r), pub=p, calc=path_m/IN if yd else path_m*1000,
                            dcm=d*100, dmrad=d/rs(r)*1000,
                            vpub=v, vcalc=(o['v']/FPS if yd else o['v']) if v else None))
    dr = []
    if c.get('wind') and c.get('drift'):
        out = solve(model, bc, b, mv, sh, rs(c['zero']), [rs(r) for r, _ in c['drift']], w=c['wind'], wdir=90)
        for r, p in c['drift']:
            calc = out[rs(r)]['z']
            calc_u = calc/IN if yd else calc*1000
            pub_m = p*IN if yd else p/1000
            dr.append(dict(r=r, pub=p, calc=calc_u, dcm=(calc-pub_m)*100, dmrad=(calc-pub_m)/rs(r)*1000))
    return dict(path=res, drift=dr)

if __name__ == '__main__':
    allres = {}
    for c in CASES:
        for m in ('g1', 'g7'):
            if not c.get(m): continue
            allres[f"{c['id']}:{m}"] = run_case(c, m)
            if c.get(m+'b'):
                allres[f"{c['id']}:{m}b"] = run_case(c, m, c[m+'b'])
        print(c['id'], 'done', file=sys.stderr)
    json.dump(allres, open(sys.argv[1], 'w'), indent=1)
