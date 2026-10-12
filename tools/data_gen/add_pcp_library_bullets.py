#!/usr/bin/env python3
"""Appends PCP pellets/slugs that have a maker-published BC in data/bullets-pcp
(extracted under tools/data_gen/bullets-pcp/) to lib/data/bullet_library.dart
when the BC was added by the 2026-10-11 BC completion run (data/bullets-bc)
and the library does not list them yet (same brand and name).
bullet_library.dart has no full generator; this only adds rows, never edits.
A missing drag model is taken as G1 (owner's rule, same as the existing PCP rows).
"""
import glob, json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LIB = HERE.parent.parent / 'lib/data/bullet_library.dart'


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def num(v):
    if v is None:
        return 'null'
    v = float(v)
    return str(int(v)) + '.0' if v == int(v) else repr(round(v, 4))


text = LIB.read_text()
have = {(m.group(1), m.group(2)) for m in re.finditer(r"LibraryBullet\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'", text)}
rows = []
for f in sorted(glob.glob(str(HERE / 'bullets-pcp/data/bullets-pcp/*.json'))):
    for r in json.load(open(f)):
        # Only rows whose BC came from the 2026-10-11 BC completion run (data/bullets-bc);
        # older rows were reviewed when the library was built (#79).
        if not r.get('bc') or 'BC (2026-10-11)' not in (r.get('notes') or '') or (r['brand'], r['name']) in have:
            continue
        if not (0.005 <= r['bc'] <= 1.5) or not (4.0 <= r['caliber_mm'] <= 13.0):
            print('skip (range)', r['name'], file=sys.stderr)
            continue
        typ = 'slug' if r['type'] == 'slug' else 'pellet'
        rows.append(f"    LibraryBullet({dart_str(r['brand'])}, {dart_str(r['name'])}, {dart_str(r.get('item_number') or '')}, "
                    f"{num(r['caliber_mm'])}, {num(r.get('head_size_mm') or r['caliber_mm'])}, {num(r['weight_gr'])}, "
                    f"{num(r['bc'])}, null, BallisticModel.g1, {num(r['bc'])}, [], {num(r.get('length_mm'))}, "
                    f"AmmunitionType.{typ}, WeaponPlatform.pcp, {dart_str(r['source_url'])}),\n")
end = text.rindex('  ];\n}')
LIB.write_text(text[:end] + ''.join(rows) + text[end:])
print('added', len(rows))
