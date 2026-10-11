#!/usr/bin/env python3
"""Scope → reticle record audit (owner, 2026-10-11).

Reads the generated lib/data/scope_library.dart and
lib/data/reticle_library.dart, matches every scope's reticle name(s) to a
record of the same brand with the rules of
lib/data/reticle_catalog.dart (ReticleCatalog.find) and prints, per
brand, how many scopes match and why the others do not.

    python3 tools/reticle_match_audit.py            # brand table
    python3 tools/reticle_match_audit.py --legacy   # rules before #feat/retikul-eslestirme
    python3 tools/reticle_match_audit.py --missing  # reticles with no record
    python3 tools/reticle_match_audit.py --json
    python3 tools/reticle_match_audit.py --write-fixture

The fixture (test/fixtures/reticle_scope_matches.json) is what the Dart
test test/reticle_scope_match_test.dart checks ReticleCatalog against, so
the two implementations cannot drift apart.

Reason codes of an unmatched reticle name:
  kayit-yok    no record of the scope's brand with this name in any unit
  baska-marka  as kayit-yok, but another brand has a record of this name
               (never used: a brand only finds its own reticle)
  birim-farki  the brand has the reticle only in the other unit (MIL/MOA)
               than the scope's turret, or the name states the other unit
  belirsiz     two records cannot be told apart
"""

import argparse
import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURE = ROOT / 'test/fixtures/reticle_scope_matches.json'

# Words that name no reticle: focal plane, illumination, glass.
NOISE = {'FFP', 'SFP', 'IR', 'F1', 'ILLUMINATED', 'RETICLE', 'ETCHED', 'GLASS'}
UNITS = {'MIL': 'mil', 'MILS': 'mil', 'MRAD': 'mil', 'MOA': 'moa'}
FOCAL = {'FFP', 'SFP'}
_DASH_UNIT = re.compile(r'^(.+?)-(MIL|MILS|MRAD|MOA)$')
# "VCT-34FFP", "VEPG-TMIL": a focal-plane or unit word glued to the last
# part of a hyphenated designation.
_GLUED = re.compile(r'^(.*-[A-Z0-9]*?[A-Z0-9])(FFP|SFP|MILS|MIL|MRAD|MOA)$')


def options(reticle):
    """Reticle names of a scope record ("VPR-MIL / VHR-MIL" is two); a
    focal plane alone is not a reticle."""
    out = []
    for r in re.split(r'\s*/\s*', reticle or ''):
        r = r.strip()
        if r and r not in FOCAL:
            out.append(r)
    return out


def name_key(name, legacy=False):
    """(core, unit): the designation without unit and focal-plane words."""
    unit = None
    core = []
    for t in re.split(r'[\s(),/]+', name.upper()):
        if not t or t in NOISE:
            continue
        if t in UNITS:
            unit = UNITS[t]
            continue
        m = _DASH_UNIT.match(t)
        if m:
            unit = UNITS[m.group(2)]
            t = m.group(1)
        if not legacy:
            while True:
                g = _GLUED.match(t)
                if not g:
                    break
                t = g.group(1)
                if g.group(2) in UNITS:
                    unit = UNITS[g.group(2)]
            # "SKMR4+" is not "SKMR4".
            t = t.replace('+', 'PLUS')
        core.append(re.sub(r'[^A-Z0-9]', '', t))
    return ''.join(core), unit


def brand_words(brand):
    return [w for w in re.split(r'[^a-z0-9]+', brand.lower())
            if w and w not in ('optics', 'optic')]


def brand_matches(data_brand, scope_brand):
    d, s = brand_words(data_brand), brand_words(scope_brand)
    return bool(d) and len(s) >= len(d) and s[:len(d)] == d


def turret(unit):
    return 'mil' if unit == 'mrad' else 'moa'


def find(name, turret_unit, brand, lib, legacy=False, model=''):
    """The record for [name] on a [brand] scope, or None."""
    return _find(name, turret_unit, brand, lib, legacy, model)[0]


def _words(text):
    return [w for w in re.split(r'[^a-z0-9]+', (text or '').lower()) if w]


