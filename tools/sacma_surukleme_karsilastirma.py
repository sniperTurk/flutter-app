#!/usr/bin/env python3
"""Pellet drag-law comparison for docs/sacma-surukleme/RAPOR.md (2026-10-12).

Compares, for typical PCP diabolo loads, drop and wind drift at 10–100 m:

* GA  — the current table in lib/core/standard_drag_tables.dart (forum-sourced);
* G1  — the BRL standard function, same BC (the app's new default);
* G1 with the BC refitted so the velocity at 50 m equals GA's (what a user
  gets when the BC is measured over a chronograph pair rather than copied);
* "sabit Cd" — a SENSITIVITY case only, not a drag table for the app: Cd held
  constant at GA's value at Mach 0.58. Ladommatos (2021, Proc. IMechE C,
  doi:10.1177/0954406221991190) reports that raising air speed from 120 to
  200 m/s "had little effect" on pellet drag coefficient; this case shows how
  far a flat curve moves results, i.e. how much the table's shape matters.

Trajectories use tools/formula_reference.py (same equations as the app).
Run with no arguments to print the Markdown block the report embeds.
Standard library only.
"""
from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as ref  # noqa: E402

REF_MACH = 0.58  # Ladommatos 2019/2021 wind-tunnel Mach number
RANGES = tuple(float(r) for r in range(10, 101, 10))
WIND_MPS = 4.0   # full value, from the left

# Generic loads of the usual order of magnitude (not copied from any app).
LOADS = (
    dict(name=".177 / 4,5 mm, 8,44 gr, 280 m/s", bc=0.021, grain=8.44, caliber_in=0.177,
         mv_mps=280.0, zero_m=30.0, sight_mm=50.0),
    dict(name=".22 / 5,5 mm, 18,13 gr, 270 m/s", bc=0.035, grain=18.13, caliber_in=0.217,
         mv_mps=270.0, zero_m=30.0, sight_mm=50.0),
    dict(name=".22 / 5,5 mm, 18,13 gr, 300 m/s", bc=0.035, grain=18.13, caliber_in=0.217,
         mv_mps=300.0, zero_m=30.0, sight_mm=50.0),
)


@dataclass(frozen=True)
class Row:
    range_m: float
    drop_cm: float       # below the line of sight, positive down
    drift_cm: float      # wind drift, positive to the right
    velocity_mps: float


def flat_table(ref_mach: float = REF_MACH) -> list[tuple[float, float]]:
    cd = ref.Pchip(ref.load_table("ga"))(ref_mach)
    return [(0.0, cd), (5.0, cd)]


def trajectory(law, bc: float, load: dict, wind_mps: float = WIND_MPS,
               ranges: tuple[float, ...] = RANGES) -> list[Row]:
    pts = ref.load_table(law) if isinstance(law, str) else list(law)
    cd = ref.Pchip(pts)
    sc = ref.Scenario(id="sacma", model="custom", bc=bc, grain=load["grain"],
                      caliber_in=load["caliber_in"], mv_mps=load["mv_mps"],
                      zero_m=load["zero_m"], sight_mm=load["sight_mm"],
                      ranges=tuple(ranges), env=ref.Env(wind_mps=wind_mps, wind_deg=90.0))
    alpha = ref.zero_angle(sc, cd, "cipm")
    axes = ref._axes(0.0, 0.0)
    model = ref._model(sc, sc.env, cd, False, "cipm")
    hits = ref._fly(model, ref._launch(sc, alpha, axes), axes[0], list(sc.ranges))
    out = []
    for r, (_t, s) in zip(sorted(sc.ranges), hits):
        y = ref._dot(s[:3], axes[1])
        z = ref._dot(s[:3], axes[2])
        v = math.sqrt(s[3] ** 2 + s[4] ** 2 + s[5] ** 2)
        out.append(Row(r, -y * 100.0, z * 100.0, v))
    return out


def fit_bc(law, target_velocity_mps: float, load: dict, at_m: float = 50.0) -> float:
    def v(bc):
        return trajectory(law, bc, load, wind_mps=0.0, ranges=(at_m,))[0].velocity_mps

    lo, hi = 0.002, 0.5
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if v(mid) < target_velocity_mps:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def _f(x: float) -> str:
    if round(x, 1) == 0:
        return "0,0"
    return f"{x:+.1f}".replace(".", ",")


def _p(x: float) -> str:
    return f"{x:.1f}".replace(".", ",")


def markdown_block() -> str:
    lines = ["<!-- sacma_surukleme_karsilastirma.py: başlangıç -->"]
    for load in LOADS:
        ga = trajectory("ga", load["bc"], load)
        g1 = trajectory("g1", load["bc"], load)
        bc_fit = fit_bc("g1", ga[RANGES.index(50.0)].velocity_mps, load)
        g1f = trajectory("g1", bc_fit, load)
        fl = trajectory(flat_table(), load["bc"], load)
        lines += [
            "",
            f"{load['name']} — BC " + f"{load['bc']:.3f}".replace(".", ",") + f", sıfır {load['zero_m']:.0f} m, "
            f"nişan {load['sight_mm']:.0f} mm, rüzgâr {WIND_MPS:.0f} m/s soldan, "
            f"G1 eşlenmiş BC {bc_fit:.4f}".replace(".", ","),
            "",
            "| Menzil m | GA düşüş cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm "
            "| GA sürüklenme cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm |",
            "|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
        for a, b, c, d in zip(ga, g1, g1f, fl):
            lines.append(
                f"| {a.range_m:.0f} | {_p(a.drop_cm)} | {_f(b.drop_cm - a.drop_cm)} "
                f"| {_f(c.drop_cm - a.drop_cm)} | {_f(d.drop_cm - a.drop_cm)} "
                f"| {_p(a.drift_cm)} | {_f(b.drift_cm - a.drift_cm)} "
                f"| {_f(c.drift_cm - a.drift_cm)} | {_f(d.drift_cm - a.drift_cm)} |")
    lines.append("")
    lines.append("<!-- sacma_surukleme_karsilastirma.py: bitiş -->")
    return "\n".join(lines)


if __name__ == "__main__":
    print(markdown_block())
