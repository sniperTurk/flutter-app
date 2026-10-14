#!/usr/bin/env python3
"""BC geliştirme (2026-10-14): back-solve a G1/G7 BC from a maker's own
published downrange-velocity table.

Input : data/bc_gelistirme/velocity_tables.json (values read from maker pages,
        each with source URL, read date and quote).
Output: data/bc_gelistirme/backsolve_results.csv and a summary on stdout.

Method: flat-fire point-mass velocity decay dv/dx = -rho*Cd(M)*v*pi/(8*BC*703.07)
(BC in lb/in^2, x along the path), integrated with RK4 (1 m step); BC found by
bisection so that v(x_last) equals the published value. Done for G1 and G7 in
two standard atmospheres (Army Standard Metro and ICAO). Per-distance BCs are
reported too: if they drift with distance, the table was not made with that
drag function (or was rounded / measured). G1/G7 tables are read from
lib/core/standard_drag_tables.dart so the app's own drag functions are used.

Usage: python3 tools/research/bc_backsolve.py
"""
from __future__ import annotations

import csv
import json
import math
import re
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "bc_gelistirme"

YD = 0.9144
FPS = 0.3048
BC_SI = 703.0696  # lb/in^2 -> kg/m^2

# Atmospheres: (density kg/m^3, speed of sound m/s)
ATMOS = {
    # Army Standard Metro: 59 F, 29.53 inHg, 78 % RH -> 0.0751265 lb/ft^3;
    # speed of sound 1120.27 ft/s as used in the classic BRL tables.
    "ASM": (0.0751265 * 16.01846, 1120.27 * FPS),
    # ICAO: 15 C, 1013.25 hPa, dry.
    "ICAO": (1.2250, 340.294),
}


def load_tables() -> dict[str, list[tuple[float, float]]]:
    text = (ROOT / "lib/core/standard_drag_tables.dart").read_text(encoding="utf-8")
    out = {}
    for name in ("g1", "g7"):
        m = re.search(r"static final " + name + r" = DragTable\(const \[(.*?)\]\);", text, re.S)
        pts = re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", m.group(1))
        out[name] = [(float(a), float(b)) for a, b in pts]
    return out


def cd_at(tab, mach: float) -> float:
    if mach <= tab[0][0]:
        return tab[0][1]
    for (m0, c0), (m1, c1) in zip(tab, tab[1:]):
        if mach <= m1:
            return c0 + (c1 - c0) * (mach - m0) / (m1 - m0)
    return tab[-1][1]


def velocity_at(tab, bc: float, v0: float, x: float, atmos: str, h: float = 1.0) -> float:
    rho, a = ATMOS[atmos]
    k = rho * math.pi / (8.0 * bc * BC_SI)

    def f(v):
        return -k * cd_at(tab, v / a) * v

    v, s = v0, 0.0
    while s < x - 1e-9:
        step = min(h, x - s)
        k1 = f(v)
        k2 = f(v + 0.5 * step * k1)
        k3 = f(v + 0.5 * step * k2)
        k4 = f(v + step * k3)
        v += step * (k1 + 2 * k2 + 2 * k3 + k4) / 6.0
        s += step
    return v


def solve_bc(tab, v0: float, x: float, vx: float, atmos: str) -> float | None:
    lo, hi = 0.02, 2.0
    if not (velocity_at(tab, lo, v0, x, atmos) < vx < velocity_at(tab, hi, v0, x, atmos)):
        return None
    for _ in range(50):
        mid = 0.5 * (lo + hi)
        if velocity_at(tab, mid, v0, x, atmos) < vx:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def to_si(rec):
    du = YD if rec["dist_unit"] == "yd" else 1.0
    vu = FPS if rec["vel_unit"] == "fps" else 1.0
    return [d * du for d in rec["distances"]], [v * vu for v in rec["velocities"]]


def rounding_sigma(rec, tab, atmos, bc) -> float:
    """Relative BC change if the far velocity moves by half its last digit."""
    xs, vs = to_si(rec)
    half = 0.5 * (FPS if rec["vel_unit"] == "fps" else 1.0)
    b2 = solve_bc(tab, vs[0], xs[-1], vs[-1] + half, atmos)
    return abs(b2 / bc - 1) if b2 else float("nan")


def main() -> None:
    tabs = load_tables()
    recs = json.loads((DATA / "velocity_tables.json").read_text(encoding="utf-8"))
    rows = []
    for r in recs:
        xs, vs = to_si(r)
        row = {k: r[k] for k in ("id", "role", "brand", "name", "source_url", "read_date")}
        row["n_points"] = len(xs)
        row["published_bc"] = r["published_bc"]
        row["published_model"] = r["published_model"] or ""
        for g in ("g1", "g7"):
            for at in ("ASM", "ICAO"):
                per = [solve_bc(tabs[g], vs[0], x, v, at) for x, v in zip(xs[1:], vs[1:])]
                far = per[-1]
                row[f"{g}_{at}"] = round(far, 4) if far else ""
                good = [p for p in per if p]
                drift = (max(good) / min(good) - 1) if len(good) > 1 else ""
                row[f"{g}_{at}_drift"] = round(drift, 4) if drift != "" else ""
                row[f"{g}_{at}_per_dist"] = ";".join(f"{p:.4f}" if p else "na" for p in per)
                if g == "g1" and at == "ASM" and far:
                    row["rounding_rel"] = round(rounding_sigma(r, tabs[g], at, far), 4)
        if r["published_bc"]:
            g = r["published_model"]
            for at in ("ASM", "ICAO"):
                val = row[f"{g}_{at}"]
                row[f"err_{at}"] = round(val / r["published_bc"] - 1, 4) if val else ""
        rows.append(row)
    keys = sorted({k for row in rows for k in row}, key=lambda k: (k not in ("id", "role", "brand", "name"), k))
    with open(DATA / "backsolve_results.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=keys)
        w.writeheader()
        w.writerows(rows)

    print(f"{'id':7} {'brand':8} {'name':40} n  G1-ASM  G1-ICAO drift  G7-ICAO drift  pub   errASM errICAO")
    for row in rows:
        print(f"{row['id']:7} {row['brand'][:8]:8} {row['name'][:40]:40} {row['n_points']}  "
              f"{row['g1_ASM']!s:6}  {row['g1_ICAO']!s:6} {row['g1_ICAO_drift']!s:6} "
              f"{row['g7_ICAO']!s:6} {row['g7_ICAO_drift']!s:6} "
              f"{(str(row['published_bc'])+row['published_model']) if row['published_bc'] else '':8} "
              f"{row.get('err_ASM', '')!s:7} {row.get('err_ICAO', '')!s:7}")
    for brand in sorted({r["brand"] for r in rows if r["role"] == "validation"}):
        for at in ("ASM", "ICAO"):
            errs = [abs(r[f"err_{at}"]) for r in rows
                    if r["role"] == "validation" and r["brand"] == brand and r.get(f"err_{at}") != ""]
            if errs:
                errs.sort()
                p90 = errs[min(len(errs) - 1, math.ceil(0.9 * len(errs)) - 1)]
                print(f"validation {brand:8} {at:4}: n={len(errs)} median {statistics.median(errs):.3%} "
                      f"p90 {p90:.3%} max {max(errs):.3%}")


if __name__ == "__main__":
    main()
