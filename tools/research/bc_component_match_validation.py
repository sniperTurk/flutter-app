#!/usr/bin/env python3
"""BC geliştirme (2026-10-14): how well does "the bullet maker's BC of the
named component" reproduce the ammo maker's OWN published BC?

For every factory load that has a BC of its own (bcFromBullet == false) and
whose name names a component line of a bullet maker, look for the bullet in
lib/data/bullet_library.dart with the same maker, a line keyword, the same
diameter (±0.02 mm) and the same weight. When exactly one bullet matches,
compare BCs in the ammo's drag model (G1 or G7). Reports error statistics per
ammo brand (each brand is an independent test: nothing is fitted, so the
result is leave-one-brand-out by construction).

Needs data/bc_gelistirme/inventory_*.csv (run bc_gelistirme_inventory.py).
Writes data/bc_gelistirme/component_match_validation.csv.
"""
from __future__ import annotations

import csv
import math
import re
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "bc_gelistirme"

# (bullet maker in bullet_library, regex on ammo name, regex on bullet name)
LINES = [
    ("Sierra", r"matchking|\bsmk\b", r"matchking|\bsmk\b"),
    ("Sierra", r"tipped matchking|\btmk\b", r"tipped matchking|\btmk\b"),
    ("Sierra", r"tipped gameking|\btgk\b", r"tipped gameking|\btgk\b"),
    ("Sierra", r"gameking", r"(?<!tipped )gameking"),
    ("Sierra", r"gamechanger", r"gamechanger"),
    ("Nosler", r"accubond (long range|lr)\b|\babrl\b", r"accubond long range"),
    ("Nosler", r"accubond(?! long| lr)", r"accubond(?! long)"),
    ("Nosler", r"partition", r"partition"),
    ("Nosler", r"ballistic tip", r"ballistic tip"),
    ("Nosler", r"e-?tip", r"e-?tip"),
    ("Barnes", r"\bttsx\b|tipped tsx", r"\bttsx\b|tipped tsx"),
    ("Barnes", r"\btsx\b(?!.*tipped)", r"\btsx\b"),
    ("Barnes", r"\blrx\b", r"\blrx\b"),
    ("Barnes", r"match burner", r"match burner"),
    ("Berger", r"hybrid hunter", r"hybrid hunter"),
    ("Berger", r"hybrid target|hybrid otm|\bhybrid\b(?! hunter)", r"hybrid target"),
    ("Berger", r"\bvld\b", r"\bvld\b"),
    ("Berger", r"elite hunter", r"elite hunter"),
    ("Hornady", r"eld match|eld-m\b", r"eld match"),
    ("Hornady", r"eld-x", r"eld-x"),
    ("Hornady", r"\bsst\b", r"\bsst\b"),
    ("Hornady", r"v-max", r"v-max"),
    ("Hornady", r"a-tip", r"a-tip"),
    ("Hornady", r"interlock", r"interlock"),
    ("Swift", r"a-frame", r"a-frame"),
    ("Swift", r"scirocco", r"scirocco"),
    ("Speer", r"grand slam", r"grand slam"),
    ("Speer", r"\bhot-?cor\b", r"hot-?cor"),
    ("Lapua", r"scenar", r"scenar"),
    ("Lapua", r"naturalis", r"naturalis"),
    ("Woodleigh", r"woodleigh", r"."),
    ("Cutting Edge Bullets", r"cutting edge", r"."),
]


def load(name):
    return list(csv.DictReader(open(DATA / name, encoding="utf-8")))


def main() -> None:
    ammo = [a for a in load("inventory_factory_ammo.csv")
            if a["has_bc"] == "1" and a["bc_from_bullet"] == "false" and a["bc_source"] == ""]
    bullets = [b for b in load("inventory_bullets.csv") if b["platform"] == "firearm"]
    rows = []
    for a in ammo:
        name = a["name"].lower()
        d, gr = float(a["diameter_mm"]), float(a["grain"])
        cands = []
        for maker, ra, rb in LINES:
            if not re.search(ra, name):
                continue
            for b in bullets:
                if b["brand"] != maker or abs(float(b["grain"]) - gr) > 0.05:
                    continue
                if abs(float(b["diameter_mm"]) - d) > 0.03 and abs(float(b["caliber_mm"]) - d) > 0.03:
                    continue
                if re.search(rb, b["name"].lower()):
                    cands.append(b)
            if cands:
                break
        if not cands:
            continue
        uniq = {(c["brand"], c["name"]) for c in cands}
        model = a["model"]
        bvals = {c[model] for c in cands if c[model]}
        if len(bvals) != 1:
            status = "ambiguous" if len(bvals) > 1 else "no_same_model_bc"
            rows.append({**{k: a[k] for k in ("brand", "name", "cartridge", "grain", "bc", "model")},
                         "bullet": " | ".join(sorted(n for _, n in uniq)), "bullet_bc": "",
                         "status": status, "rel_err": ""})
            continue
        bbc = float(bvals.pop())
        err = bbc / float(a["bc"]) - 1
        rows.append({**{k: a[k] for k in ("brand", "name", "cartridge", "grain", "bc", "model")},
                     "bullet": " | ".join(sorted(n for _, n in uniq)), "bullet_bc": bbc,
                     "status": "matched", "rel_err": round(err, 4)})
    with open(DATA / "component_match_validation.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    def stats(errs):
        errs = sorted(abs(e) for e in errs)
        p90 = errs[min(len(errs) - 1, math.ceil(0.9 * len(errs)) - 1)]
        return f"n={len(errs):3d} median {statistics.median(errs):6.2%} p90 {p90:6.2%} max {max(errs):6.2%}"

    m = [r for r in rows if r["status"] == "matched"]
    print(f"ammo with own BC naming a component: {len(rows)}; one-bullet matches: {len(m)}; "
          f"ambiguous/other: {len(rows) - len(m)}")
    print("ALL      ", stats([r["rel_err"] for r in m]))
    for brand in sorted({r["brand"] for r in m}):
        e = [r["rel_err"] for r in m if r["brand"] == brand]
        print(f"{brand[:9]:9}", stats(e))
    big = sorted(m, key=lambda r: -abs(r["rel_err"]))[:12]
    print("largest differences:")
    for r in big:
        print(f"  {r['rel_err']:+.1%} {r['brand']} {r['name']} ({r['cartridge']}) ammo {r['bc']}{r['model']} "
              f"vs bullet {r['bullet_bc']} [{r['bullet'][:60]}]")


if __name__ == "__main__":
    main()