def names_scope(record, brand, model):
    """True when one of the record's manufacturer scope series is in the
    scope's brand + model words ("Helos BTR GEN2" in "HELOS BTR GEN2
    6-24x56 …")."""
    words = _words(f'{brand} {model}')
    for entry in record.get('scopes', []):
        e = _words(entry)
        if e and any(words[i:i + len(e)] == e
                     for i in range(len(words) - len(e) + 1)):
            return True
    return False


def _find(name, turret_unit, brand, lib, legacy=False, model=''):
    if not name or not brand:
        return None, 'kayit-yok'
    if not legacy and len(options(name)) != 1:
        return None, 'coklu'
    core, unit = name_key(name, legacy)
    if not core:
        return None, 'kayit-yok'
    same = [r for r in lib if name_key(r['name'], legacy)[0] == core]
    hits = [r for r in same if brand_matches(r['brand'], brand)]
    if not hits:
        return None, 'baska-marka' if same else 'kayit-yok'
    want = turret(turret_unit)
    if legacy:
        if unit is not None:
            hits = [r for r in hits if r['unit'] == unit]
        elif len(hits) > 1:
            hits = [r for r in hits if r['unit'] == want]
    else:
        if unit is not None and unit != want:
            return None, 'birim-farki'
        hits = [r for r in hits if r['unit'] == want]
    if not hits:
        return None, 'birim-farki'
    if len(hits) > 1 and not legacy:
        # Same name twice (with and without illumination): the record whose
        # manufacturer scope list names this scope, if exactly one does.
        named = [r for r in hits if names_scope(r, brand, model)]
        if len(named) == 1:
            hits = named
    if len(hits) > 1:
        return None, 'belirsiz'
    return hits[0], None


def drawable(r):
    """Mirrors ReticleData.toSpec: a known family and, for marks, a step."""
    f = r.get('family')
    if f not in ('tree', 'hash', 'mildot', 'duplex'):
        return False
    return f == 'duplex' or r.get('hashStep') is not None


def audit_scope(s, lib, legacy=False):
    names = options(s['reticle'])
    if legacy:
        # Before: the Profil list split the names, but Hedef got whatever
        # the scope record held, so a multi-name record found nothing.
        names_eval = [s['reticle']] if s['reticle'] else []
    else:
        names_eval = names
    row = {'id': s['id'], 'brand': s['brand'], 'reticle': s['reticle'],
           'unit': s['unit'], 'multi': len(names) > 1,
           'records': [], 'reasons': [], 'missing': []}
    if not names_eval:
        row.update(status='retikul-yok', drawable=False)
        return row
    found = 0
    draw = True
    for n in names_eval:
        hit, why = _find(n, s['unit'], s['brand'], lib, legacy,
                         s.get('model', ''))
        row['records'].append(hit['id'] if hit else None)
        if hit:
            found += 1
            draw = draw and drawable(hit)
        else:
            row['reasons'].append(why)
            row['missing'].append(n)
            draw = False
    row['status'] = ('eslesti' if found == len(names_eval)
                     else 'kismi' if found else 'eslesmedi')
    row['drawable'] = draw
    return row


def audit(scopes, lib, legacy=False):
    rows = [audit_scope(s, lib, legacy) for s in scopes]
    brands = collections.OrderedDict()
    for r in sorted(rows, key=lambda r: r['brand']):
        b = brands.setdefault(r['brand'], collections.Counter())
        b['toplam'] += 1
        b['eslesti' if r['status'] == 'eslesti' else 'eslesmedi'] += 1
        if r['status'] == 'eslesti' and r['drawable']:
            b['cizilir'] += 1
        if r['status'] == 'retikul-yok':
            b['retikul-yok'] += 1
        if r['status'] == 'kismi':
            b['kismi'] += 1
        for why in r['reasons']:
            b[why] += 1
    return {'scopes': rows, 'brands': {k: dict(v) for k, v in brands.items()}}


# ---- Parsing the generated Dart lists ----

_SCOPE = re.compile(r"ScopeOptic\((.*)\),\s*$", re.M)
_RETICLE = re.compile(r"ReticleData\((.*)\),\s*$", re.M)


