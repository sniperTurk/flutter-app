#!/usr/bin/env python3
"""Bullet type / tip shape data (owner, 2026-10-13; docs/research/bc_tip_gruplari.md).

Reads lib/data/factory_ammo_library.dart and lib/data/bullet_library.dart
(never writes them) and joins them to the manufacturer-sourced shape data
under data/bullet_shape/.

Data layout
  data/bullet_shape/rules/<brand>.json   hand-collected source file: the maker
      pages that were read (url + read date) and which records each statement
      covers (a family regex over the record name, or an explicit record key).
  data/bullet_shape/<brand>.json         generated: one entry per library record
      of that brand, keyed by the record key, every field with its own
      source_url / read_date / evidence. Fields the maker does not state are
      null (never guessed).

Record key: '<brand>|<name>' (+ '|<item>' for a bullet with an item number,
+ '|<cartridge>' for a factory cartridge; '@<caliber> mm' when a PCP name
repeats across calibres).

Field precedence: an explicit record entry > the last matching family rule >
an explicit word in the maker's product name (evidence 'product_name'; the
name is the maker's own as stored with the record's source URL).

Commands
  inputs  <dir>   write per-brand record lists (for collecting the data)
  expand          rules/*.json -> data/bullet_shape/<brand>.json
  join   [out]    one joined JSON table (library fields + shape fields)
  coverage <brand> [-v]  read-only per-record view of one brand
  analyze         leave-one-brand-out BC estimator study -> stdout (markdown)
  table           group form-factor table -> stdout (markdown)
  candidates      records without a maker BC that a group fills -> data/bullet_shape/estimated_bc_candidates.json
  check           exit 1 when the generated files are stale
"""
import ast, glob, json, re, statistics, sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FACTORY = REPO / 'lib/data/factory_ammo_library.dart'
BULLETS = REPO / 'lib/data/bullet_library.dart'
OUT = REPO / 'data/bullet_shape'
RULES = OUT / 'rules'

CONSTRUCTION = {
    'cup_and_core', 'bonded', 'partition', 'monolithic_copper', 'fmj', 'match',
    'lead_free_other',
    # PCP
    'lead_pellet', 'lead_slug', 'lead_free_pellet', 'lead_free_slug',
}
TIP = {
    'polymer_tip', 'spitzer_soft_point', 'semi_spitzer', 'round_nose', 'flat_nose',
    'hollow_point', 'open_tip_match', 'fmj_pointed', 'fmj_round',
    # the maker says "soft point" but not its shape
    'soft_point',
    # PCP
    'pointed', 'wadcutter',
}
BASE = {'boat_tail', 'flat_base', 'hollow_base'}
FIELDS = ('construction', 'tip_shape', 'base', 'component_bullet')
ALLOWED = {'construction': CONSTRUCTION, 'tip_shape': TIP, 'base': BASE}


# ---------------------------------------------------------------- libraries
def _split(s):
    out, depth, cur, q, i = [], 0, '', None, 0
    while i < len(s):
        c = s[i]
        if q:
            cur += c
            if c == '\\':
                cur += s[i + 1]; i += 2; continue
            if c == q:
                q = None
        elif c in "'\"":
            q = c; cur += c
        elif c in '([{':
            depth += 1; cur += c
        elif c in ')]}':
            depth -= 1; cur += c
        elif c == ',' and depth == 0:
            out.append(cur.strip()); cur = ''
        else:
            cur += c
        i += 1
    if cur.strip():
        out.append(cur.strip())
    return out


def _val(t):
    t = t.strip()
    if t == 'null':
        return None
    if t in ('true', 'false'):
        return t == 'true'
    if t.startswith("'"):
        return ast.literal_eval(t)
    if re.match(r'^(BallisticModel|AmmunitionType|WeaponPlatform)\.', t):
        return t.split('.', 1)[1]
    if t.startswith('['):
        return [(int(a), float(b)) for a, b in re.findall(r'\((\d+), ([\d.]+)\)', t)]
    return float(t)


