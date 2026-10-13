"""How well shot-based truing pins a G1 BC (research only).

docs/research/tahmini_bc_hata.md §B.3. Uses the repository reference solver
`tools/formula_reference.py` (point mass, CIPM air at ICAO conditions, 100 m
zero, no wind) for the two example loads of bc_error_drop_cm.py.

(a) Two chronograph velocities: one chronograph, a string at the muzzle and a
    string at distance x (Courtney, Courtney & Courtney, arXiv:1503.05504).
    BC is solved by bisection so the solver's velocity at x equals the far mean.
(b) Drop at a far range R: BC solved so the predicted elevation correction at R
    equals the observed group centre (what BallisticCoefficientTruing does).

Each method's 1-sigma BC error is propagated linearly from the input errors
listed in ASSUMPTIONS (finite differences through the full solver), then the
residual drop error at 300/500 m is computed. A second part quantifies the
"drag-shape" error: the truth follows a different drag law (G7 for the
boat-tail bullet; G7 or a constant Cd for the slug), the G1 BC is fitted with
noise-free data, and the remaining drop error at 300/500 m is reported.
Run: python3 -I tools/research/bc_truing_error.py
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import formula_reference as fr  # noqa: E402

G1 = fr.Pchip(fr.load_table("g1"))
G7 = fr.Pchip(fr.load_table("g7"))
FLAT = fr.Pchip([(0.0, 0.25), (5.0, 0.25)])  # constant Cd (shape only; scale is absorbed by BC)

LOADS = {
    "firearm": dict(model="g1", bc=0.44, grain=130.0, caliber_in=0.277, mv_mps=3000 * fr.FOOT_M,
                    zero_m=100.0, sight_mm=45.0),
    "slug": dict(model="g1", bc=0.140, grain=50.0, caliber_in=0.25, mv_mps=985 * fr.FOOT_M,
                 zero_m=100.0, sight_mm=50.0),
}

# 1-sigma input errors (assumptions, stated in the report). Shot-to-shot
# values are per shot; means use n shots.
ASSUMPTIONS = {
    "firearm": dict(v_sd=3.0, n_v=10, y_sd_mrad=0.15, n_y=10, chrono_scale=0.005, lrf_m=1.0,
                    tape_m=0.1, zero_mrad=0.05, sight_mm=2.0),
    "slug": dict(v_sd=1.5, n_v=10, y_sd_mrad=0.25, n_y=10, chrono_scale=0.005, lrf_m=1.0,
                 tape_m=0.1, zero_mrad=0.05, sight_mm=2.0),
}


def fly(load: dict, bc: float, cd=G1, ranges=(100.0,), mv=None, sight_mm=None, zero_shift=0.0):
    """(drop cm, velocity m/s) at each range. zero_shift: mrad added to the bore angle."""
    ld = dict(load, bc=bc)
    if mv is not None:
        ld["mv_mps"] = mv
    if sight_mm is not None:
        ld["sight_mm"] = sight_mm
    sc = fr.Scenario("x", **ld, ranges=tuple(ranges))
    # zero with the nominal load (the rifle's bore angle does not change)
    zsc = fr.Scenario("z", **dict(load, bc=bc), ranges=(load["zero_m"],))
    alpha = fr.zero_angle(zsc, cd, "cipm") + zero_shift / 1000
    axes = fr._axes(0.0, 0.0)
    model = fr._model(sc, sc.env, cd, False, "cipm")
    hits = fr._fly(model, fr._launch(sc, alpha, axes), axes[0], list(ranges), rtol=1e-9, atol=1e-9)
    out = []
    for r, (_t, s) in zip(sorted(ranges), hits):
        y = fr._dot(s[:3], axes[1])
        corr = math.atan2(-y, r) * 1000
        out.append((corr * r / 10, math.sqrt(s[3] ** 2 + s[4] ** 2 + s[5] ** 2)))
    return out


def bisect(f, target, lo, hi, it=50):
    """Root of f(b) = target for monotone f on [lo, hi]."""
    flo = f(lo) - target
    for _ in range(it):
        mid = (lo + hi) / 2
        fm = f(mid) - target
        if (fm > 0) == (flo > 0):
            lo, flo = mid, fm
        else:
            hi = mid
    return (lo + hi) / 2


def fit_bc_velocity(load, x, vx, cd=G1, mv=None):
    return bisect(lambda b: fly(load, b, cd, (x,), mv=mv)[0][1], vx, 0.2 * load["bc"], 5 * load["bc"])


def fit_bc_drop(load, R, drop_cm, cd=G1, **kw):
    return bisect(lambda b: fly(load, b, cd, (R,), **kw)[0][0], drop_cm, 0.2 * load["bc"], 5 * load["bc"])


def method_a(name):
    load, a = LOADS[name], ASSUMPTIONS[name]
    bc = load["bc"]
    seps = (50.0, 100.0) if name == "slug" else (100.0, 200.0, 300.0)
    rows = []
    for x in seps:
        vx = fly(load, bc, ranges=(x,))[0][1]
        v0 = load["mv_mps"]
        loss = 1 - vx / v0
        # sensitivities (relative BC change per relative change of the input)
        dv = 0.001
        s_vx = (fit_bc_velocity(load, x, vx * (1 + dv)) / bc - 1) / dv
        s_v0 = (fit_bc_velocity(load, x, vx, mv=v0 * (1 + dv)) / bc - 1) / dv
        s_x = (fit_bc_velocity(load, x * 1.001, vx) / bc - 1) / 0.001
        sem = a["v_sd"] / math.sqrt(a["n_v"])
        parts = {
            "far mean (SEM)": s_vx * sem / vx,
            "near mean (SEM)": s_v0 * sem / v0,
            "tape ±0.1 m": s_x * a["tape_m"] / x,
        }
        # A common chronograph scale error multiplies v0 and vx alike: cancels.
        both = (fit_bc_velocity(load, x, vx * 1.005, mv=v0 * 1.005) / bc - 1)
        total = math.sqrt(sum(p * p for p in parts.values()))
        lrf = s_x * a["lrf_m"] / x
        rows.append(dict(x=x, vx=vx, loss=loss, sens_vx=s_vx, parts=parts, total=total,
                         scale_cancel=both, lrf_instead_of_tape=math.sqrt(total**2 - parts["tape ±0.1 m"]**2 + lrf**2)))
    return rows


def method_b(name):
    load, a = LOADS[name], ASSUMPTIONS[name]
    bc = load["bc"]
    Rs = (200.0, 300.0, 400.0, 500.0) if name == "firearm" else (150.0, 200.0, 300.0)
    rows = []
    for R in Rs:
        d0 = fly(load, bc, ranges=(R,))[0][0]

        def rel(**kw):
            # BC the shooter would fit (nominal model) if reality differed by kw
            dd = fly(load, bc, ranges=(R,), **kw)[0][0]
            return fit_bc_drop(load, R, dd) / bc - 1

        sem_y = a["y_sd_mrad"] / math.sqrt(a["n_y"])
        mv = load["mv_mps"]
        mv_sigma = math.hypot(a["v_sd"] / math.sqrt(a["n_v"]), a["chrono_scale"] * mv)
        parts = {
            "group centre (SEM)": fit_bc_drop(load, R, d0 + sem_y * R / 10) / bc - 1,
            "MV (SEM + chrono scale)": rel(mv=mv + mv_sigma),
            # the target is really at R+1 m; the shooter enters R (angular correction kept)
            "range ±1 m (LRF)": fit_bc_drop(
                load, R, fly(load, bc, ranges=(R + a["lrf_m"],))[0][0] * R / (R + a["lrf_m"])) / bc - 1,
            "zero ±0.05 mrad": rel(zero_shift=a["zero_mrad"]),
            "sight height ±2 mm": rel(sight_mm=load["sight_mm"] + a["sight_mm"]),
        }
        total = math.sqrt(sum(p * p for p in parts.values()))
        # residual drop error at 300 and 500 m from that BC error
        res = []
        for T in (300.0, 500.0):
            dT = fly(load, bc, ranges=(T,))[0][0]
            dT2 = fly(load, bc * (1 + total), ranges=(T,))[0][0]
            res.append(abs(dT2 - dT))
        sens = (fly(load, bc * 1.1, ranges=(R,))[0][0] - d0) / (R / 10)  # mrad per +10 % BC
        rows.append(dict(R=R, parts=parts, total=total, residual_cm=res, mrad_per_10pct=sens))
    return rows


def shape_error(name):
    """Truth follows another drag law; the shooter fits G1 from (a) or (b)."""
    load = LOADS[name]
    truths = [("G7", G7)] if name == "firearm" else [("G7", G7), ("constant Cd", FLAT)]
    x = 100.0 if name == "firearm" else 50.0
    out = []
    for tname, cd in truths:
        # truth BC on its own law chosen so velocity at x matches the nominal G1 load
        v_nom = fly(load, load["bc"], ranges=(x,))[0][1]
        bc_t = fit_bc_velocity(load, x, v_nom, cd=cd)
        truth = fly(load, bc_t, cd, (300.0, 500.0))
        # (a) near/far velocities at x → G1 BC
        bc_a = fit_bc_velocity(load, x, fly(load, bc_t, cd, (x,))[0][1])
        pa = fly(load, bc_a, ranges=(300.0, 500.0))
        # (b) drop at 300 m → G1 BC
        bc_b = fit_bc_drop(load, 300.0, truth[0][0])
        pb = fly(load, bc_b, ranges=(300.0, 500.0))
        out.append(dict(truth=tname, x=x,
                        a_err_cm=[abs(p[0] - t[0]) for p, t in zip(pa, truth)],
                        b_err_cm=[abs(p[0] - t[0]) for p, t in zip(pb, truth)],
                        bc_a=bc_a, bc_b=bc_b))
    return out


def main():
    for name in LOADS:
        print(f"\n===== {name}: {LOADS[name]}")
        print("(a) two velocities, one chronograph moved downrange")
        for r in method_a(name):
            parts = ", ".join(f"{k} {v*100:+.2f}%" for k, v in r["parts"].items())
            print(f"  x={r['x']:.0f} m  v_x={r['vx']:.1f} m/s  loss {r['loss']*100:.1f}%  "
                  f"dBC/BC per dv/v = {r['sens_vx']:.1f}  → σ_BC {r['total']*100:.2f}%  "
                  f"(LRF instead of tape {r['lrf_instead_of_tape']*100:.2f}%)  [{parts}]  "
                  f"common 0.5% scale error → {r['scale_cancel']*100:+.3f}%")
        print("(b) drop at range R")
        for r in method_b(name):
            parts = ", ".join(f"{k} {abs(v)*100:.2f}%" for k, v in r["parts"].items())
            print(f"  R={r['R']:.0f} m  +10% BC moves {abs(r['mrad_per_10pct']):.2f} mrad  σ_BC {r['total']*100:.2f}%  "
                  f"→ residual drop σ 300 m {r['residual_cm'][0]:.1f} cm, 500 m {r['residual_cm'][1]:.1f} cm  [{parts}]")
        print("drag-shape error (noise-free fit, truth on another law)")
        for r in shape_error(name):
            print(f"  truth {r['truth']}: (a) fit at {r['x']:.0f} m → error 300 m {r['a_err_cm'][0]:.1f} cm, "
                  f"500 m {r['a_err_cm'][1]:.1f} cm;  (b) fit at 300 m → 300 m {r['b_err_cm'][0]:.1f} cm, "
                  f"500 m {r['b_err_cm'][1]:.1f} cm")


if __name__ == "__main__":
    main()
