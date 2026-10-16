#!/usr/bin/env python3
"""Mermi kütüphanesi denetimi (2026-10-14): ayrıştırma + iç tutarlılık.

lib/data/bullet_library.dart dosyasını DEĞİŞTİRMEZ; yalnız okur.

  python3 tools/veri_denetimi_mermi.py parse  OUT.json
  python3 tools/veri_denetimi_mermi.py checks OUT.csv

`checks` her kayıt için iç tutarlılık bulgularını yazar (satır, marka, ad,
kontrol, değer, açıklama). Üretici karşılaştırması bu betiğin işi değildir.
"""
from __future__ import annotations

import collections
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib' / 'data' / 'bullet_library.dart'

_STR = r"'((?:[^'\\]|\\.)*)'"
_NUM = r"(null|-?[0-9.]+)"
ROW = re.compile(
    r"^\s*LibraryBullet\(" + _STR + r", " + _STR + r", " + _STR + r", "
    + _NUM + r", " + _NUM + r", " + _NUM + r", " + _NUM + r", " + _NUM
    + r", BallisticModel\.(\w+), " + _NUM + r", \[(.*?)\], " + _NUM
    + r", AmmunitionType\.(\w+), WeaponPlatform\.(\w+), " + _STR + r"\),\s*$")


def _n(s: str):
    return None if s == 'null' else float(s)


def parse(path: Path = LIB) -> list[dict]:
    rows = []
    for i, line in enumerate(path.read_text(encoding='utf-8').split('\n'), 1):
        if not line.strip().startswith("LibraryBullet('"):
            continue
        m = ROW.match(line)
        if not m:
            raise ValueError(f'satır {i} ayrıştırılamadı: {line[:120]}')
        g = m.groups()
        bands = [(int(a), float(b)) for a, b in
                 re.findall(r"\((\d+), ([0-9.]+)\)", g[10])]
        rows.append(dict(
            line=i, brand=g[0].replace("\\'", "'"),
            name=g[1].replace("\\'", "'"), item=g[2],
            caliber_mm=_n(g[3]), diameter_mm=_n(g[4]), grain=_n(g[5]),
            g1=_n(g[6]), g7=_n(g[7]), model=g[8], bc=_n(g[9]), bands=bands,
            length_mm=_n(g[11]), type=g[12], platform=g[13], url=g[14]))
    return rows


def _name_grain(name: str):
    m = re.search(r'(\d+(?:[.,]\d+)?)\s*(?:gr|grain|grs)\b', name, re.I)
    return float(m.group(1).replace(',', '.')) if m else None


_CAL_HINT = [  # (regex in name, expected diameter inch)
    (r'\.172\b|\b17 ?cal', .172), (r'\.204\b|\b20 ?cal', .204),
    (r'\.224\b|\b22 ?cal(?!iber pellet)', .224), (r'\.243\b|(?<![\d.])6 ?mm\b', .243),
    (r'\.257\b|\b25 ?cal', .257), (r'\.264\b|\b6\.5 ?mm\b', .264),
    (r'\.277\b|\b270 ?cal', .277), (r'\.284\b|(?<![\d.])7 ?mm\b', .284),
    (r'\.308\b|\b30 ?cal', .308), (r'\.311\b', .311), (r'\.323\b|(?<![\d.])8 ?mm\b', .323),
    (r'\.338\b|\b338 ?cal', .338), (r'\.358\b|\b35 ?cal', .358),
    (r'\.366\b|\b9\.3 ?mm\b', .366), (r'\.375\b|\b375 ?cal', .375),
    (r'\.416\b', .416), (r'\.458\b|\b45 ?cal', .458),
]