def load_library():
    recs = []
    for line in FACTORY.read_text().splitlines():
        m = re.match(r'\s*FactoryAmmo\((.*)\),\s*$', line)
        if not m:
            continue
        a = _split(m.group(1))
        pos = [_val(x) for x in a if not re.match(r'^\w+:', x)]
        kw = {x.split(':', 1)[0]: _val(x.split(':', 1)[1]) for x in a if re.match(r'^\w+:', x)}
        recs.append(dict(lib='factory', platform='firearm', type='bullet', brand=pos[0],
                         name=pos[1], cartridge=pos[2], diameter_mm=pos[3], grain=pos[4],
                         bc=pos[5], model=pos[6], mv_fps=pos[7], source_url=pos[9],
                         bc_from_bullet=kw.get('bcFromBullet', False),
                         bc_source=kw.get('bcSource')))
    for line in BULLETS.read_text().splitlines():
        m = re.match(r'\s*LibraryBullet\((.*)\),\s*$', line)
        if not m:
            continue
        p = [_val(x) for x in _split(m.group(1))]
        recs.append(dict(lib='bullet', brand=p[0], name=p[1], item=p[2], caliber_mm=p[3],
                         diameter_mm=p[4], grain=p[5], g1=p[6], g7=p[7], model=p[8], bc=p[9],
                         type=p[12], platform=p[13], source_url=p[14]))
    keys = Counter(_base_key(r) for r in recs)
    for r in recs:
        k = _base_key(r)
        r['key'] = k if keys[k] == 1 else f"{k}@{r.get('caliber_mm') or r['diameter_mm']:g} mm"
    assert len({r['key'] for r in recs}) == len(recs)
    return recs


def _base_key(r):
    if r['lib'] == 'factory':
        return f"{r['brand']}|{r['name']}|{r['cartridge']}"
    return f"{r['brand']}|{r['name']}" + (f"|{r['item']}" if r['item'] else '')


def slug(brand):
    return re.sub(r'[^a-z0-9]+', '_', brand.lower().replace('&', 'and')).strip('_')


# ------------------------------------------------------- product-name words
def _w(p):
    return re.compile(r'(?<![A-Za-z0-9])(?:' + p + r')(?![A-Za-z0-9])', re.I)


# Only words that state the field outright. "SP" says soft point but not its
# shape; "FMJ" says nothing about the nose; brand line names (V-MAX, SST …)
# are left to the maker's line page.
NAME_RULES = [
    ('base', _w(r'boat[- ]?tail|BT|HPBT|BTHP|SBT|FMJBT|FMJ-BT|BTSP|SPBT|BTHP-?Match|HPBT-?Match|OTM-?BT|ELD-?BT'), 'boat_tail'),
    ('base', _w(r'flat[- ]?base|FB|HPFB|FMJFB'), 'flat_base'),
    ('base', _w(r'hollow[- ]?base'), 'hollow_base'),
    ('tip_shape', _w(r'polymer[- ]?tip(?:ped)?|plastic[- ]?tip(?:ped)?|ballistic[- ]?tip'), 'polymer_tip'),
    ('tip_shape', _w(r'open[- ]tip[- ]match|OTM'), 'open_tip_match'),
    ('tip_shape', _w(r'(?:HPBT|BTHP|hollow[- ]point[- ]boat[- ]?tail)[- ]match|match[- ](?:HPBT|BTHP)'), 'open_tip_match'),
    ('tip_shape', _w(r'semi[- ]?spitzer|SSP'), 'semi_spitzer'),
    ('tip_shape', _w(r'spitzer[- ]soft[- ]point|pointed[- ]soft[- ]point|PSP|SPSP|spitzer[- ]SP'), 'spitzer_soft_point'),
    ('tip_shape', _w(r'FMJ[- ]?(?:RN|round[- ]nose)|(?:RN|round[- ]nose)[- ]FMJ|full[- ]metal[- ]jacket[- ]round[- ]nose'), 'fmj_round'),
    ('tip_shape', _w(r'FMJ[- ]?spitzer|spitzer[- ]FMJ|pointed[- ]FMJ|FMJ[- ]pointed'), 'fmj_pointed'),
    ('tip_shape', _w(r'hollow[- ]?point|HP|JHP|HPBT|BTHP|LHP|CPHP'), 'hollow_point'),
    ('tip_shape', _w(r'round[- ]nose|RN|RNSP|SPRN|LRN|domed?'), 'round_nose'),
    ('tip_shape', _w(r'flat[- ]nose|flat[- ]point|FN|FP|FNSP|SPFN|JFP|JFN'), 'flat_nose'),
    ('tip_shape', _w(r'wad[- ]?cutter|WC'), 'wadcutter'),
    ('tip_shape', _w(r'soft[- ]?point|SP|JSP'), 'soft_point'),
    ('tip_shape', _w(r'pointed'), 'pointed'),
    ('construction', _w(r'full[- ]metal[- ]jacket|FMJ|TMJ|total[- ]metal[- ]jacket|FMJBT'), 'fmj'),
    ('construction', _w(r'bonded'), 'bonded'),
    ('construction', _w(r'partition'), 'partition'),
    ('construction', _w(r'(?:solid|all|mono(?:lithic)?)[- ]copper|monolithic'), 'monolithic_copper'),
]
# a tip word found first wins over later, more generic ones
_TIP_ORDER = [v for f, _, v in NAME_RULES if f == 'tip_shape']


