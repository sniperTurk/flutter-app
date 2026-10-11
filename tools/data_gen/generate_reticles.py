#!/usr/bin/env python3
"""Generates lib/data/reticle_library.dart from the manufacturer-sourced
retikül ölçüleri in data/reticles/*.json. The app never reads JSON at run
time; it uses the Dart constants written here.

NASIL ÇALIŞTIRILIR (repo kökünden):

    # 1) Çalışma ağacındaki data/reticles/*.json dosyalarından:
    python3 tools/data_gen/generate_reticles.py

    # 2) Uzak veri dallarından (önce `git fetch origin`): data/reticles ve
    #    her data/reticles-<marka> dalı okunur; aynı adlı dosyada marka dalı
    #    kazanır (ör. data/reticles-nightforce, null alanları dolduran dal).
    python3 tools/data_gen/generate_reticles.py --from-branches

    # Belirli dallar (sıra önemli, sonraki öncekini ezer):
    python3 tools/data_gen/generate_reticles.py \\
        --branch origin/data/reticles --branch origin/data/reticles-athlon

    # Yazmadan yalnız denetim (dosya güncel değilse çıkış kodu 1):
    python3 tools/data_gen/generate_reticles.py --check

Ardından üretilen lib/data/reticle_library.dart'ı commit edin. Elle
düzenlemeyin; çıktı belirlenimcidir (tarih yok, dosya adına göre sıralı).

Şema (her anahtar zorunlu, bilinmeyen değer null; birimler retikülün kendi
biriminde, mil = mrad):
  name, brand, scopes[], unit ('mil'|'mrad'|'moa'),
  family ('hash'|'tree'|'mildot'|'duplex'|null),
  hash_step, major_every, numbers_every,
  extent_h, extent_v_up, extent_v_down,
  tree ({rows: [{y, half_width, dot_step}]} | null),
  posts_start, center_dot, floating_center, source_url, notes.
İsteğe bağlı (marka dalları ekleyebilir; yoksa null sayılır):
  line_width  — ince ana çizgi kalınlığı,
  post_width  — kalın direk kalınlığı.

Hiçbir değer tahmin edilmez: null kalan alanı çizici genel ızgarayla
tamamlar ve retikül "kısmi" sayılır. Geçersiz kayıt (ad/birim yok, sayı
yerine metin vb.) atlanır ve stderr'e yazılır.
"""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATA_DIR = REPO / 'data' / 'reticles'
OUT = REPO / 'lib' / 'data' / 'reticle_library.dart'

REQUIRED = [
    'name', 'brand', 'scopes', 'unit', 'family', 'hash_step', 'major_every',
    'numbers_every', 'extent_h', 'extent_v_up', 'extent_v_down', 'tree',
    'posts_start', 'center_dot', 'floating_center', 'source_url', 'notes',
]
OPTIONAL = ['line_width', 'post_width']
NUMBERS = [
    'hash_step', 'major_every', 'numbers_every', 'extent_h', 'extent_v_up',
    'extent_v_down', 'posts_start', 'line_width', 'post_width',
]
UNITS = {'mil': 'mil', 'mrad': 'mil', 'moa': 'moa'}
FAMILIES = {'hash', 'tree', 'mildot', 'duplex'}


class RecordError(ValueError):
    pass


def _num(rec: dict, key: str, positive: bool = True):
    v = rec.get(key)
    if v is None:
        return None
    if isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v):
        raise RecordError(f'{key}: sayı değil ({v!r})')
    if positive and v <= 0:
        raise RecordError(f'{key}: pozitif olmalı ({v!r})')
    return float(v)


def _flag(rec: dict, key: str):
    v = rec.get(key)
    if v is None or isinstance(v, bool):
        return v
    raise RecordError(f'{key}: true/false/null olmalı ({v!r})')


def normalize(stem: str, rec: dict) -> dict:
    """Validates one JSON record; never fills a missing value."""
    if not isinstance(rec, dict):
        raise RecordError('kayıt bir nesne değil')
    missing = [k for k in REQUIRED if k not in rec]
    if missing:
        raise RecordError('eksik anahtar: ' + ', '.join(missing))
    unknown = sorted(set(rec) - set(REQUIRED) - set(OPTIONAL))
    if unknown:
        raise RecordError('bilinmeyen anahtar: ' + ', '.join(unknown))
    name, brand = rec['name'], rec['brand']
    if not isinstance(name, str) or not name.strip():
        raise RecordError('name boş')
    if not isinstance(brand, str) or not brand.strip():
        raise RecordError('brand boş')
    unit = UNITS.get(str(rec['unit']).strip().lower()) if rec['unit'] else None
    if unit is None:
        raise RecordError(f"unit tanınmıyor ({rec['unit']!r})")
    family = rec['family']
    if family is not None and family not in FAMILIES:
        raise RecordError(f'family tanınmıyor ({family!r})')
    scopes = rec['scopes'] or []
    if not isinstance(scopes, list) or not all(isinstance(s, str) for s in scopes):
        raise RecordError('scopes metin listesi değil')
    out = {
        'id': stem, 'name': name.strip(), 'brand': brand.strip(),
        'scopes': [s.strip() for s in scopes if s.strip()],
        'unit': unit, 'family': family,
        'center_dot': _flag(rec, 'center_dot'),
        'floating_center': _flag(rec, 'floating_center'),
        'source_url': rec['source_url'] if isinstance(rec['source_url'], str) else None,
    }
    for k in NUMBERS:
        out[k] = _num(rec, k)
    tree = rec['tree']
    if tree is None:
        out['tree'] = None
    else:
        rows = tree.get('rows') if isinstance(tree, dict) else None
        if rows is None:
            out['tree'] = None
        elif not isinstance(rows, list):
            raise RecordError('tree.rows liste değil')
        else:
            parsed = []
            for r in rows:
                if not isinstance(r, dict):
                    raise RecordError('tree.rows öğesi nesne değil')
                parsed.append({
                    'y': _num(r, 'y'),
                    'half_width': _num(r, 'half_width'),
                    'dot_step': _num(r, 'dot_step'),
                })
            out['tree'] = sorted(parsed, key=lambda r: (r['y'] is None, r['y'] or 0))
    return out