def checks(rows: list[dict]) -> list[dict]:
    out = []

    def add(r, kind, value, note, level='ŞÜPHELİ'):
        out.append(dict(line=r['line'], brand=r['brand'], name=r['name'],
                        check=kind, value=value, note=note, level=level))

    fa = [r for r in rows if r['platform'] == 'firearm']
    # SD-normalised form factor: i = SD / BC(G1); outliers within a family.
    for r in rows:
        d_in = r['diameter_mm'] / 25.4 if r['diameter_mm'] else None
        ng = _name_grain(r['name'])
        if ng is not None and r['grain'] and abs(ng - r['grain']) > 0.051:
            add(r, 'ad_ağırlık', f"ad {ng} / alan {r['grain']}",
                'Adın içindeki ağırlık ile grain alanı farklı', 'HATALI')
        if r['caliber_mm'] and r['diameter_mm'] and \
                abs(r['caliber_mm'] - r['diameter_mm']) > 0.2:
            add(r, 'kalibre_çap', f"{r['caliber_mm']} / {r['diameter_mm']}",
                'Kalibre ile çap 0,2 mm’den fazla farklı')
        if r['bc'] is not None:
            want = r['g7'] if r['model'] == 'g7' else r['g1']
            if want is None or abs(want - r['bc']) > 1e-9:
                add(r, 'bc_model', f"bc {r['bc']} model {r['model']} g1 {r['g1']} g7 {r['g7']}",
                    'Formun BC değeri seçilen modelin alanına eşit değil', 'HATALI')
        if r['g1'] and r['g7'] and not (1.6 <= r['g1'] / r['g7'] <= 2.35):
            add(r, 'g1_g7_oran', f"{r['g1']}/{r['g7']}={r['g1']/r['g7']:.2f}",
                'G1/G7 oranı tipik 1,7–2,1 aralığı dışında')
        if r['platform'] == 'pcp' and r['model'] == 'g7' and r['type'] == 'pellet':
            add(r, 'saçma_g7', r['model'], 'Saçma için G7 model (G1 beklenir)')
        if r['platform'] == 'firearm' and d_in:
            for rx, dia in _CAL_HINT:
                if re.search(rx, r['name'], re.I) and abs(d_in - dia) > 0.004:
                    add(r, 'ad_çap', f"ad ~{dia}in / alan {d_in:.3f}in",
                        'Addaki kalibre ile çap alanı uyuşmuyor', 'HATALI')
                    break
        if r['grain'] and d_in:
            sd = r['grain'] / 7000 / d_in ** 2
            r['_sd'] = sd
            if r['g1']:
                r['_i'] = sd / r['g1']
        if r['bands']:
            ths = [t for t, _ in r['bands']]
            if ths != sorted(ths, reverse=True):
                add(r, 'bant_sıra', str(r['bands']), 'Hız bantları azalan sırada değil')
        if r['length_mm'] is not None and d_in:
            cal_len = r['length_mm'] / r['diameter_mm']
            if not (0.7 <= cal_len <= 7.0):
                add(r, 'uzunluk', f"{r['length_mm']} mm = {cal_len:.1f} kalibre",
                    'Uzunluk/çap oranı olağan dışı (birim hatası?)')
        if r['platform'] == 'pcp' and r['grain'] and d_in:
            # pellet/slug: SD outside 0.010–0.30 suggests gram/grain mix-up
            if not (0.010 <= r['_sd'] <= 0.30):
                add(r, 'pcp_sd', f"SD {r['_sd']:.3f}",
                    'Kesit yoğunluğu PCP için olağan dışı (gram/grain?)')
        if r['platform'] == 'firearm' and r.get('_sd') is not None and \
                not (0.08 <= r['_sd'] <= 0.45):
            add(r, 'fa_sd', f"SD {r['_sd']:.3f}",
                'Kesit yoğunluğu tüfek mermisi için olağan dışı')
    # form-factor outliers per brand (G1 i = SD/BC). Typical 0.4–1.6.
    for r in fa:
        i = r.get('_i')
        if i is not None and not (0.35 <= i <= 1.9):
            add(r, 'form_faktör', f"i={i:.2f} (SD {r['_sd']:.3f}, G1 {r['g1']})",
                'BC ağırlık/çapa göre olağan dışı (form faktörü i=SD/BC)')
    # duplicates
    seen = collections.defaultdict(list)
    for r in rows:
        key = (r['brand'].lower(), r['name'].lower(), r['grain'], r['diameter_mm'])
        seen[key].append(r)
    for lst in seen.values():
        if len(lst) > 1:
            for r in lst:
                add(r, 'kopya_ad', ','.join(str(x['line']) for x in lst),
                    'Aynı marka+ad+ağırlık+çap birden çok satırda')
    vals = collections.defaultdict(list)
    for r in rows:
        if r['bc'] is not None:
            vals[(r['brand'], r['diameter_mm'], r['grain'], r['g1'], r['g7'],
                  tuple(r['bands']))].append(r)
    for lst in vals.values():
        names = {x['name'] for x in lst}
        if len(lst) > 1 and len(names) > 1:
            for r in lst:
                add(r, 'aynı_değer', ','.join(str(x['line']) for x in lst),
                    'Farklı adlı satırlarda birebir aynı ağırlık+BC (komşu satır kopyası?)')
    # within-family monotonicity: same brand, line keyword, diameter → BC
    # rising with weight is typical; a heavier bullet with far lower BC is flagged.
    fam = collections.defaultdict(list)
    for r in fa:
        if r['g1']:
            line_kw = re.sub(r'[\d.]+\s*(gr|grain)\b', '', r['name'], flags=re.I)
            line_kw = re.sub(r'^\S+\s+\S+\s+', '', line_kw).strip().lower()
            fam[(r['brand'], r['diameter_mm'], line_kw)].append(r)
    for lst in fam.values():
        lst = sorted(lst, key=lambda x: x['grain'])
        for a, b in zip(lst, lst[1:]):
            if b['grain'] > a['grain'] * 1.08 and b['g1'] < a['g1'] * 0.85:
                add(b, 'aile_monoton',
                    f"{a['grain']}gr G1 {a['g1']} → {b['grain']}gr G1 {b['g1']} (satır {a['line']})",
                    'Aynı ailede daha ağır mermi belirgin düşük BC')
    return out


def main(argv):
    rows = parse()
    if argv[1] == 'parse':
        Path(argv[2]).write_text(json.dumps(rows, ensure_ascii=False, indent=0))
        print(len(rows), 'kayıt')
    elif argv[1] == 'checks':
        res = checks(rows)
        with open(argv[2], 'w', newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=['line', 'brand', 'name', 'check',
                                              'value', 'note', 'level'])
            w.writeheader()
            w.writerows(res)
        c = collections.Counter(x['check'] for x in res)
        print(len(rows), 'kayıt;', len(res), 'iç bulgu', dict(c))


if __name__ == '__main__':
    main(sys.argv)
