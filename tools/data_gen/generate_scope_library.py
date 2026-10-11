#!/usr/bin/env python3
"""Generates lib/data/scope_library.dart from the manufacturer-sourced
dürbün kataloğu in data/scopes/*.json (PR #77 şeması). The app never reads
JSON at run time; it uses the Dart constants written here.

NASIL ÇALIŞTIRILIR (repo kökünden, önce `git fetch origin`):

    # Veri dallarından (sıra önemli; aynı adlı dosyada sonraki dal kazanır):
    python3 tools/data_gen/generate_scope_library.py \\
        --branch origin/data/scopes --branch origin/data/scopes-element

    # Varsayılan: yalnız origin/data/scopes
    python3 tools/data_gen/generate_scope_library.py

    # Çalışma ağacındaki bir klasörden:
    python3 tools/data_gen/generate_scope_library.py --data-dir data/scopes

    # Yazmadan yalnız denetim (dosya güncel değilse çıkış kodu 1):
    python3 tools/data_gen/generate_scope_library.py --check

Ardından üretilen lib/data/scope_library.dart'ı commit edin. Elle
düzenlemeyin; çıktı belirlenimcidir (dosya adına, sonra dosyadaki sıraya göre).

Şema (bir kayıt): brand, model, min_mag, max_mag, objective_mm, tube_mm,
focal ('ffp'|'sfp'|null), click_unit ('mrad'|'mil'|'moa'), click_value,
elevation_travel_<birim>, windage_travel_<birim> (birim = taret birimi,
mrad veya moa), reticle, parallax_min_m, length_mm, weight_g, zero_stop,
source_url, notes. Bilinmeyen değer null.

Kurallar (değer asla tahmin edilmez):
  * click_value veya objective_mm null olan kayıt listeye girmez (ScopeOptic
    bunları zorunlu tutar); stderr'e yazılır.
  * MOA taret aralığı mrad'a çevrilir (× π/10.8, 2 ondalık).
  * El ile doğrulanmış katalogda (lib/data/catalog_repository.dart) olan
    dürbün atlanır (PR #83 kuralı): katalog modeli üretici kodu taşıyorsa
    ("(SCFF-72)") kaynak URL'sinde aynı kod geçen kayıt; taşımıyorsa aynı
    marka, büyütme aralığı, objektif, odak düzlemi ve klik birimi.
  * Kimlik: 'lib-' + marka + model (küçük harf, harf/rakam dışı '-'),
    en çok 74 karakter; aynı kimlik tekrarında '-2', '-3' … eklenir.
  * Vector Optics model adlarındaki 'Rifle Scope' sözcükleri listede
    gösterilmez (kimlik özgün addan üretilir).
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
DEFAULT_BRANCHES = ['origin/data/scopes']
MOA_TO_MRAD = math.pi / 10.8
# Üretici sayfalarının okunduğu tarih (dosya bazında; yoksa varsayılan).
READ_DATE_DEFAULT = '2026-10-10'
READ_DATES = {'element_optics': '2026-10-11'}
UNITS = {'mrad': 'mrad', 'mil': 'mrad', 'moa': 'moa'}


def _git(*args: str) -> str:
    return subprocess.run(['git', '-C', str(REPO), *args], check=True,
                          capture_output=True, text=True).stdout


def load_branch(ref: str) -> dict[str, list]:
    out = {}
    for line in _git('ls-tree', '--name-only', ref, 'data/scopes/').splitlines():
        if line.endswith('.json'):
            out[Path(line).stem] = json.loads(_git('show', f'{ref}:{line}'))
    return out


def load_dir(path: Path) -> dict[str, list]:
    return {p.stem: json.loads(p.read_text(encoding='utf-8'))
            for p in sorted(path.glob('*.json'))}


ID_MAX = 74


def display_model(brand: str, model: str) -> str:
    if brand == 'Vector Optics':
        model = re.sub(r'\s*\bRifle Scope\b', '', model)
    return re.sub(r'\s{2,}', ' ', model).strip()


def slug(s: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')


def _f(v):
    if v is None or isinstance(v, bool):
        return None
    if not isinstance(v, (int, float)) or not math.isfinite(v):
        return None
    return float(v)


CODE = re.compile(r'\b(SC[A-Z]{2}-\d+)\b')


def catalog_keys(text: str) -> tuple[set, set]:
    """(product codes, key tuples) of the hand-verified ScopeOptic entries.

    A hand entry whose model names a manufacturer product code ("(SCFF-72)")
    is matched by that code; any other by brand, magnification range,
    objective, focal plane and click unit.
    """
    codes, keys = set(), set()
    block = text.split('static const scopes = <ScopeOptic>[', 1)[-1]
    block = block.split('...ScopeLibrary.all', 1)[0]
    for body in block.split('ScopeOptic(')[1:]:

        def g(name):
            x = re.search(rf'\b{name}:\s*([^,\n]+)', body)
            return x.group(1).strip() if x else None

        def num(name):
            v = g(name)
            try:
                return float(v) if v is not None else None
            except ValueError:
                return None
        model = re.search(r"model:'((?:[^'\\]|\\.)*)'", body)
        code = CODE.search(model.group(1)) if model else None
        if code:
            codes.add(code.group(1))
            continue
        ffp = g('firstFocalPlane')
        keys.add(((g('brand') or '').strip("'"), num('minMagnification'),
                  num('maxMagnification'), num('objectiveDiameterMm'),
                  None if ffp is None else ffp == 'true',
                  (g('clickUnit') or '').split('.')[-1]))
    return codes, keys


def in_catalog(rec: dict, catalog: tuple[set, set]) -> bool:
    codes, keys = catalog
    code = CODE.search(rec['url'] or '')
    if code and code.group(1) in codes:
        return True
    return (rec['brand'], rec['min'], rec['max'], rec['objective'],
            rec['ffp'], rec['unit']) in keys


def normalize(stem: str, x: dict) -> dict | None:
    unit = UNITS.get(str(x.get('click_unit') or '').lower())
    click, obj = _f(x.get('click_value')), _f(x.get('objective_mm'))
    if unit is None or click is None or click <= 0 or obj is None or obj <= 0:
        return None

    def travel(axis):
        for u, k in (('mrad', 1.0), ('mil', 1.0), ('moa', MOA_TO_MRAD)):
            v = _f(x.get(f'{axis}_travel_{u}'))
            if v is not None:
                return round(v * k, 2)
        return None
    focal = (x.get('focal') or '').lower()
    reticle = x.get('reticle')
    return {
        'brand': x['brand'].strip(), 'model': x['model'].strip(),
        'objective': obj, 'click': click, 'unit': unit,
        'tube': _f(x.get('tube_mm')), 'min': _f(x.get('min_mag')),
        'max': _f(x.get('max_mag')),
        'elev': travel('elevation'), 'wind': travel('windage'),
        'length': _f(x.get('length_mm')), 'weight': _f(x.get('weight_g')),
        'ffp': {'ffp': True, 'sfp': False}.get(focal),
        'reticle': reticle.strip() if isinstance(reticle, str) and reticle.strip() else None,
        'url': x.get('source_url'),
        'date': READ_DATES.get(stem, READ_DATE_DEFAULT),
    }


def dart_str(s: str) -> str:
    return "'" + (s.replace('\\', '\\\\').replace("'", "\\'")
                  .replace('$', '\\$').replace('\n', ' ')) + "'"


def render_one(r: dict) -> str:
    parts = [f"id:{dart_str(r['id'])}", f"brand:{dart_str(r['brand'])}",
             f"model:{dart_str(r['model'])}",
             f"objectiveDiameterMm:{r['objective']!r}",
             f"clickValue:{r['click']!r}", f"clickUnit:AngularUnit.{r['unit']}"]
    for key, name in (('tube', 'tubeDiameterMm'), ('min', 'minMagnification'),
                      ('max', 'maxMagnification'), ('elev', 'elevationRangeMrad'),
                      ('wind', 'windageRangeMrad'), ('length', 'lengthMm'),
                      ('weight', 'weightG')):
        if r[key] is not None:
            parts.append(f'{name}:{float(r[key])!r}')
    if r['ffp'] is not None:
        parts.append(f"firstFocalPlane:{'true' if r['ffp'] else 'false'}")
    if r['reticle'] is not None:
        parts.append(f"reticle:{dart_str(r['reticle'])}")
    parts.append(f"sourceName:{dart_str(r['brand'])}")
    parts.append('sourceDocument:' + dart_str(
        f"{r['url']} — official manufacturer page, read {r['date']}"))
    return '    ScopeOptic(' + ', '.join(parts) + '),'


def build(raw: dict[str, list], catalog_text: str) -> tuple[str, list[str], int]:
    keys = catalog_keys(catalog_text)
    lines = [
        '// dart format off',
        '// GENERATED by tools/data_gen/generate_scope_library.py from the',
        '// manufacturer-sourced data/scopes/*.json. Each entry keeps its source',
        '// page. Do not edit by hand; re-run the script when the data changes.',
        "import '../models/domain.dart';",
        '',
        '/// Scopes of the built-in list beyond the hand-verified catalog entries',
        '/// (owner, 2026-10-10: "Listeden seç" for every manufacturer scope).',
        'abstract final class ScopeLibrary {',
        '  static const all = <ScopeOptic>[',
    ]
    skipped, seen, n = [], set(), 0
    for stem in sorted(raw):
        for x in raw[stem]:
            r = normalize(stem, x)
            label = f"{stem}: {x.get('model')!r}"
            if r is None:
                skipped.append(label + ' (klik/objektif/birim yok)')
                continue
            if not (isinstance(r['url'], str) and r['url'].startswith('https://')):
                skipped.append(label + ' (kaynak URL yok)')
                continue
            base = ('lib-' + slug(r['brand']) + '-' + slug(r['model']))[:ID_MAX]
            if in_catalog(r, keys):
                skipped.append(label + ' (el ile doğrulanmış katalogda)')
                continue
            r['id'], k = base, 2
            while r['id'] in seen:
                r['id'], k = f'{base}-{k}', k + 1
            seen.add(r['id'])
            r['model'] = display_model(r['brand'], r['model'])
            lines.append(render_one(r))
            n += 1
    lines += ['  ];', '}', '']
    return '\n'.join(lines), skipped, n


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--branch', action='append', default=[],
                    help='okunacak git ref (tekrarlanabilir, sonraki ezer)')
    ap.add_argument('--data-dir', type=Path)
    ap.add_argument('--out', type=Path, default=OUT)
    ap.add_argument('--check', action='store_true',
                    help='yazma; çıktı farklıysa 1 ile çık')
    ap.add_argument('-v', '--verbose', action='store_true',
                    help='atlanan kayıtları yaz')
    a = ap.parse_args(argv)
    raw: dict[str, list] = {}
    if a.data_dir:
        raw.update(load_dir(a.data_dir))
    else:
        for ref in a.branch or DEFAULT_BRANCHES:
            raw.update(load_branch(ref))
            print(f'okundu: {ref}', file=sys.stderr)
    text, skipped, n = build(raw, CATALOG.read_text(encoding='utf-8'))
    if a.verbose:
        for s in skipped:
            print('ATLANDI ' + s, file=sys.stderr)
    if a.check:
        current = a.out.read_text(encoding='utf-8') if a.out.exists() else ''
        if current != text:
            print(f'{a.out} güncel değil; scripti çalıştırın.', file=sys.stderr)
            return 1
        return 0
    a.out.write_text(text, encoding='utf-8')
    print(f'{n} dürbün yazıldı, {len(skipped)} atlandı', file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
