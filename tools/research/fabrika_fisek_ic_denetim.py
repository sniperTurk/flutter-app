#!/usr/bin/env python3
"""Fabrika fişeği iç tutarlılık denetimi (yalnız okur; lib/ değiştirmez).

`lib/data/factory_ammo_library.dart` içindeki her `FactoryAmmo(...)` satırını
ayrıştırır ve üretici kaynağına bakmadan yakalanabilen sorunları işaretler:

* ad içindeki ağırlık (``150 gr``, ``10.4 g``, ``10,4g``) ile grain alanı uyuşmuyor
* kesitsel yoğunluk (SD) kalibre için olağan aralığın dışında
* BC / ağırlık uyumu (`profiles_screen.dart` içindeki `_bcPlausibilityWarning`
  ile aynı biçim katsayısı aralıkları: G1 0.32–4.6, G7 0.63–1.8) ve daha dar
  bir "olağan" aralık (G1 0.45–1.2, G7 0.85–1.6; kütüphanenin %1–%97
  dilimleri, yalnız öncelik için)
* namlu çıkış hızı aynı fişekte, benzer ağırlıktaki satırların ortancasından
  %12'den fazla sapıyor; m/s gibi duran hızlar
* aynı fişekte farklı çap, birebir aynı satırlar, aynı ad farklı değer

Kullanım: ``python3 tools/research/fabrika_fisek_ic_denetim.py [--json out]``
"""
from __future__ import annotations

import argparse
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib" / "data" / "factory_ammo_library.dart"
GRAMS_TO_GRAINS = 15.4323584

# _bcPlausibilityWarning (lib/features/profiles/profiles_screen.dart)
FORM_RANGE = {"g1": (0.32, 4.6), "g7": (0.63, 1.8)}
# Dar, yalnız önceliklendirme için olağan aralık (uyarı değil, "bak" işareti).
FORM_TYPICAL = {"g1": (0.45, 1.2), "g7": (0.85, 1.6)}
RIMFIRE = {".17 HMR", ".17 WSM", ".22 LR", ".22 WMR", ".22 Short", ".17 Mach 2", ".22 Long"}


def _tokens(s: str) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    cur, i = "", 0
    while i < len(s):
        c = s[i]
        if c == "'":
            if cur.strip():
                out.append(("r", cur.strip()))
            cur = ""
            j, buf = i + 1, ""
            while s[j] != "'":
                if s[j] == "\\":
                    buf += s[j + 1]
                    j += 2
                    continue
                buf += s[j]
                j += 1
            out.append(("s", buf))
            i = j + 1
            continue
        if c == ",":
            if cur.strip():
                out.append(("r", cur.strip()))
            cur = ""
        else:
            cur += c
        i += 1
    if cur.strip():
        out.append(("r", cur.strip()))
    return out


def parse(path: Path = LIB) -> list[dict]:
    rows = []
    for ln, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
        m = re.match(r"\s*FactoryAmmo\((.*)\),?\s*$", line)
        if not m:
            continue
        pos, named, key = [], {}, None
        for typ, v in _tokens(m.group(1)):
            if typ == "r" and re.match(r"^\w+:\s*", v):
                key, rest = v.split(":", 1)
                if rest.strip():
                    named[key] = rest.strip()
                    key = None
                continue
            if key:
                named[key] = v
                key = None
                continue
            pos.append(v)
        f = lambda x: None if x == "null" else float(x)  # noqa: E731
        rows.append(
            dict(line=ln, brand=pos[0], name=pos[1], cartridge=pos[2], diam=f(pos[3]),
                 grain=f(pos[4]), bc=f(pos[5]),
                 model=None if pos[6] == "null" else pos[6].split(".")[-1],
                 mv=f(pos[7]), barrel=f(pos[8]), url=pos[9], **named))
    return rows


def name_weights(name: str) -> list[float]:
    """Weights written in the product name, in grains."""
    out = []
    for m in re.finditer(r"(\d+(?:[.,]\d+)?)\s*(gr|grain|grs|g)\b", name, re.I):
        v = float(m.group(1).replace(",", "."))
        grams = not m.group(2).lower().startswith("gr")
        # Nosler "180g" = 180 grain; a gram value above ~65 g is not a bullet.
        out.append(v * GRAMS_TO_GRAINS if grams and v < 65 else v)
    return out


def sd(r: dict) -> float:
    d_in = r["diam"] / 25.4
    return r["grain"] / 7000 / d_in / d_in