def name_fields(r):
    """Fields stated by explicit words of the maker's product name."""
    out = {}
    name = r['name']
    for field, rx, value in NAME_RULES:
        m = rx.search(name)
        if not m or field in out:
            continue
        if field == 'tip_shape' and r['platform'] == 'pcp' and value == 'soft_point':
            continue
        out[field] = dict(value=value, source_url=r['source_url'], read_date=None,
                          evidence='product_name', quote=m.group(0))
    # "Match" alone is a construction word only for firearm bullets
    if 'construction' not in out and r['platform'] == 'firearm':
        m = _w(r'match').search(name)
        tip = out.get('tip_shape', {}).get('value')
        if m and tip in ('open_tip_match', 'hollow_point'):
            out['construction'] = dict(value='match', source_url=r['source_url'], read_date=None,
                                       evidence='product_name', quote=m.group(0))
    return out


# -------------------------------------------------------------------- rules
def load_rules():
    rules = {}
    for f in sorted(RULES.glob('*.json')):
        d = json.loads(f.read_text())
        rules[f.stem] = d
    return rules


def _field_from_rule(spec, sources, where):
    src = sources.get(spec['src'])
    if src is None:
        raise SystemExit(f'{where}: unknown source id {spec["src"]!r}')
    return dict(value=spec['value'], source_url=src['url'], read_date=src['read_date'],
                evidence=spec.get('evidence', 'maker_page'), quote=spec.get('quote'))


def validate_value(field, value, where):
    if field in ALLOWED and value not in ALLOWED[field]:
        raise SystemExit(f'{where}: {field}={value!r} not in {sorted(ALLOWED[field])}')


def expand(recs, rules):
    by_brand = defaultdict(list)
    for r in recs:
        by_brand[slug(r['brand'])].append(r)
    keyset = {r['key'] for r in recs}
    result = {}
    for b, rows in sorted(by_brand.items()):
        rule = rules.get(b, {})
        sources = {s['id']: s for s in rule.get('sources', [])}
        fams = rule.get('families', [])
        explicit = rule.get('records', {})
        for k in explicit:
            if k not in keyset:
                raise SystemExit(f'rules/{b}.json: record key not in library: {k!r}')
        out = {}
        used = Counter()
        for r in rows:
            fields = {f: None for f in FIELDS}
            via = {}
            for f, v in name_fields(r).items():
                fields[f] = v; via[f] = 'name'
            for fam in fams:
                lib = fam.get('lib', 'any')
                if lib != 'any' and lib != r['lib']:
                    continue
                if 'platform' in fam and fam['platform'] != r['platform']:
                    continue
                if not re.search(fam['name_regex'], r['name'], re.I):
                    continue
                if 'not_regex' in fam and re.search(fam['not_regex'], r['name'], re.I):
                    continue
                if 'cartridge_regex' in fam and not re.search(fam['cartridge_regex'], r.get('cartridge', ''), re.I):
                    continue
                used[fam['id']] += 1
                for f, spec in fam['fields'].items():
                    where = f'rules/{b}.json family {fam["id"]}'
                    validate_value(f, spec['value'], where)
                    fields[f] = _field_from_rule(spec, sources, where); via[f] = fam['id']
            for f, spec in explicit.get(r['key'], {}).items():
                where = f'rules/{b}.json record {r["key"]}'
                if spec is None:
                    fields[f] = None; continue
                validate_value(f, spec['value'], where)
                fields[f] = _field_from_rule(spec, sources, where); via[f] = 'record'
            entry = dict(lib=r['lib'], platform=r['platform'], name=r['name'],
                         grain=r['grain'], library_source_url=r['source_url'])
            if r['lib'] == 'factory':
                entry['cartridge'] = r['cartridge']
            else:
                entry['caliber_mm'] = r['caliber_mm']
                if r['item']:
                    entry['item'] = r['item']
            if r['lib'] != 'factory':
                fields.pop('component_bullet')
            entry.update(fields)
            out[r['key']] = entry
        for fam in fams:
            if not used[fam['id']]:
                print(f'warning: rules/{b}.json family {fam["id"]} matches no record', file=sys.stderr)
        brand = rows[0]['brand']
        result[b] = dict(
            brand=brand,
            generated_by='tools/data_gen/bullet_shape.py expand',
            note=rule.get('note'),
            sources=rule.get('sources', []),
            records=out)
    return result


