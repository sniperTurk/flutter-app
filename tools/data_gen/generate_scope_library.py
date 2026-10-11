#!/usr/bin/env python3
"""Regenerates one brand's block of lib/data/scope_library.dart from the
manufacturer-sourced data/scopes/<brand>.json (PR #77 schema).

The original one-off generator of PR #83 was never committed. This script
reproduces its output byte-for-byte for the brands listed in VERIFIED (checked
against the committed file) and rewrites only that brand's contiguous block,
so the other brands stay untouched.

NASIL ÇALIŞTIRILIR (repo kökünden, önce `git fetch origin`):

    # data dalından (varsayılan origin/data/scopes):
    python3 tools/data_gen/generate_scope_library.py --brand vector_optics

    # belirli bir daldan / çalışma ağacındaki bir dosyadan:
    python3 tools/data_gen/generate_scope_library.py --brand vector_optics \\
        --ref origin/data/scopes-vector-optics
    python3 tools/data_gen/generate_scope_library.py --brand vector_optics \\
        --file data/scopes/vector_optics.json

    # yazmadan denetim (dosya güncel değilse çıkış kodu 1):
    python3 tools/data_gen/generate_scope_library.py --brand vector_optics --check

Kurallar (PR #83 ile aynı):
  * El ile doğrulanmış katalogda (lib/data/catalog_repository.dart) model kodu
    (ör. SCFF-70) geçen dürbünler atlanır — iki kez listelenmesin.
  * id = ('lib-' + slug(marka) + '-' + slug(tam model adı))[:74]; çakışırsa -2, -3…
  * model adından ' Rifle Scope' çıkarılır.
  * MOA kule hareketi mrad'a çevrilir (1 MOA = 0.290888 mrad), 2 basamak.
  * Bilinmeyen (null) alan yazılmaz; hiçbir değer tahmin edilmez.
  * click_value veya objective_mm olmayan kayıt atlanır (stderr'e yazılır).
"""
from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / 'lib' / 'data' / 'scope_library.dart'
CATALOG = REPO / 'lib' / 'data' / 'catalog_repository.dart'
READ_DATE = {'vector_optics': '2026-10-10'}
VERIFIED = {'vector_optics'}
CODE_RE = re.compile(r'\b(SC[A-Z]{2,4}-[A-Z]*\d+[A-Z]*)')
MOA_TO_MRAD = math.pi / 180 / 60 * 1000


def slug(s: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')


def num(v) -> str:
    return repr(float(v))


def dstr(s: str) -> str:
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def load(args) -> list:
    if args.file:
        return json.loads(Path(args.file).read_text(encoding='utf-8'))
    raw = subprocess.run(
        ['git', 'show', f'{args.ref}:data/scopes/{args.brand}.json'],
        cwd=REPO, check=True, capture_output=True, text=True).stdout
    return json.loads(raw)


def render(records: list, brand_key: str, read_date: str, known: dict) -> list[str]:
    catalog_codes = set(CODE_RE.findall(CATALOG.read_text(encoding='utf-8')))
    lines, seen = [], set()
    for r in records:
        m = CODE_RE.search(r.get('source_url') or '')
        if m and m.group(1) in catalog_codes:
            continue
        if not r.get('click_value') or not r.get('objective_mm'):
            print(f"ATLANDI {r.get('model')}: click_value/objective_mm yok",
                  file=sys.stderr)
            continue
        brand = r['brand']
        base = f"lib-{slug(brand)}-{slug(r['model'])}"[:74]
        rid, n = base, 2
        while rid in seen:
            rid, n = f'{base}-{n}', n + 1
        seen.add(rid)
        unit = r['click_unit']
        parts = [f'id:{dstr(rid)}', f'brand:{dstr(brand)}',
                 f"model:{dstr(re.sub(' +', ' ', r['model'].replace(' Rifle Scope', '')).strip())}",
                 f"objectiveDiameterMm:{num(r['objective_mm'])}",
                 f"clickValue:{num(r['click_value'])}",
                 f"clickUnit:AngularUnit.{'moa' if unit == 'moa' else 'mrad'}"]
        if r.get('tube_mm') is not None:
            parts.append(f"tubeDiameterMm:{num(r['tube_mm'])}")
        for key, field in (('min_mag', 'minMagnification'), ('max_mag', 'maxMagnification')):
            if r.get(key) is not None:
                parts.append(f'{field}:{num(r[key])}')
        for axis, field in (('elevation', 'elevationRangeMrad'), ('windage', 'windageRangeMrad')):
            v = r.get(f'{axis}_travel_mrad')
            if v is None and r.get(f'{axis}_travel_moa') is not None:
                v = round(r[f'{axis}_travel_moa'] * MOA_TO_MRAD, 2)
            if v is not None:
                parts.append(f'{field}:{num(v)}')
        for key, field in (('length_mm', 'lengthMm'), ('weight_g', 'weightG')):
            if r.get(key) is not None:
                parts.append(f'{field}:{num(r[key])}')
        if r.get('focal') in ('ffp', 'sfp'):
            parts.append(f"firstFocalPlane:{'true' if r['focal'] == 'ffp' else 'false'}")
        if isinstance(r.get('zero_stop'), bool):
            parts.append(f"zeroStop:{'true' if r['zero_stop'] else 'false'}")
        if r.get('reticle'):
            parts.append(f"reticle:{dstr(r['reticle'])}")
        parts.append(f'sourceName:{dstr(brand)}')
        date = known.get(r['source_url'], read_date)
        parts.append(f"sourceDocument:{dstr(r['source_url'] + ' — official manufacturer page, read ' + date)}")
        lines.append('    ScopeOptic(' + ', '.join(parts) + '),\n')
    return lines


def splice(text: str, brand: str, block: list[str]) -> str:
    lines = text.splitlines(keepends=True)
    tag = f"brand:{dstr(brand)}"
    idx = [i for i, l in enumerate(lines) if l.lstrip().startswith('ScopeOptic(') and tag in l]
    if not idx:
        raise SystemExit(f'{brand}: blok bulunamadı')
    if idx != list(range(idx[0], idx[-1] + 1)):
        raise SystemExit(f'{brand}: blok bitişik değil')
    return ''.join(lines[:idx[0]] + block + lines[idx[-1] + 1:])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--brand', required=True, help='data/scopes/<brand>.json adı, ör. vector_optics')
    ap.add_argument('--ref', default='origin/data/scopes')
    ap.add_argument('--file')
    ap.add_argument('--read-date', help='yeni kayıtların kaynak okuma tarihi (sourceDocument)')
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    if args.brand not in VERIFIED:
        print(f'{args.brand}: biçim bu betikle doğrulanmadı (VERIFIED)', file=sys.stderr)
        return 2
    records = load(args)
    brand = records[0]['brand']
    old = OUT.read_text(encoding='utf-8')
    # Kayıt zaten listedeyse ilk okuma tarihi korunur; yeni kayıtlar --read-date alır.
    known = dict(re.findall(r"sourceDocument:'(\S+) — official manufacturer page, read (\d{4}-\d{2}-\d{2})'", old))
    block = render(records, args.brand, args.read_date or READ_DATE[args.brand], known)
    new = splice(old, brand, block)
    if args.check:
        if new != old:
            print(f'{OUT.relative_to(REPO)} güncel değil', file=sys.stderr)
            return 1
        return 0
    OUT.write_text(new, encoding='utf-8')
    total = new.count('    ScopeOptic(')
    print(f'{OUT.relative_to(REPO)}: {brand} {len(block)} dürbün, toplam {total}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