def check(rows: list[dict]) -> dict[int, list[str]]:
    flags: dict[int, list[str]] = defaultdict(list)
    by_cart: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_cart[r["cartridge"]].append(r)
        ln = r["line"]
        # 1) ad içi ağırlık
        ws = name_weights(r["name"])
        if ws and all(abs(w - r["grain"]) > max(1.0, 0.012 * r["grain"]) for w in ws):
            flags[ln].append(f"AD_AGIRLIK: adda {', '.join(f'{w:.1f}' for w in ws)} gr, alan {r['grain']} gr")
        # 2) SD
        s = sd(r)
        if s < 0.08 or s > 0.42:
            flags[ln].append(f"SD_ARALIK: SD {s:.3f}")
        # 3) BC biçim katsayısı
        if r["bc"] and r["model"]:
            i = s / r["bc"]
            lo, hi = FORM_RANGE[r["model"]]
            tlo, thi = FORM_TYPICAL[r["model"]]
            if i < lo or i > hi:
                flags[ln].append(f"BC_UYARI: i={i:.2f} ({r['model'].upper()} {lo}-{hi} dışında; uygulama uyarı verir)")
            elif (i < tlo or i > thi) and r["cartridge"] not in RIMFIRE:
                flags[ln].append(f"BC_OLAGANDISI: i={i:.2f} ({r['model'].upper()} olağan {tlo}-{thi})")
            if r["model"] == "g7" and r["bc"] > 0.45:
                flags[ln].append(f"BC_MODEL: G7 {r['bc']} çok yüksek (G1 olabilir)")
            if r["model"] == "g1" and r["bc"] < 0.12 and r["cartridge"] not in RIMFIRE:
                flags[ln].append(f"BC_MODEL: G1 {r['bc']} çok düşük (G7 olabilir)")
        # 4) hız birimi
        subsonic = re.search(r"sub|suppress", r["name"], re.I)
        if r["mv"] < 1300 and r["cartridge"] not in RIMFIRE and r["mv"] > 500 and not subsonic:
            flags[ln].append(f"MV_BIRIM: {r['mv']} fps (m/s olabilir)")
        if r["mv"] > 4500:
            flags[ln].append(f"MV_ARALIK: {r['mv']} fps")
        if r["barrel"] is not None and not (14 <= r["barrel"] <= 30):
            flags[ln].append(f"NAMLU: {r['barrel']} in")
    for cart, rs in by_cart.items():
        diams = {r["diam"] for r in rs}
        if len(diams) > 1:
            common = statistics.mode(r["diam"] for r in rs)
            for r in rs:
                if r["diam"] != common:
                    flags[r["line"]].append(f"CAP: {cart} için {r['diam']} mm, çoğunluk {common} mm")
        for r in rs:
            peers = [p["mv"] for p in rs if p is not r and abs(p["grain"] - r["grain"]) <= 0.08 * r["grain"]]
            if len(peers) >= 3 and not re.search(r"sub|suppress", r["name"], re.I):
                med = statistics.median(peers)
                if abs(r["mv"] - med) / med > 0.12:
                    flags[r["line"]].append(f"MV_SAPMA: {r['mv']:.0f} fps, benzer ağırlık ortancası {med:.0f} fps ({(r['mv']-med)/med:+.0%})")
            wpeers = [p["grain"] for p in rs if p is not r]
            if len(wpeers) >= 4:
                med = statistics.median(wpeers)
                if r["grain"] > 1.8 * med or r["grain"] < 0.5 * med:
                    flags[r["line"]].append(f"AGIRLIK_SAPMA: {r['grain']} gr, fişek ortancası {med:.0f} gr")
    seen: dict[tuple, int] = {}
    same_name: dict[tuple, list[dict]] = defaultdict(list)
    for r in rows:
        key = (r["brand"], r["name"], r["cartridge"], r["grain"], r["bc"], r["mv"], r["url"])
        if key in seen:
            flags[r["line"]].append(f"KOPYA: satır {seen[key]} ile birebir aynı")
        else:
            seen[key] = r["line"]
        same_name[(r["brand"], r["name"], r["cartridge"])].append(r)
    for (b, n, c), rs in same_name.items():
        if len(rs) > 1:
            vals = {(r["grain"], r["bc"], r["mv"]) for r in rs}
            if len(vals) > 1:
                for r in rs:
                    flags[r["line"]].append(f"AYNI_AD_FARKLI_DEGER: {len(rs)} satır ({', '.join(str(x['line']) for x in rs)})")
    return flags


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", help="bayrakları JSON olarak yaz")
    a = ap.parse_args(argv)
    rows = parse()
    flags = check(rows)
    kinds: dict[str, int] = defaultdict(int)
    for fl in flags.values():
        for f in fl:
            kinds[f.split(":")[0]] += 1
    print(f"kayıt: {len(rows)}  işaretli kayıt: {len(flags)}")
    for k, v in sorted(kinds.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")
    if a.json:
        Path(a.json).write_text(json.dumps({str(k): v for k, v in sorted(flags.items())}, ensure_ascii=False, indent=1), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
