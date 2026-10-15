#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-14b, area MUH (ammunition / BC / drag model).

Independent hand references for test/audit_2026_10_14b/ammo_bc_audit_test.dart
(findings MUH-1 .. MUH-5). Written from published physics and the makers'
own figures, never from the app's Dart solver, never from the repository's
own back-solve script (tools/research/bc_backsolve.py) and never from another
ballistic program:

* BC back-solve (re-check of #296 / #304): a 2-D point-mass trajectory in
  time (RK4, gravity included, distance measured horizontally), retardation
  a = rho/2 * v^2 * Cd_G(M) * (pi/4) / BC_SI with BC_SI = BC lb/in^2 *
  703.0696 kg/m^2 (McCoy, Modern Exterior Ballistics, ch. 4). Air: Army
  Standard Metro (59 F, 29.53 inHg, 78 % RH): rho 0.0751265 lb/ft^3 and the
  dry-air speed of sound at 59 F, 49.0223*sqrt(518.67 R) = 1116.45 ft/s.
  (The repo script integrates dv/dx along the path with 1120.27 ft/s; this
  re-check deliberately uses a different method and sound speed.) The Cd
  numbers are the BRL G1/G7 tables stored in lib/core/standard_drag_tables.dart
  (public BRL data; only the numbers are read, anchored below against the
  published BRL values).
* The makers' downrange-velocity tables are the ones recorded with source URL,
  read date and quote in data/bc_gelistirme/velocity_tables.json (#290); the
  BC the app ships is read from lib/data/factory_ammo_library.dart.
* G1 <-> G7 meaning: the same bullet's G7 BC is roughly half its G1 BC, so a
  G1 number run on the G7 table is a far "slicker" bullet (MUH-1). Shown with
  the same point-mass model: drop at 600/800 m of Winchester X651 (129 gr,
  2820 fps, BC 0.324) with G1 vs G7.
* Unit conversion: 1 gr = 0.06479891 g (exact, international avoirdupois).

Standard library only:
    python3 -m unittest tools/test_denetim_2026_10_14b_muh.py
"""
from __future__ import annotations

import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
G0 = 9.80665
FPS = 0.3048
YD = 0.9144
LB_IN2 = 0.45359237 / 0.0254**2  # 703.0696 kg/m^2
GRAIN_G = 0.06479891
# Army Standard Metro.
RHO_ASM = 0.0751265 * 0.45359237 / 0.3048**3  # 1.2034 kg/m^3
A_ASM = 49.0223 * math.sqrt(518.67) * FPS  # 1116.45 ft/s


def drag_table(name: str) -> list[tuple[float, float]]:
    text = (ROOT / "lib/core/standard_drag_tables.dart").read_text(encoding="utf-8")
    block = re.search(
        rf"static final {name} = DragTable\(const \[(.*?)\]\);", text, re.S
    )
    assert block is not None, name
    return [
        (float(a), float(b))
        for a, b in re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", block.group(1))
    ]


G1 = drag_table("g1")
G7 = drag_table("g7")


def cd(tab, mach):
    if mach <= tab[0][0]:
        return tab[0][1]
    if mach >= tab[-1][0]:
        return tab[-1][1]
    for (m0, c0), (m1, c1) in zip(tab, tab[1:]):
        if m0 <= mach <= m1:
            return c0 + (c1 - c0) * (mach - m0) / (m1 - m0)
    return tab[-1][1]


def fly(v0, bc, tab, xs, rho=RHO_ASM, a=A_ASM, dt=2e-4, angle=0.0):
    """Speeds (m/s) and drops (m, below the bore line) at horizontal xs (m)."""
    k = rho * math.pi / 4 / 2 / (bc * LB_IN2)
    x, y = 0.0, 0.0
    vx, vy = v0 * math.cos(angle), v0 * math.sin(angle)
    out = []
    targets = sorted(xs)
    i = 0

    def acc(vx_, vy_):
        v = math.hypot(vx_, vy_)
        d = k * cd(tab, v / a) * v
        return -d * vx_, -d * vy_ - G0

    while i < len(targets):
        if targets[i] <= 0:
            out.append((v0, 0.0))
            i += 1
            continue
        px, py, pvx, pvy = x, y, vx, vy
        a1 = acc(vx, vy)
        a2 = acc(vx + a1[0] * dt / 2, vy + a1[1] * dt / 2)
        a3 = acc(vx + a2[0] * dt / 2, vy + a2[1] * dt / 2)
        a4 = acc(vx + a3[0] * dt, vy + a3[1] * dt)
        x += dt * (vx + dt / 6 * (a1[0] + a2[0] + a3[0]))
        y += dt * (vy + dt / 6 * (a1[1] + a2[1] + a3[1]))
        vx += dt / 6 * (a1[0] + 2 * a2[0] + 2 * a3[0] + a4[0])
        vy += dt / 6 * (a1[1] + 2 * a2[1] + 2 * a3[1] + a4[1])
        while i < len(targets) and x >= targets[i]:
            f = (targets[i] - px) / (x - px)
            v = math.hypot(pvx + f * (vx - pvx), pvy + f * (vy - pvy))
            out.append((v, -(py + f * (y - py))))
            i += 1
        if vx <= 1:
            break
    return out


def backsolve(v0, x_last, v_last, tab=G1):
    """G1 BC so that the speed at x_last equals v_last (bisection)."""
    lo, hi = 0.02, 2.0
    for _ in range(50):
        mid = (lo + hi) / 2
        v = fly(v0, mid, tab, [x_last], dt=5e-4)[0][0]
        if v < v_last:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def tables():
    return {
        d["id"]: d
        for d in json.loads(
            (ROOT / "data/bc_gelistirme/velocity_tables.json").read_text("utf-8")
        )
    }


def library():
    text = (ROOT / "lib/data/factory_ammo_library.dart").read_text(encoding="utf-8")
    rows = {}
    for m in re.finditer(
        r"FactoryAmmo\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', "
        r"([0-9.]+), ([0-9.]+), ([0-9.]+|null), (BallisticModel\.\w+|null), ([0-9.]+)",
        text,
    ):
        brand, name, cart, d, gr, bc, model, mv = m.groups()
        rows[(brand, name, cart)] = dict(
            diameter=float(d),
            grain=float(gr),
            bc=None if bc == "null" else float(bc),
            model=None if model == "null" else model.split(".")[-1],
            mv=float(mv),
        )
    return rows


def to_m(table):
    unit = YD if table["dist_unit"] == "yd" else 1.0
    vel = FPS if table["vel_unit"] == "fps" else 1.0
    return [d * unit for d in table["distances"]], [v * vel for v in table["velocities"]]


# (velocity-table id, library key) for the re-checked rows.
RECHECK = [
    ("FA002", ("Hornady", "Varmint Express Rimfire 17 gr V-MAX", ".17 HMR")),
    ("FA029", ("Hornady", "30 gr V-MAX Varmint Express Rimfire", ".22 WMR")),
    ("FA062", ("Hornady", "170 gr MonoFlex Black", ".338 ARC")),
    ("FA063", ("Hornady", "175 gr HP Match BLACK", ".338 ARC")),
    ("FA067", ("Hornady", "210 gr InterLock American Whitetail", ".400 Legend")),
    ("FA082", ("Hornady", "American Gunner 123 gr HP Match", "7.62x39")),
    ("FA048", ("Aguila", "30-06 SPRG 150 Grain Soft Point", ".30-06 Springfield")),
    ("FA075", ("Aguila", "140 Grain Full Metal Jacket Boat Tail", "6.5 Creedmoor")),
    ("FA070", ("Aguila", "5.56 x 45mm NATO 55 Grain FMJ", "5.56x45 NATO")),
    ("FA012", ("Aguila", "22 Long Rifle Target Competition Lead Solid Point", ".22 LR")),
    ("FA056", ("Aguila", "308 WIN 150 Grain Full Metal Jacket Boat Tail", ".308 Win")),
]


class DragTableAnchors(unittest.TestCase):
    def test_brl_anchor_values(self):
        # Published BRL G1 / G7 Cd at a few Mach numbers.
        for tab, pts in (
            (G1, [(0.0, 0.2629), (1.0, 0.4805), (2.0, 0.5934), (3.0, 0.5133)]),
            (G7, [(0.0, 0.1198), (1.0, 0.3803), (2.0, 0.2980), (3.0, 0.2424)]),
        ):
            for m, c in pts:
                self.assertAlmostEqual(cd(tab, m), c, places=4)

    def test_asm_air(self):
        self.assertAlmostEqual(RHO_ASM, 1.2034, places=3)
        self.assertAlmostEqual(A_ASM / FPS, 1116.45, places=1)


class MethodValidation(unittest.TestCase):
    """Loads whose maker prints a G1 BC: the method recovers it."""

    def test_printed_g1_recovered(self):
        t = tables()
        for vid in ("V-H05", "V-H03", "V-H07", "V-A01", "V-A02"):
            xs, vs = to_m(t[vid])
            bc = backsolve(vs[0], xs[-1], vs[-1])
            want = t[vid]["published_bc"]
            self.assertLess(abs(bc / want - 1), 0.03, f"{vid}: {bc:.4f} vs {want}")


class FactoryBcRecheck(unittest.TestCase):
    """#296 / #304: stored BC, model, weight, velocity vs the maker table."""

    def test_backsolved_rows(self):
        t, lib = tables(), library()
        for vid, key in RECHECK:
            row = lib[key]
            xs, vs = to_m(t[vid])
            bc = backsolve(vs[0], xs[-1], vs[-1])
            # Two-point tables (Aguila) round the 100 yd speed to 1 fps:
            # +-1 fps alone moves the BC by up to ~2 %.
            tol = 0.035 if len(xs) == 2 else 0.025
            self.assertEqual(row["model"], "g1", vid)
            self.assertLess(abs(row["bc"] / bc - 1), tol, f"{vid}: {row['bc']} vs {bc:.4f}")
            # The weight in the row name matches the stored grain.
            m = re.search(r"(\d+(?:\.\d+)?) ?(?:gr|Grain)", key[1])
            if m:
                self.assertEqual(float(m.group(1)), row["grain"], vid)

    def test_mv_matches_table_except_known(self):
        t, lib = tables(), library()
        for vid, key in RECHECK:
            row = lib[key]
            v0_fps = t[vid]["velocities"][0] / (1 if t[vid]["vel_unit"] == "fps" else FPS)
            if vid == "FA056":
                # MUH-4 (low): app 2750 fps, the page the BC was solved
                # from says 2760 fps.
                self.assertAlmostEqual(row["mv"], 2750.0)
                self.assertAlmostEqual(v0_fps, 2760.0)
                continue
            self.assertAlmostEqual(row["mv"], v0_fps, delta=1.0, msg=vid)

    def test_g7_label_would_be_wrong(self):
        # Every re-checked number is a G1 number: read as G7 its form factor
        # i = SD/BC is far below any real bullet's G7 i (~0.9-1.2) for the
        # long-range boat-tails, i.e. the label G1 is the right one.
        lib = library()
        row = lib[("Winchester", "Super-X Power-Point 129 gr Power-Point", "6.5 Creedmoor")]
        d_in = row["diameter"] / 25.4
        sd = row["grain"] / 7000 / d_in**2
        self.assertAlmostEqual(sd, 0.2645, places=3)
        self.assertAlmostEqual(sd / row["bc"], 0.816, places=2)
        # Inside the app's G1 plausibility band (0.32-4.6) AND its G7 band
        # (0.63-1.8): the profile warning cannot catch a G1->G7 switch (MUH-1).
        self.assertTrue(0.32 <= sd / row["bc"] <= 4.6)
        self.assertTrue(0.63 <= sd / row["bc"] <= 1.8)

    def test_x651_and_fa007(self):
        lib = library()
        x651 = lib[("Winchester", "Super-X Power-Point 129 gr Power-Point", "6.5 Creedmoor")]
        self.assertEqual((x651["grain"], x651["bc"], x651["model"], x651["mv"]),
                         (129.0, 0.324, "g1", 2820.0))
        fa007 = lib[("Aguila", "22 Long Rifle Standard Velocity Lead Solid Point", ".22 LR")]
        self.assertEqual(fa007["grain"], 40.0)
        self.assertIsNone(fa007["bc"])
        self.assertIsNone(fa007["model"])
        # MUH-3: the maker page the weight was taken from gives 1130 fps.
        t = tables()["FA007"]
        self.assertEqual(t["velocities"][0], 1130)
        self.assertEqual(fa007["mv"], 1095.0)  # still the .22 Short figure


class G1vsG7Meaning(unittest.TestCase):
    """MUH-1: the same number on the G7 table is a very different bullet."""

    def test_x651_g1_number_on_g7_table(self):
        v0 = 2820 * FPS
        # Zero both at 100 m (sight height ignored: drop relative to bore
        # line at the zero angle), compare drop at 600 / 800 m.
        def drops(tab):
            # find angle so that drop at 100 m is 0
            lo, hi = 0.0, 0.01
            for _ in range(40):
                mid = (lo + hi) / 2
                y = fly(v0, 0.324, tab, [100], angle=mid, dt=5e-4)[0][1]
                if y > 0:
                    lo = mid
                else:
                    hi = mid
            ang = (lo + hi) / 2
            return [d for _, d in fly(v0, 0.324, tab, [600, 800], angle=ang, dt=5e-4)]

        g1 = drops(G1)
        g7 = drops(G7)
        mrad = [(a - b) / x * 1000 for a, b, x in zip(g1, g7, (600, 800))]
        # Several mrad of elevation difference: a user-visible wrong number.
        # 600 m: G1 6.17 vs G7 4.41 mrad; 800 m: 10.86 vs 6.78 mrad.
        self.assertGreater(mrad[0], 1.5)
        self.assertGreater(mrad[1], 3.5)


class Units(unittest.TestCase):
    def test_grain_gram(self):
        # The typed-weight unit text "gr = x g" (profiles_screen _gramText).
        self.assertEqual(f"{168 * GRAIN_G:.1f}", "10.9")
        self.assertEqual(f"{173 * GRAIN_G:.1f}", "11.2")
        # Energy at 800 m/s for 168 gr: 0.5 m v^2.
        self.assertAlmostEqual(0.5 * 168 * GRAIN_G / 1000 * 800**2, 3483.6, delta=0.5)

    def test_typed_weight_range_rejects_grams(self):
        # .308 Win with listed weights: [0.8 * lightest, 1.25 * heaviest];
        # without listed weights SD 0.08-0.45 lb/in^2: grams typed as grains
        # (10.9 for 168 gr) fall far below either bound.
        d_in = 7.82 / 25.4
        k = 7000 * d_in * d_in
        self.assertGreater(0.08 * k, 50)
        self.assertLess(10.9, 0.08 * k)


if __name__ == "__main__":
    unittest.main()