def write_expanded(result, check=False):
    stale = []
    for b, d in result.items():
        p = OUT / f'{b}.json'
        txt = json.dumps(d, ensure_ascii=False, indent=1) + '\n'
        if not p.exists() or p.read_text() != txt:
            stale.append(p)
            if not check:
                p.write_text(txt)
    return stale


def joined(recs, result):
    rows = []
    for r in recs:
        e = result[slug(r['brand'])]['records'][r['key']]
        row = dict(r)
        for f in FIELDS:
            v = e.get(f)
            row[f] = v['value'] if v else None
            row[f + '_evidence'] = v['evidence'] if v else None
        rows.append(row)
    return rows


# ------------------------------------------------------------------ analysis
# Form factor i = SD / BC(G1), SD = grain / (7000 · d²) (lb/in², d in inches);
# estimated BC = SD / i(group). Only maker G1 BCs are used (a G7-only record
# is left out rather than converted).
MIN_N = 5          # records a group needs before it is used
MIN_BRANDS = 2     # … from at least this many bullet makers
# order chosen by LOBO (bullets): c×t (no base) did worse than t×b / t, so it is not used
LEVELS = ('c×t×b', 't×b', 't', 'c')

_MAKERS = ('Hornady', 'Sierra', 'Nosler', 'Berger', 'Barnes', 'Speer', 'Swift', 'Woodleigh',
           'Federal', 'Norma', 'Lapua', 'Sako', 'RWS', 'Cutting Edge', 'Hammer', 'Peregrine',
           'Winchester', 'Remington', 'Fiocchi', 'Prvi', 'Sellier')


def g1_of(r):
    if r['lib'] == 'bullet':
        return r['g1']
    return r['bc'] if r['model'] == 'g1' and r['bc'] else None


def sd(r):
    d = r['diameter_mm'] / 25.4
    return r['grain'] / (7000 * d * d)


def pct(xs, q):
    xs = sorted(xs)
    if not xs:
        return float('nan')
    k = (len(xs) - 1) * q
    lo, hi = int(k), min(int(k) + 1, len(xs) - 1)
    return xs[lo] + (xs[hi] - xs[lo]) * (k - lo)


def bullet_maker(r):
    """The brand whose bullet it is: a factory BC usually is the bullet
    maker's figure, so leave-one-brand-out must hold out that maker."""
    cb = r.get('component_bullet') or ''
    for m in _MAKERS:
        if cb.lower().startswith(m.lower()):
            return {'Cutting Edge': 'Cutting Edge Bullets', 'Hammer': 'Hammer Bullets',
                    'Prvi': 'Prvi Partizan', 'Sellier': 'Sellier & Bellot'}.get(m, m)
    return r['brand']


def tip_group(r):
    """A match bullet the maker calls hollow point is the open-tip match nose."""
    t = r['tip_shape']
    if t == 'hollow_point' and r['construction'] == 'match':
        return 'open_tip_match'
    return t