def load_dir(path: Path) -> dict[str, dict]:
    return {p.stem: json.loads(p.read_text(encoding='utf-8'))
            for p in sorted(path.glob('*.json'))}


def _git(*args: str) -> str:
    return subprocess.run(['git', '-C', str(REPO), *args], check=True,
                          capture_output=True, text=True).stdout


def load_branch(ref: str) -> dict[str, dict]:
    out = {}
    for line in _git('ls-tree', '--name-only', ref, 'data/reticles/').splitlines():
        if line.endswith('.json'):
            out[Path(line).stem] = json.loads(_git('show', f'{ref}:{line}'))
    return out


def data_branches() -> list[str]:
    refs = _git('for-each-ref', '--format=%(refname:short)',
                'refs/remotes/origin/data/').split()
    base = [r for r in refs if r == 'origin/data/reticles']
    brands = sorted(r for r in refs if r.startswith('origin/data/reticles-'))
    return base + brands


def dart_str(s: str | None) -> str:
    if s is None:
        return 'null'
    return "'" + (s.replace('\\', '\\\\').replace("'", "\\'")
                  .replace('$', '\\$').replace('\n', ' ')) + "'"


def dart_num(v: float | None) -> str:
    if v is None:
        return 'null'
    r = repr(float(v))
    return r


def dart_bool(v: bool | None) -> str:
    return 'null' if v is None else ('true' if v else 'false')


def render(records: list[dict]) -> str:
    lines = [
        '// dart format off',
        '// GENERATED by tools/data_gen/generate_reticles.py from the',
        '// manufacturer-sourced data/reticles/*.json. Do not edit by hand;',
        '// re-run the script when the data branches change.',
        "import '../core/reticle.dart';",
        '',
        '/// Retikül ölçüleri (owner, 2026-10-11): null = the manufacturer',
        '/// source did not give the value; it is never guessed.',
        'abstract final class ReticleLibrary {',
        '  static const all = <ReticleData>[',
    ]
    for r in records:
        if r['tree'] is None:
            tree = 'null'
        else:
            tree = '[' + ', '.join(
                f"ReticleDataRow(y:{dart_num(x['y'])}, halfWidth:{dart_num(x['half_width'])}, "
                f"dotStep:{dart_num(x['dot_step'])})" for x in r['tree']) + ']'
        scopes = '[' + ', '.join(dart_str(s) for s in r['scopes']) + ']'
        fam = 'null' if r['family'] is None else f"'{r['family']}'"
        lines.append(
            f"    ReticleData(id:{dart_str(r['id'])}, brand:{dart_str(r['brand'])}, "
            f"name:{dart_str(r['name'])}, unit:'{r['unit']}', family:{fam}, "
            f"hashStep:{dart_num(r['hash_step'])}, majorEvery:{dart_num(r['major_every'])}, "
            f"numbersEvery:{dart_num(r['numbers_every'])}, extentH:{dart_num(r['extent_h'])}, "
            f"extentUp:{dart_num(r['extent_v_up'])}, extentDown:{dart_num(r['extent_v_down'])}, "
            f"tree:{tree}, postsStart:{dart_num(r['posts_start'])}, "
            f"centerDot:{dart_bool(r['center_dot'])}, "
            f"floatingCenter:{dart_bool(r['floating_center'])}, "
            f"lineWidth:{dart_num(r['line_width'])}, postWidth:{dart_num(r['post_width'])}, "
            f"scopes:{scopes}, sourceUrl:{dart_str(r['source_url'])}),")
    lines += ['  ];', '}', '']
    return '\n'.join(lines)


def build(raw: dict[str, dict]) -> tuple[str, list[str]]:
    records, skipped = [], []
    for stem in sorted(raw):
        try:
            records.append(normalize(stem, raw[stem]))
        except RecordError as e:
            skipped.append(f'{stem}: {e}')
    return render(records), skipped


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--from-branches', action='store_true',
                    help='origin/data/reticles + origin/data/reticles-* dallarını oku')
    ap.add_argument('--branch', action='append', default=[],
                    help='okunacak git ref (tekrarlanabilir, sonraki ezer)')
    ap.add_argument('--data-dir', type=Path, default=DATA_DIR)
    ap.add_argument('--out', type=Path, default=OUT)
    ap.add_argument('--check', action='store_true',
                    help='yazma; çıktı farklıysa 1 ile çık')
    a = ap.parse_args(argv)

    raw: dict[str, dict] = {}
    refs = list(a.branch) or (data_branches() if a.from_branches else [])
    if refs:
        for ref in refs:
            raw.update(load_branch(ref))
            print(f'okundu: {ref}', file=sys.stderr)
    else:
        raw.update(load_dir(a.data_dir))
    text, skipped = build(raw)
    for s in skipped:
        print('ATLANDI ' + s, file=sys.stderr)
    if a.check:
        current = a.out.read_text(encoding='utf-8') if a.out.exists() else ''
        if current != text:
            print(f'{a.out} güncel değil; scripti çalıştırın.', file=sys.stderr)
            return 1
        return 0
    a.out.write_text(text, encoding='utf-8')
    print(f'{a.out.relative_to(REPO) if a.out.is_relative_to(REPO) else a.out}: '
          f'{len(raw) - len(skipped)} retikül, {len(skipped)} atlandı', file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main())
