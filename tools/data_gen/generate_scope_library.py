#!/usr/bin/env python3
"""Generates lib/data/scope_library.dart from the manufacturer-sourced dürbün
kataloğu in data/scopes/*.json (data/scopes branch, PR #77 schema).

NASIL ÇALIŞTIRILIR (repo kökünden, önce `git fetch origin`):

    # Uzak veri dalından (varsayılan: origin/data/scopes):
    python3 tools/data_gen/generate_scope_library.py --branch origin/data/scopes

    # Yerel bir klasörden:
    python3 tools/data_gen/generate_scope_library.py --data-dir path/to/data/scopes

    # Yazmadan denetim (dosya güncel değilse çıkış kodu 1):
    python3 tools/data_gen/generate_scope_library.py --branch origin/data/scopes --check

Kurallar (PR #83 çıktısıyla birebir aynı sonucu verir):
  * Dosyalar ada göre, kayıtlar dosyadaki sırayla okunur.
  * click_value, objective_mm veya click_unit olmayan kayıt atlanır.
  * HAND_VERIFIED_DUPLICATES listesindeki kayıtlar catalog_repository.dart'taki
    elle doğrulanmış girişlerle aynı dürbün olduğu için atlanır.
  * id = 'lib-' + slug(brand + ' ' + model)[:70]; çakışmada '-2', '-3' eklenir.
  * MOA kule hareketi mrad'a çevrilir (2 ondalık), MRAD olduğu gibi kalır.
  * Okuma tarihi kaydın 'accessed' alanı, yoksa 2026-10-10.
Hiçbir değer tahmin edilmez; null alan Dart'a yazılmaz.
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
DEFAULT_ACCESSED = '2026-10-10'

# Same scope as an entry in CatalogRepository.scopes (skipped since PR #83).
HAND_VERIFIED_DUPLICATES = {
    ("Arken Optics", "EP-5 GENII 5-25x56 FFP"),
    ("Arken Optics", "EP-5 5-25x56 FFP"),
    ("Arken Optics", "EP-5 GENII 7-35x56 FFP"),
    ("Arken Optics", "EPL-4 6-24x50 FFP"),
    ("Arken Optics", "SH-4J GENII 6-24x50 FFP"),
    ("Discovery Optics", "HD Gen III 5-30x56 SFIR FFP"),
    ("Discovery Optics", "ED-ELR Gen II 5-40x56 SFIR FFP"),
    ("Discovery Optics", "ED-ELR Gen III 5-40x56 SFIR FFP"),
    ("Discovery Optics", "XED 6-36x56 SFIR FFP Zero Stop"),
    ("Discovery Optics", "LHD 8-32x56 SFIR FFP Zero Stop"),
    ("Discovery Optics", "ED-PRS Gen II 5-25x56 SFIR FFP Zero Stop"),
    ("Discovery Optics", "HD Gen II 5-30x56 SFIR FFP Zero Stop"),
    ("Discovery Optics", "HD 2-12x24 SFIR FFP"),
    ("Element Optics", "Helix Gen 2 4-16x44 FFP"),
    ("Element Optics", "Helix Gen 2 6-24x50 FFP"),
    ("Element Optics", "Titan 5-25x56 FFP"),
    ("Element Optics", "Titan 3-18x50 FFP"),
    ("Element Optics", "Helix 4-16x44 FFP"),
    ("Element Optics", "Helix 6-24x50 FFP"),
    ("Gazi Sniper", "6-36x56 FFP"),
    ("Vector Optics", "Continental x6 6-36X56 FFP Rifle Scope"),
    ("Vector Optics", "Veyron GenII 3-12x44 HD CTR FFP Rifle Scope"),
    ("Vector Optics", "Veyron GenII 6-24x44 HD CTR FFP Rifle Scope"),
    ("Vector Optics", "Veyron GenII 4-16x44 HD DCR FFP Rifle Scope"),
    ("Vector Optics", "Tauron 5-25x56 HD MIL FFP Rifle Scope PRS"),
    ("Vector Optics", "Tauron 6-24x50 HD MOA FFP Rifle Scope PRS"),
    ("Vector Optics", "Tauron 6-24x50 HD MIL FFP Rifle Scope PRS"),
    ("Vector Optics", "Tauron 4-16x44 HD MOA FFP Rifle Scope"),
    ("Vector Optics", "Tauron 5-40x56 ED FFP Rifle Scope"),
    ("Vector Optics", "Continental x6 6-36X56 FFP PRS Rifle Scope PRS"),
    ("Vector Optics", "Tauron 5-30x56 GenII Rifle Scope"),
    ("Vector Optics", "Tauron GenII 3-24x56 ED FFP Rifle Scope"),
    ("Vector Optics", "Continental 1-6x24i Fiber Rifle Scope Tactical LPVO"),
    ("Vector Optics", "Orion Pro MAX 3-18x50 HD SFP Rifle Scope"),
    ("Vector Optics", "Sentinel 5-25x50 HD FFP Rifle Scope"),
    ("Vector Optics", "Sentinel 6-24x50 FFP Rifle Scope"),
    ("Vector Optics", "Orion Pro Max 6-24X50 FFP HD Rifle Scope"),
    ("Vector Optics", "34mm Continental x6 4-24x56 MBR FFP Rifle Scope PRS"),
    ("Vector Optics", "Veyron 4-16x44 FFP Riflescope"),
    ("Vector Optics", "Orion MAX 3-18x44 HD FFP Rifle Scope"),
    ("Vector Optics", "Continental x10 1-10x28 ED RAR FDE Rifle Scope"),
    ("Vector Optics", "Forester 2-10x40SFP Riflescope"),
    ("Vector Optics", "Forester 3-15x50SFP Riflescope"),
    ("Vector Optics", "Forester JR. 3-9x40 Rifle Scope"),
    ("Vector Optics", "Paragon 3-15x50SFP GenII Riflescope"),
    ("Vector Optics", "Paragon 6-30x56SFP GenII Riflescope"),
    ("Vector Optics", "34mm Continental x6 5-30x56 VCT FFP Rifle Scope PRS"),
    ("Vector Optics", "34mm Continental x6 3-18x50 FFP Rifle Scope"),
}

HEADER = """// dart format off
// GENERATED from the manufacturer-sourced data/scopes/*.json (2026-10-10).
// Each entry keeps its source page. Do not edit by hand.
// Regenerate: python3 tools/data_gen/generate_scope_library.py
import '../models/domain.dart';