def group_keys(r):
    c, t, b = r['construction'], r['tipg'], r['base']
    have = {'c×t×b': (c, t, b) if c and t and b else None,
            't×b': (t, b) if t and b else None,
            't': (t,) if t else None,
            'c': (c,) if c else None}
    return [(lvl, have[lvl]) for lvl in LEVELS if have[lvl]]


def analysis_rows(rows, platform, libs=('bullet', 'factory'), typ=None):
    out = []
    for r in rows:
        if r['platform'] != platform or r['lib'] not in libs:
            continue
        if typ and r['type'] != typ:
            continue
        g = g1_of(r)
        if not g or not r['grain'] or not r['diameter_mm']:
            continue
        rr = dict(r, g1x=g, sd=sd(r))
        rr['i'] = rr['sd'] / g
        rr['tipg'] = tip_group(r)
        rr['maker'] = bullet_maker(r)
        out.append(rr)
    return out


def build_table(train, min_brands=None):
    min_brands = MIN_BRANDS if min_brands is None else min_brands
    tab = defaultdict(list)
    for r in train:
        for lvl, k in group_keys(r):
            tab[(lvl, k)].append(r)
    return {k: (statistics.median(x['i'] for x in v), len(v), len({x['maker'] for x in v}))
            for k, v in tab.items()
            if len(v) >= MIN_N and len({x['maker'] for x in v}) >= min_brands}


def predict(r, table, global_i):
    for lvl, k in group_keys(r):
        if (lvl, k) in table:
            return table[(lvl, k)][0], lvl, k
    return global_i, 'global', None


def lobo(data, use_groups=True):
    """Leave-one-brand-out: every form factor comes from the other makers."""
    res = []
    for m in sorted({r['maker'] for r in data}):
        train = [r for r in data if r['maker'] != m]
        if not train:
            continue
        gl = statistics.median(r['i'] for r in train)
        table = build_table(train) if use_groups else {}
        for r in data:
            if r['maker'] != m:
                continue
            i, lvl, k = predict(r, table, gl)
            est = r['sd'] / i
            res.append(dict(r, est=est, err=abs(est - r['g1x']) / r['g1x'], level=lvl, gkey=k))
    return res


def loo(data, use_groups=True):
    """Leave-one-record-out, for sets with too few makers for LOBO (PCP pellets:
    44 of 45 are H&N). Optimistic: the same maker's siblings stay in training."""
    res = []
    for j, r in enumerate(data):
        train = data[:j] + data[j + 1:]
        gl = statistics.median(x['i'] for x in train)
        table = build_table(train, min_brands=1) if use_groups else {}
        i, lvl, k = predict(r, table, gl)
        est = r['sd'] / i
        res.append(dict(r, est=est, err=abs(est - r['g1x']) / r['g1x'], level=lvl, gkey=k))
    return res


def stats(res):
    e = [x['err'] for x in res]
    return len(e), pct(e, .5), pct(e, .75), pct(e, .9)


def row(label, res):
    n, m, q3, q9 = stats(res)
    return f'| {label} | {n} | {m*100:.0f} % | {q3*100:.0f} % | {q9*100:.0f} % |'


HDR = '| Method | Records | Median | 75 % | 90 % |\n|---|---|---|---|---|'


def _block(lines, title, data):
    if not data:
        return
    cv = lobo
    if len({r['maker'] for r in data}) < 3:
        cv = loo
        title += ' — leave-one-RECORD-out (too few makers for LOBO; optimistic)'
    base = {x['key']: x for x in cv(data, use_groups=False)}
    grp = cv(data)
    lines += [f'\n### {title}\n', HDR,
              row('Global form factor', list(base.values())),
              row('Shape groups → fallback', grp)]
    cov = [x for x in grp if x['level'] != 'global']
    if cov:
        lines.append(row('… records a shape group covered: groups', cov))
        lines.append(row('… same records: global', [base[x['key']] for x in cov]))
    full = [x for x in grp if x['level'] == 'c×t×b']
    if full:
        lines.append(row('… records with all three fields: groups', full))
        lines.append(row('… same records: global', [base[x['key']] for x in full]))
    lines += ['\nBy level used:\n', HDR.replace('Method', 'Level')]
    for lvl in LEVELS + ('global',):
        xs = [x for x in grp if x['level'] == lvl]
        if xs:
            lines.append(row(lvl, xs))
    return grp