def _field(body, key):
    m = re.search(r"\b%s:'((?:[^'\\]|\\.)*)'" % key, body)
    return m.group(1).replace("\\'", "'") if m else None


def _num(body, key):
    m = re.search(r"\b%s:(null|[-0-9.]+)" % key, body)
    return None if not m or m.group(1) == 'null' else float(m.group(1))


def parse_scopes(text):
    out = []
    for m in _SCOPE.finditer(text):
        b = m.group(1)
        unit = re.search(r"clickUnit:AngularUnit\.(\w+)", b).group(1)
        out.append({'id': _field(b, 'id'), 'brand': _field(b, 'brand'),
                    'model': _field(b, 'model'),
                    'reticle': _field(b, 'reticle') or '', 'unit': unit})
    return out


def parse_reticles(text):
    out = []
    for m in _RETICLE.finditer(text):
        b = m.group(1)
        fam = re.search(r"\bfamily:(null|'(\w+)')", b)
        out.append({'id': _field(b, 'id'), 'brand': _field(b, 'brand'),
                    'name': _field(b, 'name'), 'unit': _field(b, 'unit'),
                    'family': fam.group(2) if fam else None,
                    'hashStep': _num(b, 'hashStep'),
                    'scopes': re.findall(r"'((?:[^'\\]|\\.)*)'",
                                         re.search(r"scopes:\[(.*?)\]",
                                                   b).group(1))})
    return out


def load(root=ROOT):
    scopes = parse_scopes((root / 'lib/data/scope_library.dart').read_text())
    lib = parse_reticles((root / 'lib/data/reticle_library.dart').read_text())
    return scopes, lib


def fixture(root=ROOT):
    """{scope id: {reticle name: record id or null}} for every listed
    reticle name of every scope."""
    scopes, lib = load(root)
    out = {}
    for s in scopes:
        names = options(s['reticle'])
        if not names:
            continue
        out[s['id']] = {}
        for n in names:
            hit = find(n, s['unit'], s['brand'], lib, model=s['model'])
            out[s['id']][n] = hit['id'] if hit else None
    return out


def missing(result):
    """Reticle names with no usable record, per brand and reason."""
    out = collections.defaultdict(lambda: collections.defaultdict(set))
    for r in result['scopes']:
        for n, why in zip(r['missing'], r['reasons']):
            out[r['brand']][n].add(f"{why} ({r['unit'].upper()})")
    return out


def table(result):
    cols = ['toplam', 'eslesti', 'cizilir', 'eslesmedi', 'kismi',
            'retikul-yok', 'kayit-yok', 'baska-marka', 'birim-farki',
            'belirsiz']
    lines = ['| Marka | ' + ' | '.join(cols) + ' |',
             '|---|' + '---:|' * len(cols)]
    tot = collections.Counter()
    for brand, c in result['brands'].items():
        tot.update(c)
        lines.append(f'| {brand} | ' +
                     ' | '.join(str(c.get(k, 0)) for k in cols) + ' |')
    lines.append('| **Toplam** | ' +
                 ' | '.join(str(tot.get(k, 0)) for k in cols) + ' |')
    return '\n'.join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--legacy', action='store_true')
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--missing', action='store_true')
    ap.add_argument('--write-fixture', action='store_true')
    a = ap.parse_args(argv)
    if a.write_fixture:
        FIXTURE.parent.mkdir(parents=True, exist_ok=True)
        FIXTURE.write_text(json.dumps(fixture(), indent=1, sort_keys=True,
                                      ensure_ascii=False) + '\n')
        print(f'wrote {FIXTURE.relative_to(ROOT)}')
        return 0
    scopes, lib = load()
    result = audit(scopes, lib, a.legacy)
    if a.json:
        print(json.dumps(result, indent=1, ensure_ascii=False))
    elif a.missing:
        for brand, names in sorted(missing(result).items()):
            print(f'## {brand}')
            for n, why in sorted(names.items()):
                print(f"- {n}: {', '.join(sorted(why))}")
    else:
        print(table(result))
    return 0


if __name__ == '__main__':
    sys.exit(main())
