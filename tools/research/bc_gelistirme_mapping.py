#!/usr/bin/env python3
"""BC geliştirme (2026-10-14): one row per BC-less factory load with the
best manufacturer-sourced route to a real BC.

Combines (all files under data/bc_gelistirme/):
  * agent_component_search_*.json  - component / ammo-page search (maker
    pages only; URL, read date, quote per value),
  * velocity_tables.json + backsolve_results.csv - maker's own downrange
    velocity tables and the BC that reproduces them (bc_backsolve.py),
and writes bc_less_mapping.csv plus a count summary on stdout.

Decisions encoded here (see docs/research/bc_gelistirme.md):
  * Back-solve uses G1 / Army Standard Metro (validated: Hornady n=12
    median 0.19 % p90 0.53 %, Aguila n=3 max 0.10 %).
  * Confidence: high = maker's own number (printed or back-solved from a
    >=3-point table, validated brand); medium = 2-point table, text
    reconstruction, cross-maker component, or drift > 2 %; low = rounded
    metric table with drift > 4 %.
"""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "bc_gelistirme"
READ = "2026-10-14"

# Manual decisions (id -> dict) where the automatic rules are not enough.
MANUAL = {
    "FA001": dict(status="blocked_data_error", confidence="none",
                  notes="Aguila 17 HMR page has one malformed row (distance '2350', 1785 fps, 332 ft-lb); "
                        "cannot be tied to a range. Catalogue PDF permission timed out."),
    "FA007": dict(status="ambiguous", confidence="low",
                  notes="Library row says 29 gr; Aguila page for 'Standard Velocity Lead Solid Point' is 40 gr. "
                        "Back-solved value belongs to the 40 gr page; check library row before use."),
    "FA013": dict(status="not_applicable", confidence="none", notes="#12 shot load; BC not applicable."),
    "FA016": dict(status="blocked", confidence="none", notes="rws-ammunition.com disallowed by robots.txt; not fetched."),
    "FA031": dict(status="linked_cross_maker", confidence="medium", model="g1", bc=0.0948,
                  source_url="https://www.hornady.com/ammunition/rimfire/22-wmr-30-gr-v-max", read_date=READ,
                  quote="Hornady #83202 30 gr V-MAX: Muzzle 2200 / 100 yd 1454 / 200 yd 1026 fps",
                  method="component (Hornady V-MAX named by Winchester) + back-solve of Hornady's own 22 WMR 30 gr V-MAX table",
                  notes="Winchester names 'V-MAX' (Hornady trademark); same weight/calibre. Cross-check: for .17 HMR "
                        "17 gr V-MAX the Hornady back-solve (0.125) equals CCI/Federal/Winchester printed 0.125."),
    "FA034": dict(status="linked", confidence="medium", model="g1", bc=0.149,
                  source_url="https://barnesbullets.com/content/barnes-loaddata/rifle/224/223RemingtonWeb.pdf",
                  read_date=READ, quote="36-grain Varmint Grenade ... Ballistic Coefficient .149",
                  method="component (Barnes Varmint Grenade, named on Black Hills Gold .22-250 page)",
                  notes="Black Hills .223 page: '36 Gr. Varmint Grenade' (no maker); BH Gold .22-250 page: "
                        "'36 Gr. Barnes Varmint Grenade'. Barnes prints BC without G1/G7 label (G1 assumed, as in library)."),
    "FA049": dict(status="ambiguous", confidence="low",
                  notes="Black Hills: '168 Gr. Hornady Match Hollow Point'. Candidates (library, Hornady pages): "
                        "168 BTHP Match G1 0.450; 168 HPBT AeroMatch G1 0.440; 168 ELD Match G1 0.523/G7 0.263. "
                        "BTHP Match most likely (BH sells ELD Match separately) but not stated."),
    "FA059": dict(status="ambiguous", confidence="low",
                  notes="Black Hills: '125 Gr. Hornady CX'. Hornady lists no 125 gr CX component, only 125 gr ECX (#301944); "
                        "identity unconfirmed; no BC read."),
    "FA073": dict(status="linked_no_bc", confidence="none",
                  notes="Black Hills: '70 Gr. Hornady GMX'. GMX not on current Hornady site (replaced by CX); "
                        "no maker BC available. Do not substitute CX."),
}