def analyze(rows):
    L = ['## Leave-one-brand-out cross-validation (G1)',
         f'Group used when it has ≥ {MIN_N} records from ≥ {MIN_BRANDS} bullet makers '
         'outside the held-out maker; order ' + ' → '.join(LEVELS) + ' → global.']
    fb = analysis_rows(rows, 'firearm', ('bullet',))
    grp = _block(L, 'Firearm component bullets (bullet_library)', fb)
    h = [x for x in grp if x['brand'] == 'Hornady']
    hb = [x for x in lobo(fb, use_groups=False) if x['brand'] == 'Hornady']
    L += ['\nHornady subset (owner baseline: no family 15 % / 71 %, same family 8 % / 35 %):\n', HDR,
          row('Hornady, global (other makers)', hb), row('Hornady, shape groups (other makers)', h)]
    _block(L, 'Firearm factory cartridges with a maker G1 BC (held out by bullet maker)',
           analysis_rows(rows, 'firearm', ('factory',)))
    _block(L, 'Firearm, bullets + cartridges pooled', analysis_rows(rows, 'firearm'))
    for typ in ('slug', 'pellet'):
        _block(L, f'PCP {typ}', analysis_rows(rows, 'pcp', typ=typ))
    L += ['\n## Per-group error (firearm, pooled; records whose full group was used)\n',
          '| Construction × tip × base | Records | Makers | i (median) | i IQR | LOBO median | 75 % | 90 % |',
          '|---|---|---|---|---|---|---|---|']
    pooled = analysis_rows(rows, 'firearm')
    res = lobo(pooled)
    by = defaultdict(list)
    for x in res:
        by[(x['level'], x['gkey'])].append(x)
    for d in group_table(rows):
        xs = by.get((d['level'], d['group']), [])
        if d['level'] != 'c×t×b':
            continue
        e = [x['err'] for x in xs]
        L.append(f"| {' × '.join(d['group'])} | {d['n']} | {d['makers']} | {d['i']:.3f} | "
                 f"{d['q1']:.3f}–{d['q3']:.3f} | " +
                 (f"{pct(e,.5)*100:.0f} % | {pct(e,.75)*100:.0f} % | {pct(e,.9)*100:.0f} % |" if e else '– | – | – |'))
    return '\n'.join(L)


def group_table(rows, platform='firearm', typ=None):
    data = analysis_rows(rows, platform, typ=typ)
    tab = defaultdict(list)
    for r in data:
        for lvl, k in group_keys(r):
            tab[(lvl, k)].append(r)
    out = []
    for (lvl, k), xs in tab.items():
        makers = len({x['maker'] for x in xs})
        if len(xs) < MIN_N or makers < MIN_BRANDS:
            continue
        ii = [x['i'] for x in xs]
        out.append(dict(level=lvl, group=k, n=len(xs), makers=makers,
                        i=statistics.median(ii), q1=pct(ii, .25), q3=pct(ii, .75)))
    out.sort(key=lambda d: (LEVELS.index(d['level']), -d['n']))
    return out


def fill_candidates(rows):
    """Records without any maker BC that a shape group would fill (tahmini)."""
    out = []
    for platform, typs in (('firearm', (None,)), ('pcp', ('slug', 'pellet'))):
        for typ in typs:
            data = analysis_rows(rows, platform, typ=typ)
            if not data:
                continue
            table = build_table(data)
            for r in rows:
                if r['platform'] != platform or (typ and r['type'] != typ):
                    continue
                if r['bc'] or r.get('g1') or r.get('g7') or not r['grain'] or not r['diameter_mm']:
                    continue
                rr = dict(r, tipg=tip_group(r))
                for lvl, k in group_keys(rr):
                    if (lvl, k) in table:
                        i, n, mk = table[(lvl, k)]
                        out.append(dict(
                            key=r['key'], lib=r['lib'], platform=platform, type=r['type'],
                            brand=r['brand'], name=r['name'],
                            cartridge=r.get('cartridge') or f"{r.get('caliber_mm'):g} mm",
                            grain=r['grain'], diameter_mm=r['diameter_mm'],
                            construction=r['construction'], tip_shape=r['tip_shape'], base=r['base'],
                            level=lvl, group=list(k), group_records=n, group_makers=mk,
                            form_factor=round(i, 3), bc_g1_tahmini=round(sd(r) / i, 3),
                            label='tahmini',
                            # only a known tip shape beat the global factor in
                            # LOBO; a construction-only group or any PCP group did not
                            recommended=platform == 'firearm' and lvl != 'c'))
                        break
    return out


