#!/usr/bin/env python3
"""Hand-calculated reference values for test/core/formuller_core_test.dart.

Formüller core'a taşındı (owner, 2026-10-15). Plain textbook formulas only
(trigonometry, unit factors, Litz spin drift / aerodynamic jump fits, Miller
length in calibres, sectional density); no value comes from another
ballistic app. Run: python3 tools/formuller_core_reference.py
"""
import math


def main() -> None:
    rows = [
        ("linearToMrad(0.01, 100)", math.atan(0.01 / 100) * 1000),
        ("mradToLinear(0.1, 100)", math.tan(0.1 / 1000) * 100),
        ("metersToInchesDisplay(0.0254)", 0.0254 * 39.3700787),
        ("spinDriftInches(sg=2, t=0.5)", 1.25 * (2 + 1.2) * 0.5 ** 1.83),
        ("spinDriftMrad(sg=2, t=1, 100 m)",
         math.atan(1.25 * 3.2 * 0.0254 / 100) * 1000),
        ("lengthCalibers(31, 7.62)", 31 / 25.4 / (7.62 / 25.4)),
        ("aeroJumpMoaPerMph(sg=2, l=4)", 0.01 * 2 - 0.0024 * 4 + 0.032),
        ("aeroJumpMrad(10 mph from right)",
         (0.01 * 2 - 0.0024 * 4 + 0.032) * 10 * math.pi / 10800 * 1000),
        ("crosswindFromRight(5, 300)",
         -5 * math.sin(300 * math.pi / 180)),
        ("leadMrad(2 m/s, 0.5 s, 100 m)", math.atan(1.0 / 100) * 1000),
        ("targetRadiusMrad(0.1, 100)", math.atan(0.1 / 2 / 100) * 1000),
        ("horizontalRange(100, 60)", 100 * math.cos(math.radians(60))),
        ("zeroOffsetMrad(1 in, 100 m)", math.atan(0.0254 / 100) * 1000),
        ("LowPass.factor(0.12, 0.12)", 1 - math.exp(-1)),
        ("sectionalDensity(168 gr, 7.62 mm)",
         168 / (7000 * (7.62 / 25.4) ** 2)),
        ("grainForSectionalDensity(0.2, 7.62)",
         0.2 * 7000 * (7.62 / 25.4) ** 2),
    ]
    for name, value in rows:
        print(f"{name:40s} {value!r}")


if __name__ == "__main__":
    main()