def main() -> None:
    items = list(csv.DictReader(open(DATA / "inventory_factory_ammo.csv", encoding="utf-8")))
    items = [r for r in items if r["has_bc"] == "0"]
    for i, r in enumerate(items):
        r["id"] = f"FA{i + 1:03d}"
    agent = {}
    for f in ("agent_component_search_blackhills.json", "agent_component_search_other.json"):
        for r in json.loads((DATA / f).read_text(encoding="utf-8")):
            agent[r["id"]] = r
    vt = {r["id"]: r for r in json.loads((DATA / "velocity_tables.json").read_text(encoding="utf-8"))}
    bs = {r["id"]: r for r in csv.DictReader(open(DATA / "backsolve_results.csv", encoding="utf-8"))}

    out = []
    for it in items:
        i = it["id"]
        row = dict(id=i, brand=it["brand"], name=it["name"], cartridge=it["cartridge"], grain=it["grain"],
                   status="", confidence="none", method="", bc="", model="", atmosphere="",
                   source_url="", read_date="", quote="", notes="")
        a = agent.get(i, {})
        if a.get("status") == "ammo_bc_found":
            b = a["bc"]
            row.update(status="maker_bc_found", confidence="high",
                       method="ammo maker prints the BC on another page",
                       bc=b["g1"] if b["g1"] else b["g7"], model="g1" if b["g1"] else "g7",
                       source_url=b["url"], read_date=b["read_date"], quote=b["quote"],
                       notes=(a.get("notes") or "")[:300])
            if b.get("g7") and b.get("g1"):
                row["notes"] = f"also G7 {b['g7']}. " + row["notes"]
        elif i in bs and bs[i]["g1_ASM"]:
            v, r = vt[i], bs[i]
            drift = float(r["g1_ASM_drift"]) if r["g1_ASM_drift"] else None
            npts = int(r["n_points"])
            conf = "high"
            why = []
            if npts < 3:
                conf, _ = "medium", why.append("2-point table (muzzle + 100 yd)")
            if drift is not None and drift > 0.02:
                conf = "medium"
                why.append(f"G1 drift {drift:.1%} over distances")
            if drift is not None and drift > 0.04:
                conf = "low"
            if "reconstructed" in (v.get("note") or ""):
                conf = "medium" if conf == "high" else conf
                why.append("catalogue table text reconstructed by fetch tool; verify printed page")
            if it["brand"] == "Geco":
                why.append("velocities rounded to 5-10 m/s (rounding alone ±1.3 %)")
            row.update(status="maker_table_backsolve", confidence=conf,
                       method="back-solve of maker's own downrange-velocity table (G1, Army Standard Metro)",
                       bc=float(r["g1_ASM"]), model="g1", atmosphere="ASM",
                       source_url=v["source_url"], read_date=v["read_date"], quote=v["quote"],
                       notes="; ".join(why + [f"G7 ICAO equivalent {r['g7_ICAO']}"]))
        elif a:
            row.update(status=a.get("status", ""), confidence=a.get("confidence", "none"),
                       notes=(a.get("notes") or "")[:300])
        if i in MANUAL:
            row.update(MANUAL[i])
        out.append(row)

    with open(DATA / "bc_less_mapping.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        w.writerows(out)
    from collections import Counter
    print("total BC-less factory loads:", len(out))
    print("by status:", dict(Counter(r["status"] for r in out)))
    print("by confidence:", dict(Counter(r["confidence"] for r in out)))
    got = [r for r in out if r["bc"] != ""]
    print("with a manufacturer-sourced BC:", len(got), " high:", sum(r["confidence"] == "high" for r in got),
          " medium:", sum(r["confidence"] == "medium" for r in got), " low:", sum(r["confidence"] == "low" for r in got))
    print("by brand (got/total):", {b: f"{sum(1 for r in got if r['brand'] == b)}/{sum(1 for r in out if r['brand'] == b)}"
                                    for b in sorted({r['brand'] for r in out})})


if __name__ == "__main__":
    main()
