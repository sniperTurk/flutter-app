#!/usr/bin/env python3
"""Fabrika fişeği denetim sonuçlarını tek CSV'de birleştirir (yalnız okur; lib/ değiştirmez).

Girdi: üretici kaynağına karşı yapılan alan kontrolleri (JSONL, satır başına bir
kontrol: line, field, lib, maker, status, url, date, quote, note) ve
`fabrika_fisek_ic_denetim.py` iç tutarlılık bayrakları. Kaynağı okunmamış her
kayıt/alan ERİŞİLEMEDİ olarak yazılır; hiçbir kontrol atlanmaz.

Kaynak, JSONL dizini ya da önceki CSV olabilir (okunmuş kontroller korunur).

Kullanım:
  python3 tools/research/fabrika_fisek_denetim_csv.py SONUC_DIZINI_VEYA_CSV \
      [--out data/veri_denetimi/fabrika_fisek.csv] [--unreachable-note METIN]
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fabrika_fisek_ic_denetim as ic  # noqa: E402

FIELDS = ["name", "caliber", "grain", "mv", "barrel", "bc", "model"]
STATUSES = ("OK", "HATALI", "ŞÜPHELİ", "ERİŞİLEMEDİ")
HEADER = ["line", "brand", "name", "cartridge", "field", "library_value", "maker_value", "status",
          "url", "read_date", "quote", "note"]
# İç bayraklardan yalnız bunlar ŞÜPHELİ sayılır; BC_OLAGANDISI yalnız öncelik notudur.
IC_SUSPECT = {"AD_AGIRLIK", "SD_ARALIK", "BC_UYARI", "BC_MODEL", "MV_BIRIM", "MV_SAPMA", "NAMLU", "CAP",
              "KOPYA", "AYNI_AD_FARKLI_DEGER", "AGIRLIK_SAPMA"}


def _fmt(v) -> str:
    if v is None:
        return "null"
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def lib_value(r: dict, field: str) -> str:
    return {
        "name": r["name"], "caliber": r["cartridge"], "grain": _fmt(r["grain"]), "mv": _fmt(r["mv"]),
        "barrel": _fmt(r["barrel"]), "bc": _fmt(r["bc"]), "model": _fmt(r["model"]),
    }[field]


def _from_csv(path: Path) -> list[dict]:
    """Önceki CSV'deki denenmiş kontroller (okuma tarihi olanlar) yeniden çalıştırmada kaybolmasın."""
    out = []
    with path.open(encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            if r["field"] in FIELDS and (r["status"] != "ERİŞİLEMEDİ" or r["read_date"]):
                out.append(dict(line=r["line"], field=r["field"], maker=r["maker_value"], status=r["status"],
                                url=r["url"], date=r["read_date"], quote=r["quote"], note=r["note"]))
    return out


def load_checks(src: Path) -> dict[tuple[int, str], dict]:
    checks: dict[tuple[int, str], dict] = {}
    if src.is_file() and src.suffix == ".csv":
        for c in _from_csv(src):
            checks[(int(c["line"]), c["field"])] = c
        return checks
    for p in sorted(src.glob("*.jsonl")):
        for raw in p.read_text(encoding="utf-8").splitlines():
            if not raw.strip():
                continue
            c = json.loads(raw)
            if c.get("field") not in FIELDS or c.get("status") not in STATUSES:
                continue
            key = (int(c["line"]), c["field"])
            # Bir alan iki kez kontrol edildiyse okunmuş sonuç, okunamamışın önüne geçer.
            if key in checks and c["status"] == "ERİŞİLEMEDİ":
                continue
            checks[key] = c
    return checks


def build(src: Path, unreachable_note: str) -> list[list[str]]:
    rows = ic.parse()
    flags = ic.check(rows)
    checks = load_checks(src)
    out: list[list[str]] = []
    for r in rows:
        for f in FIELDS:
            c = checks.get((r["line"], f))
            if c is None:
                out.append([str(r["line"]), r["brand"], r["name"], r["cartridge"], f, lib_value(r, f), "",
                            "ERİŞİLEMEDİ", r["url"], "", "", unreachable_note])
                continue
            out.append([str(r["line"]), r["brand"], r["name"], r["cartridge"], f, lib_value(r, f),
                        str(c.get("maker", "")), c["status"], c.get("url") or r["url"], c.get("date", ""),
                        " ".join(str(c.get("quote", "")).split()[:15]), str(c.get("note", ""))])
        fl = flags.get(r["line"], [])
        suspect = [x for x in fl if x.split(":")[0] in IC_SUSPECT]
        out.append([str(r["line"]), r["brand"], r["name"], r["cartridge"], "ic_tutarlilik", "", "",
                    "ŞÜPHELİ" if suspect else "OK", "", "2026-10-14", "",
                    "; ".join(fl) if fl else "iç kontroller temiz"])
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("--out", type=Path, default=ic.ROOT / "data" / "veri_denetimi" / "fabrika_fisek.csv")
    ap.add_argument("--unreachable-note", default="üretici kaynağı okunamadı")
    a = ap.parse_args(argv)
    out = build(a.src, a.unreachable_note)
    a.out.parent.mkdir(parents=True, exist_ok=True)
    with a.out.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(HEADER)
        w.writerows(out)
    from collections import Counter
    print(Counter((x[4] == "ic_tutarlilik", x[7]) for x in out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
