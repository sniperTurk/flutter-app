#!/usr/bin/env python3
"""BC geliştirme araştırması (2026-10-14): parse the two built-in libraries.

Reads lib/data/factory_ammo_library.dart and lib/data/bullet_library.dart
(read-only) and writes:

  data/bc_gelistirme/inventory_factory_ammo.csv
  data/bc_gelistirme/inventory_bullets.csv

with one row per firearm item and a ``has_bc`` flag. No network, no app code
changes. Usage: python3 tools/research/bc_gelistirme_inventory.py
"""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data" / "bc_gelistirme"


def split_args(s: str) -> list[str]:
    """Split a Dart argument list at top-level commas (strings/brackets aware)."""
    out, cur, depth, i, quote = [], [], 0, 0, None
    while i < len(s):
        c = s[i]
        if quote:
            cur.append(c)
            if c == "\\" and i + 1 < len(s):
                cur.append(s[i + 1])
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "'\"":
            quote = c
            cur.append(c)
        elif c in "([{":
            depth += 1
            cur.append(c)
        elif c in ")]}":
            depth -= 1
            cur.append(c)
        elif c == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(c)
        i += 1
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return out


def unq(tok: str) -> str:
    tok = tok.strip()
    if len(tok) >= 2 and tok[0] in "'\"" and tok[-1] == tok[0]:
        return tok[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\$", "$")
    return tok


def num(tok: str):
    tok = tok.strip()
    return None if tok == "null" else float(tok)


def calls(text: str, ctor: str):
    """Yield the argument string of each ``ctor(...)`` call (balanced parens)."""
    for m in re.finditer(r"\b" + ctor + r"\(", text):
        if text[m.start() - 6:m.start()].strip().endswith("const"):
            continue  # the class constructor declaration
        i, depth, quote = m.end(), 1, None
        while depth:
            c = text[i]
            if quote:
                if c == "\\":
                    i += 1
                elif c == quote:
                    quote = None
            elif c in "'\"":
                quote = c
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
            i += 1
        yield text[m.end():i - 1]


def parse_factory(path: Path) -> list[dict]:
    rows = []
    for args in calls(path.read_text(encoding="utf-8"), "FactoryAmmo"):
        a = split_args(args)
        if len(a) < 10 or not a[0].startswith("'"):
            continue
        named = {}
        for extra in a[10:]:
            if ":" in extra:
                k, v = extra.split(":", 1)
                named[k.strip()] = unq(v)
        rows.append({
            "brand": unq(a[0]), "name": unq(a[1]), "cartridge": unq(a[2]),
            "diameter_mm": num(a[3]), "grain": num(a[4]), "bc": num(a[5]),
            "model": a[6].replace("BallisticModel.", "") if a[6] != "null" else "",
            "mv_fps": num(a[7]), "source_url": unq(a[9]),
            "bc_from_bullet": named.get("bcFromBullet", "false"),
            "bc_source": named.get("bcSource", ""),
        })
    return rows


def parse_bullets(path: Path) -> list[dict]:
    rows = []
    for args in calls(path.read_text(encoding="utf-8"), "LibraryBullet"):
        a = split_args(args)
        if len(a) < 15 or not a[0].startswith("'"):
            continue
        rows.append({
            "brand": unq(a[0]), "name": unq(a[1]), "item": unq(a[2]),
            "caliber_mm": num(a[3]), "diameter_mm": num(a[4]), "grain": num(a[5]),
            "g1": num(a[6]), "g7": num(a[7]),
            "model": a[8].replace("BallisticModel.", ""), "bc": num(a[9]),
            "length_mm": num(a[11]),
            "type": a[12].replace("AmmunitionType.", ""),
            "platform": a[13].replace("WeaponPlatform.", ""), "source_url": unq(a[14]),
        })
    return rows


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fa = parse_factory(ROOT / "lib/data/factory_ammo_library.dart")
    bl = parse_bullets(ROOT / "lib/data/bullet_library.dart")
    for rows, name in ((fa, "inventory_factory_ammo.csv"), (bl, "inventory_bullets.csv")):
        for r in rows:
            r["has_bc"] = int(r["bc"] is not None)
        with open(OUT / name, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
    fire = [r for r in bl if r["platform"] == "firearm"]
    print(f"factory ammo: {len(fa)} rows, BC-less {sum(1 for r in fa if r['bc'] is None)}")
    print(f"bullets: {len(bl)} rows, firearm {len(fire)}, firearm BC-less "
          f"{sum(1 for r in fire if r['bc'] is None)}")


if __name__ == "__main__":
    main()
