"""Drop-error distribution (cm) that each BC estimator's cross-validated errors produce.

Research only (docs/research/tahmini_bc_hata.md). Each held-out projectile's
signed BC error (est/pub − 1, leave-one-brand-out) is applied to the example
load of its category (firearm → .277 130 gr G1 0.44 at 3000 fps; PCP slug →
6.35 mm 50 gr G1 0.140 at 985 fps; 100 m zero) and the drop change at
200/300/500 m is read from a BC-factor grid computed with the repository
reference solver. Percentiles are over projectiles.
Run: python3 -I tools/research/bc_drop_distribution.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bc_error_drop_cm as dropmod  # noqa: E402
import bc_estimator_cv as cv  # noqa: E402

LOAD_FOR = {"firearm": "firearm .277 130 gr G1 0.44, 3000 fps",
            "slug": "PCP 6.35 mm 50 gr slug G1 0.140, 985 fps"}
FACTORS = np.exp(np.linspace(np.log(0.2), np.log(3.0), 61))


def grid(load_name):
    load = dropmod.LOADS[load_name]
    base = np.array(dropmod.drops_cm(load, load["bc"]))
    rows = []
    for f in FACTORS:
        try:
            rows.append(np.array(dropmod.drops_cm(load, load["bc"] * f)) - base)
        except RuntimeError:  # stopped before 500 m
            rows.append(np.full(len(base), np.nan))
    return np.array(rows)  # [factor, range]


def signed_errors(rows, est, scheme):
    folds = cv.folds_lobo(rows) if scheme == "lobo" else cv.folds_kfold(rows, seed=0)
    out = []
    for test in folds:
        ts = set(test)
        est.fit([r for j, r in enumerate(rows) if j not in ts])
        out += [r["sd"] / est.predict(r) / r["g1"] - 1 for r in (rows[j] for j in test)]
    return np.array(out)


def main():
    plans = {
        "firearm": [cv.GlobalMedian(),
                    cv.GroupMedian("M1+2 family x SD band", lambda r: (r["fam"], cv.sd_band(r)),
                                   lambda r: r["fam"])],
        "slug": [cv.GlobalMedian(), cv.LdFam("S2 ELR keyword, else L/d", ["elr"])],
    }
    for cat, ests in plans.items():
        rows = cv.dataset(cat)
        g = grid(LOAD_FOR[cat])
        print(f"\n{cat}: {LOAD_FOR[cat]}  (leave-one-brand-out, n={len(rows)})")
        for est in ests:
            e = signed_errors(rows, est, "lobo")
            f = np.clip(1 + e, FACTORS[0], FACTORS[-1])
            cells = []
            for k, rng in enumerate(dropmod.RANGES):
                if rng <= 100:
                    continue
                d = np.abs(np.interp(np.log(f), np.log(FACTORS), g[:, k]))
                cells.append(f"{int(rng)} m: med {np.nanmedian(d):.1f} / p75 {np.nanpercentile(d, 75):.1f} / "
                             f"p90 {np.nanpercentile(d, 90):.1f} cm")
            over = np.mean(e > 0) * 100
            print(f"  {est.name:30s} BC over-estimated in {over:.0f} %;  " + ";  ".join(cells))
            # change the app's truing would need: BC_pub / BC_est − 1
            need = np.abs(1 / (1 + e) - 1)
            print(f"  {'':30s} truing change needed > 30 % (BallisticCoefficientTruing limit): "
                  f"{np.mean(need > 0.30) * 100:.1f} %;  > 20 % (DragBandTruing limit): {np.mean(need > 0.20) * 100:.1f} %")


if __name__ == "__main__":
    main()
