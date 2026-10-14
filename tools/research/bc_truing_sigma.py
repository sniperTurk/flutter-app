#!/usr/bin/env python3
"""BC geliştirme (2026-10-14): expected BC uncertainty of the in-app truing
flows, by linear error propagation on the same point-mass model used in
bc_backsolve.py (G1, Army Standard Metro).

Flows:
 A. Two velocities: chronograph at the muzzle and at distance L (or one
    Doppler radar that reports velocity at the muzzle and at L for the same
    shot). n shots each.
 B. Drop at a known range R (group centre of n shots), zero at 100 m.

Inputs per flow are stated in the printout; all are assumptions, not
measurements. Usage: python3 tools/research/bc_truing_sigma.py
"""
from __future__ import annotations

import math

from bc_backsolve import load_tables, velocity_at, ATMOS, cd_at, BC_SI

G = 9.80665


def drop_at(tab, bc, v0, rng, zero=100.0, sight=0.04, atmos="ASM", h=0.5):
    """Flat-fire drop below line of sight (m) at rng with zero at `zero`."""
    rho, a = ATMOS[atmos]
    k = rho * math.pi / (8.0 * bc * BC_SI)

    def traj(angle, stop):
        x, y, vx, vy = 0.0, -sight, v0 * math.cos(angle), v0 * math.sin(angle)
        dt = 1e-4
        while x < stop:
            v = math.hypot(vx, vy)
            d = k * cd_at(tab, v / a) * v
            vx, vy = vx - d * vx * dt, vy - (d * vy + G) * dt
            x += vx * dt
            y += vy * dt
        return y

    lo, hi = -0.01, 0.02
    for _ in range(40):
        mid = 0.5 * (lo + hi)
        if traj(mid, zero) < 0:
            lo = mid
        else:
            hi = mid
    return traj(0.5 * (lo + hi), rng)


def main() -> None:
    tab = load_tables()["g1"]
    cases = [  # name, BC G1, v0 m/s
        (".308 Win 168 gr", 0.45, 800.0),
        ("6.5 CM 140 gr", 0.58, 820.0),
        (".223 Rem 55 gr", 0.25, 990.0),
        (".22 LR 40 gr", 0.14, 330.0),
    ]
    print("A. two velocities (n = 10 shots, distance tape ±0.5 m)")
    for name, bc, v0 in cases:
        for L, sd_shot, sd_inst, label in (
            (100.0, 4.5, 0.001, "two optical/radar units, MV SD 4.5 m/s, separate shots"),
            (100.0, 0.0, 0.002, "one Doppler radar tracking the same shot to 100 m (±0.2 % far)"),
        ):
            if name.startswith(".22 LR"):
                L = 50.0
            vL = velocity_at(tab, bc, v0, L, "ASM")
            eps = 0.01
            dvdbc = (velocity_at(tab, bc * (1 + eps), v0, L, "ASM") - vL) / (bc * eps)
            n = 10
            s0 = math.hypot(sd_shot, sd_inst * v0) / math.sqrt(n)
            sL = math.hypot(sd_shot, sd_inst * vL) / math.sqrt(n)
            if sd_shot == 0.0:  # same shot: muzzle and far share the shot
                s0, sL = sd_inst * v0 / math.sqrt(n), sd_inst * vL / math.sqrt(n)
            # dv_L/dv0 ~ vL/v0 for the shared drag law
            sv = math.hypot(sL, s0 * vL / v0)
            dL = 0.5  # tape error on L
            dvdL = (velocity_at(tab, bc, v0, L + 1, "ASM") - vL)
            s_bc = math.hypot(sv / dvdbc, dL * dvdL / dvdbc) / bc
            print(f"  {name:16} L={L:4.0f} m  {label:62} sigma_BC = {s_bc:5.1%}")
    print("B. drop at range R (group centre of 10 shots, MV SD 4.5 m/s, MV known ±1 m/s,")
    print("   reading/zero error 1.5 cm, range ±1 m)")
    for name, bc, v0 in cases[:3]:
        for R in (300.0, 500.0, 800.0):
            y = drop_at(tab, bc, v0, R)
            dyb = drop_at(tab, bc * 1.01, v0, R) - y
            dyv = drop_at(tab, bc, v0 + 1.0, R) - y
            dyr = drop_at(tab, bc, v0, R + 1.0) - y
            s_y = math.hypot(0.015, (abs(dyv) * 4.5) / math.sqrt(10))
            s = math.hypot(s_y, abs(dyv) * 1.0, abs(dyr) * 1.0) / abs(dyb) * 0.01
            print(f"  {name:16} R={R:4.0f} m  drop {y:6.2f} m  sigma_BC = {s:5.1%}")


if __name__ == "__main__":
    main()
