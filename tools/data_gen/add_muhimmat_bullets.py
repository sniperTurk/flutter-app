#!/usr/bin/env python3
"""Mühimmat tamamlama (2026-10-12): appends to lib/data/bullet_library.dart
  * firearm bullets of data/muhimmat/bullets-firearm (new makers) that carry a
    maker BC,
  * PCP pellets/slugs of data/muhimmat/bullets-pcp (new makers),
  * PCP records of data/bullets-pcp (worktree tools/data_gen/bullets-pcp) that
    the library left out because the maker publishes no BC (Hatsan, My Bullet,
    RWS, Air Arms, Crosman, FX, NSA, Zan).
A record without a maker BC is listed with bc null (the form's BC box stays
empty). Rows already in the library (same brand and name) are never edited or
repeated, so the script can run again. `--check` exits 1 when rows would be added.
"""
import glob, json, re, sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
LIB = REPO / 'lib/data/bullet_library.dart'
PCP_MM = (4.5, 5.0, 5.5, 6.35, 7.62, 9.0, 11.43, 11.6, 12.7)


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def num(v):
    if v is None:
        return 'null'
    v = float(v)
    return str(int(v)) + '.0' if v == int(v) else repr(round(v, 4))


def name_of(s):
    return re.sub(r'(\d)gr\b', r'\1 gr', s)  # "30gr" -> "30 gr" (list label style)


def main(check=False):
    text = LIB.read_text()
    have = {(m.group(1), m.group(2)) for m in
            re.finditer(r"LibraryBullet\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'", text)}
    # PCP names carry no caliber (the rifle already picks it; owner,
    # 2026-10-12), so a PCP row is the same row only at the same caliber.
    have_pcp = {(m.group(1), m.group(2), float(m.group(3))) for m in
                re.finditer(r"LibraryBullet\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', '(?:[^'\\]|\\.)*', ([\d.]+), ", text)}
    # Kalibre list value of a true diameter, as the existing firearm rows use it.
    cal_of = {}
    counts = Counter((m.group(2), m.group(1)) for m in re.finditer(
        r"LibraryBullet\('(?:[^'\\]|\\.)*', '(?:[^'\\]|\\.)*', '(?:[^'\\]|\\.)*', ([\d.]+), ([\d.]+), .*WeaponPlatform\.firearm", text))
    for (dia, cal), _ in sorted(counts.items(), key=lambda kv: -kv[1]):
        cal_of.setdefault(float(dia), float(cal))
    rows, skipped = [], []
    for f in sorted(glob.glob(str(REPO / 'data/muhimmat/bullets-firearm/*.json'))):
        for r in json.load(open(f)):
            name = name_of(r['name'])
            # Firearm rows need a maker BC, as every firearm row of the library;
            # a BC withheld here (an Applied Ballistics '(A.B.)' value) is not
            # "no BC published", so the row stays out instead of saying so.
            if (r['brand'], name) in have or not (r.get('g1_bc') or r.get('g7_bc')):
                continue
            dia = round(r['diameter_in'] * 25.4, 3)
            cal = cal_of.get(dia, round(dia, 2))
            g1, g7 = r.get('g1_bc'), r.get('g7_bc')
            bc, model = (g7, 'g7') if g7 else (g1, 'g1')
            if not (4.0 <= cal <= 13.0) or (bc is not None and not 0.005 <= bc <= 1.5):
                skipped.append(name)
                continue
            length = None if r.get('length_in') is None else round(r['length_in'] * 25.4, 2)
            have.add((r['brand'], name))
            rows.append(f"    LibraryBullet({dart_str(r['brand'])}, {dart_str(name)}, {dart_str(r.get('item_number') or '')}, "
                        f"{num(cal)}, {num(dia)}, {num(r['weight_gr'])}, {num(g1)}, {num(g7)}, BallisticModel.{model}, "
                        f"{num(bc)}, [], {num(length)}, AmmunitionType.bullet, WeaponPlatform.firearm, {dart_str(r['source_url'])}),\n")
    new_pcp = sorted(glob.glob(str(REPO / 'data/muhimmat/bullets-pcp/*.json')))
    old_pcp = sorted(glob.glob(str(HERE / 'bullets-pcp/data/bullets-pcp/*.json')))
    for f in new_pcp + old_pcp:
        for r in json.load(open(f)):
            key = (r['brand'], r['name'], float(r['caliber_mm']))
            if key in have_pcp:
                continue
            # data/bullets-pcp rows with a BC were reviewed when the library was
            # built (#79, add_pcp_library_bullets.py); only the BC-less ones join.
            if f in old_pcp and r['bc'] is not None:
                continue
            if all(abs(r['caliber_mm'] - mm) > 0.01 for mm in PCP_MM) or (r['bc'] is not None and not 0.005 <= r['bc'] <= 1.5):
                skipped.append(r['name'])
                continue
            have.add((r['brand'], r['name']))
            have_pcp.add(key)
            typ = 'slug' if r['type'] == 'slug' else 'pellet'
            # A missing drag model is taken as G1 (owner's rule, as the existing PCP rows).
            rows.append(f"    LibraryBullet({dart_str(r['brand'])}, {dart_str(r['name'])}, {dart_str(r.get('item_number') or '')}, "
                        f"{num(r['caliber_mm'])}, {num(r.get('head_size_mm') or r['caliber_mm'])}, {num(r['weight_gr'])}, "
                        f"{num(r['bc'])}, null, BallisticModel.g1, {num(r['bc'])}, [], {num(r.get('length_mm'))}, "
                        f"AmmunitionType.{typ}, WeaponPlatform.pcp, {dart_str(r['source_url'])}),\n")
    for s in skipped:
        print('skip', s, file=sys.stderr)
    if check:
        print('would add', len(rows))
        return 1 if rows else 0
    if rows:
        end = text.rindex('  ];\n}')
        LIB.write_text(text[:end] + ''.join(rows) + text[end:])
    print('added', len(rows))
    return 0


if __name__ == '__main__':
    sys.exit(main('--check' in sys.argv))