/// Scopes of the built-in list beyond the hand-verified catalog entries
/// (owner, 2026-10-10: "Listeden seç" for every manufacturer scope).
abstract final class ScopeLibrary {
  static const all = <ScopeOptic>[
"""
FOOTER = """  ];
}
"""


def slug(s: str) -> str:
    s = s.lower().replace('®', '').replace('™', '')
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')


def num(v) -> str:
    return repr(float(v))


def dart_str(s: str) -> str:
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def moa_to_mrad(v: float) -> float:
    return round(v * math.pi / 180 / 60 * 1000, 2)


def load_files(args) -> list[tuple[str, list]]:
    if args.data_dir:
        d = Path(args.data_dir)
        return [(p.name, json.loads(p.read_text(encoding='utf-8')))
                for p in sorted(d.glob('*.json'))]
    ref = args.branch
    names = subprocess.run(['git', 'ls-tree', '--name-only', ref, 'data/scopes/'],
                           cwd=REPO, check=True, capture_output=True, text=True).stdout.split()
    out = []
    for n in sorted(x for x in names if x.endswith('.json')):
        txt = subprocess.run(['git', 'show', f'{ref}:{n}'], cwd=REPO, check=True,
                             capture_output=True, text=True).stdout
        out.append((Path(n).name, json.loads(txt)))
    return out


def entry(r: dict, id_: str) -> str:
    brand, model = r['brand'], r['model']
    if brand == 'Vector Optics':
        model = re.sub(r'\s*Rifle Scope', '', model)
    p = [f"id:{dart_str(id_)}", f"brand:{dart_str(brand)}", f"model:{dart_str(model)}",
         f"objectiveDiameterMm:{num(r['objective_mm'])}", f"clickValue:{num(r['click_value'])}",
         f"clickUnit:AngularUnit.{r['click_unit']}"]
    for k, dk in [('tube_mm', 'tubeDiameterMm'), ('min_mag', 'minMagnification'),
                  ('max_mag', 'maxMagnification')]:
        if r.get(k) is not None:
            p.append(f"{dk}:{num(r[k])}")
    for ax, dk in [('elevation', 'elevationRangeMrad'), ('windage', 'windageRangeMrad')]:
        if r.get(ax + '_travel_mrad') is not None:
            p.append(f"{dk}:{num(r[ax + '_travel_mrad'])}")
        elif r.get(ax + '_travel_moa') is not None:
            p.append(f"{dk}:{num(moa_to_mrad(r[ax + '_travel_moa']))}")
    for k, dk in [('length_mm', 'lengthMm'), ('weight_g', 'weightG')]:
        if r.get(k) is not None:
            p.append(f"{dk}:{num(r[k])}")
    if r.get('focal') in ('ffp', 'sfp'):
        p.append(f"firstFocalPlane:{'true' if r['focal'] == 'ffp' else 'false'}")
    if r.get('zero_stop') is not None:
        p.append(f"zeroStop:{'true' if r['zero_stop'] else 'false'}")
    if r.get('reticle'):
        p.append(f"reticle:{dart_str(r['reticle'])}")
    p.append(f"sourceName:{dart_str(brand)}")
    accessed = r.get('accessed') or DEFAULT_ACCESSED
    p.append(f"sourceDocument:{dart_str(r['source_url'] + ' — official manufacturer page, read ' + accessed)}")
    return '    ScopeOptic(' + ', '.join(p) + '),'


def generate(files) -> tuple[str, list[str]]:
    lines, seen, skipped = [], set(), []
    for fname, recs in files:
        for r in recs:
            if not r.get('click_value') or not r.get('objective_mm') or not r.get('click_unit'):
                skipped.append(f"{fname}: {r.get('model')} (eksik tık/objektif)")
                continue
            if (r['brand'], r['model']) in HAND_VERIFIED_DUPLICATES:
                skipped.append(f"{fname}: {r['model']} (katalogda elle doğrulanmış)")
                continue
            id_ = 'lib-' + slug(r['brand'] + ' ' + r['model'])[:70]
            if id_ in seen:
                n = 2
                while f'{id_}-{n}' in seen:
                    n += 1
                id_ = f'{id_}-{n}'
            seen.add(id_)
            lines.append(entry(r, id_))
    return HEADER + '\n'.join(lines) + '\n' + FOOTER, skipped


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--branch', default='origin/data/scopes')
    ap.add_argument('--data-dir')
    ap.add_argument('--out', default=str(OUT))
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    text, skipped = generate(load_files(args))
    for s in skipped:
        print('ATLANDI', s, file=sys.stderr)
    out = Path(args.out)
    n = text.count('ScopeOptic(id:')
    if args.check:
        ok = out.exists() and out.read_text(encoding='utf-8') == text
        print(f'{out}: {"güncel" if ok else "GÜNCEL DEĞİL"} ({n} dürbün)')
        return 0 if ok else 1
    out.write_text(text, encoding='utf-8')
    print(f'{out}: {n} dürbün, {len(skipped)} atlandı')
    return 0


if __name__ == '__main__':
    sys.exit(main())