def main(argv):
    cmd = argv[1] if len(argv) > 1 else 'expand'
    recs = load_library()
    if cmd == 'inputs':
        d = Path(argv[2]); d.mkdir(parents=True, exist_ok=True)
        by = defaultdict(list)
        for r in recs:
            nf = {k: v['value'] for k, v in name_fields(r).items()}
            by[slug(r['brand'])].append(dict(
                key=r['key'], lib=r['lib'], platform=r['platform'], type=r['type'],
                name=r['name'], cartridge=r.get('cartridge'), caliber_mm=r.get('caliber_mm'),
                grain=r['grain'], source_url=r['source_url'], name_words=nf))
        for b, rows in by.items():
            (d / f'{b}.json').write_text(json.dumps(rows, ensure_ascii=False, indent=0))
        print(len(recs), 'records,', len(by), 'brands')
        return 0
    rules = load_rules()
    result = expand(recs, rules)
    if cmd == 'expand':
        stale = write_expanded(result)
        print(f'{len(result)} brand files, {len(stale)} written')
        return 0
    if cmd == 'coverage':
        # read-only: per-record fields of one brand (validates its rules file)
        b = slug(argv[2])
        recs_b = result[b]['records']
        n = len(recs_b)
        for f in ('construction', 'tip_shape', 'base', 'component_bullet'):
            have = sum(1 for e in recs_b.values() if e.get(f))
            print(f'{f}: {have}/{n}')
        if '-v' in argv:
            for k, e in recs_b.items():
                vals = [(e.get(f) or {}).get('value') for f in FIELDS]
                print(k, '=>', ' / '.join(str(v) for v in vals))
        return 0
    if cmd == 'check':
        stale = write_expanded(result, check=True)
        for p in stale:
            print('stale:', p.relative_to(REPO))
        return 1 if stale else 0
    rows = joined(recs, result)
    if cmd == 'join':
        out = Path(argv[2]) if len(argv) > 2 else OUT / 'joined.json'
        out.write_text(json.dumps(rows, ensure_ascii=False, indent=0, default=str))
        print('wrote', out)
        return 0
    if cmd == 'analyze':
        print(analyze(rows))
        return 0
    if cmd == 'table':
        # group form factors for lib/core/estimated_bc.dart (later)
        for platform, typ in (('firearm', None), ('pcp', 'slug'), ('pcp', 'pellet')):
            print(f'\n### {platform} {typ or ""}\n')
            print('| Level | Group | Records | Makers | i (G1) | IQR |\n|---|---|---|---|---|---|')
            for d in group_table(rows, platform, typ):
                print(f"| {d['level']} | {' × '.join(d['group'])} | {d['n']} | {d['makers']} | "
                      f"{d['i']:.3f} | {d['q1']:.3f}–{d['q3']:.3f} |")
        return 0
    if cmd == 'candidates':
        c = fill_candidates(rows)
        out = OUT / 'estimated_bc_candidates.json'
        out.write_text(json.dumps(dict(
            note='Kayıtlar üretici BC vermiyor; BC tip/uç şekli grubunun biçim katsayısından '
                 'TAHMİNİ (G1). lib/ dosyalarına yazılmadı.',
            generated_by='tools/data_gen/bullet_shape.py candidates',
            records=c), ensure_ascii=False, indent=1) + '\n')
        print(len(c), 'candidates ->', out.relative_to(REPO))
        return 0
    raise SystemExit(__doc__)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
