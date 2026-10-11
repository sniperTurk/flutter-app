#!/usr/bin/env python3
"""Generates lib/data/cartridges.dart, rifle_library.dart, factory_ammo_library.dart
from the data branches (data/rifles, data/mke, data/ammo, data/ammo-military).
Manufacturer-sourced data only; nothing is guessed. Records whose caliber cannot
be mapped to a known cartridge (with a known bullet diameter) are skipped and
listed on stderr.
"""
import glob, json, math, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = Path('/home/claude/flutter-app')

# (name, bullet diameter mm). First POPULAR are shown first, rest A-Z.
POPULAR = ['.308 Win', '7.62x51 NATO', '6.5 Creedmoor', '.223 Rem', '5.56x45 NATO',
           '.30-06 Springfield', '7.62x39', '.300 Win Mag', '.338 Lapua Mag', '.22 LR']
CARTRIDGES = {
    '.17 HMR': 4.37, '.17 Hornet': 4.37, '.204 Ruger': 5.18, '.22 ARC': 5.7,
    '.22 Creedmoor': 5.7, '.22 Hornet': 5.69, '.22 LR': 5.69, '.22 WMR': 5.69,
    '.22-250 Rem': 5.7, '.222 Rem': 5.7, '.223 Rem': 5.7, '.243 Win': 6.17,
    '.25 Creedmoor': 6.53, '.25-06 Rem': 6.53, '.257 Weatherby Mag': 6.53,
    '.260 Rem': 6.71, '.264 Win Mag': 6.71, '.270 Weatherby Mag': 7.04,
    '.270 Win': 7.04, '.270 WSM': 7.04, '.280 Ackley Improved': 7.21, '.280 Rem': 7.21,
    '.28 Nosler': 7.21, '.30 R Blaser': 7.82, '.30-06 Springfield': 7.82,
    '.30-30 Win': 7.82, '.300 Blackout': 7.82, '.300 Blaser Mag': 7.82,
    '.300 Norma Mag': 7.82, '.300 PRC': 7.82, '.300 RUM': 7.82, '.300 Win Mag': 7.82,
    '.300 WSM': 7.82, '.303 British': 7.92, '.308 Win': 7.82, '.338 Blaser Mag': 8.59,
    '.338 Lapua Mag': 8.59, '.338 Norma Mag': 8.59, '.338 Win Mag': 8.59,
    '.350 Legend': 9.02, '.400 Legend': 10.16, '.358 Win': 9.09, '.375 Blaser Mag': 9.53, '.375 CheyTac': 9.53,
    '.375 H&H Mag': 9.53, '.408 CheyTac': 10.36, '.416 Rem Mag': 10.57,
    '.416 Rigby': 10.57, '.45-70 Govt': 11.63, '.450 Bushmaster': 11.48,
    '.458 Lott': 11.63, '.458 Win Mag': 11.63, '.50 BMG': 12.95, '.500 Jeffery': 12.95,
    '12.7x99 NATO': 12.95, '5.56x45 NATO': 5.7, '5.6x50 R Mag': 5.7, '5.6x52 R': 5.77,
    '6mm ARC': 6.17, '6mm Creedmoor': 6.17, '6mm GT': 6.17, '6XC': 6.17,
    '6.5 Creedmoor': 6.71, '6.5 PRC': 6.71, '6.5x47 Lapua': 6.71, '6.5x55 Swedish': 6.71,
    '6.5x57 R': 6.71, '6.5x65 R RWS': 6.71, '6.5-284 Norma': 6.71, '6.8 Western': 7.04,
    '7mm Backcountry': 7.21, '7mm Blaser Mag': 7.21, '7mm PRC': 7.21, '7mm Rem Mag': 7.21,
    '7mm-08 Rem': 7.21, '7x57 Mauser': 7.24, '7x57 R': 7.24, '7x64': 7.21, '7x65 R': 7.21,
    '7.5x55 Swiss': 7.82, '7.62x39': 7.92, '7.62x51 NATO': 7.82, '7.62x54R': 7.92,
    '8x57 IRS': 8.22, '8x57 JS': 8.22, '8x68 S': 8.22, '8.5x55 Blaser': 8.59,
    '8.6 Blackout': 8.59, '9.3x62': 9.3, '9.3x66 Sako': 9.3, '9.3x74 R': 9.3,
}
ALIASES = {
    '.30-06': '.30-06 Springfield', '.30-06 spr': '.30-06 Springfield',
    '.30-06 sprg': '.30-06 Springfield', '.300 aac blackout': '.300 Blackout',
    '.375 h&h': '.375 H&H Mag', '.22 creedmoor': '.22 Creedmoor',
    '.25 creedmoor': '.25 Creedmoor', '5.56x45': '5.56x45 NATO', '5.56 nato': '5.56x45 NATO',
    '6.5x55 se': '6.5x55 Swedish', '7 prc': '7mm PRC', '7.5x55 suisse': '7.5x55 Swiss',
    '7.62x51': '7.62x51 NATO', '8x57 is': '8x57 JS', '.28 nosler': '.28 Nosler',
    '.280 ackley improved': '.280 Ackley Improved', '.204 ruger': '.204 Ruger',
    '8.59x70 (.338 lapua magnum)': '.338 Lapua Mag', '.338 lapua magnum (8.6x70)': '.338 Lapua Mag',
    '12.7x99 nato (.50 bmg)': '12.7x99 NATO', '.50 bmg (12.7x99 nato)': '12.7x99 NATO',
    '10.36x77 (.408 cheytac)': '.408 CheyTac', '.308 win (7.62x51)': '.308 Win',
}

CARTRIDGES.update({
    '8x57 JRS': 8.22, '6.5-300 Weatherby Mag': 6.71, '6.5 Weatherby RPM': 6.71,
    '.300 Weatherby Mag': 7.82, '.240 Weatherby Mag': 6.17, '.338 Weatherby RPM': 8.59,
    '.25 Weatherby RPM': 6.53, '6.5x57': 6.71, '7mm Weatherby Mag': 7.21,
    '6.8 Rem SPC': 7.04, '.416 Barrett': 10.57, '.338-378 Weatherby Mag': 8.59,
    '.30-378 Weatherby Mag': 7.82, '8x64 S': 8.22, '6.5x68': 6.71, '6.5 Grendel': 6.71,
    '.340 Weatherby Mag': 8.59, '.30 Carbine': 7.82, '9.3x72 R': 9.3, '6.5x52 R': 6.71,
    '5.6x57': 5.7, '.375 Swiss P': 9.53, '.338 Federal': 8.59, '.224 Valkyrie': 5.7,
})
for _wby in ('.257', '.270', '.300', '.240', '7mm', '.340', '.338-378', '.30-378', '6.5-300'):
    ALIASES[_wby.lower() + ' wby mag'] = (_wby + ' Weatherby Mag')
for _rpm in ('6.5', '.338', '.25'):
    ALIASES[_rpm.lower() + ' wby rpm'] = _rpm + ' Weatherby RPM'
ALIASES.update({'7x57': '7x57 Mauser', '.45-70 government': '.45-70 Govt', '.300 blk': '.300 Blackout',
                '6.5x65 r': '6.5x65 R RWS', '5.6x50 mag': '5.6x50 R Mag'})
PCP = [(4.5, '4.50 mm (.177)'), (5.0, '5.00 mm (.20)'), (5.5, '5.50 mm (.22)'),
       (6.35, '6.35 mm (.25)'), (7.62, '7.62 mm (.30)'), (9.0, '9.00 mm (.357)'),
       (11.43, '11.43 mm (.45)'), (12.7, '12.70 mm (.50)')]
PCP_ALIASES = {'.177': 4.5, '.20': 5.0, '.22': 5.5, '.25': 6.35, '.30': 7.62, '.35': 9.0,
               '.357': 9.0, '.45': 11.43, '.50': 12.7}

skipped = []


def norm_key(s):
    s = s.strip().replace('×', 'x').replace('  ', ' ')
    s = re.sub(r'\s*mm$', '', s)
    k = s.lower()
    if not k.startswith('.') and re.match(r'^\d{2,3}[ -]', k) and not re.match(r'^\d{1,2}(\.\d+)?x', k):
        k = '.' + k  # "308 Win" -> ".308 win", "22 Creedmoor" -> ".22 creedmoor"
    return k


LOWER = {n.lower(): n for n in CARTRIDGES}


def cartridge(raw):
    k = norm_key(raw)
    if k in ALIASES:
        return ALIASES[k]
    return LOWER.get(k)


def pcp_mm(raw, dia):
    k = raw.strip().lower().replace(' mm', '')
    if k in PCP_ALIASES:
        return PCP_ALIASES[k]
    try:
        v = float(k)
    except ValueError:
        v = dia
    for mm, _ in PCP:
        if v is not None and abs(mm - v) < 0.06:
            return mm
    return None


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$') + "'"


def num(v):
    if v is None:
        return 'null'
    v = float(v)
    return str(int(v)) + '.0' if v == int(v) else repr(round(v, 4))


# ------------------------------------------------------------------ rifles
def base_model(model, raw_cal, brand=''):
    m = model
    barrel = None
    mb = re.search(r'\(?\b(\d{1,2}(?:\.\d+)?)\s?(?:in|")\)?(?=\s|$)', m)
    if mb:
        barrel = float(mb.group(1))
        m = m[:mb.start()] + m[mb.end():]
    m = re.sub(r'\b\d{3}\s?mm\b', ' ', m)          # TRG "660 mm", Blackwolf "430mm"
    m = re.sub(r'\(\d{4,6}\)', ' ', m)              # Ruger item numbers "(46930)"
    m = re.sub(r'\s1:\d+(?:\.\d+)?(?=\s|$)', ' ', m)  # Sako "1:12"
    for c in sorted({raw_cal, raw_cal.lstrip('.'), raw_cal.replace('×', 'x')}, key=len, reverse=True):
        if c and c in m:
            m = m.replace(c, ' ')
            break
    m = re.sub(r'\s+', ' ', m).strip(' -/,')
    if brand and m.lower().startswith(brand.lower() + ' '):
        m = m[len(brand) + 1:]
    return m, barrel


rifles = []
for f in sorted(glob.glob(str(HERE / 'rifles/data/rifles/*.json'))):
    for r in json.load(open(f)):
        raw = str(r['caliber'] or '')
        model, barrel_in = base_model(r['model'], raw, r['brand'].strip())
        if not model:
            model = r['model']
        if r['platform'] == 'firearm':
            c = cartridge(raw)
            if c is None:
                skipped.append(('rifle', r['brand'], r['model'], raw))
                continue
            dia = CARTRIDGES[c]
        else:
            dia = pcp_mm(raw, r.get('bullet_diameter_mm'))
            if dia is None:
                skipped.append(('rifle', r['brand'], r['model'], raw))
                continue
            c = dict(PCP)[dia]
        bl = r.get('barrel_length_mm')
        rifles.append(dict(brand=r['brand'].strip(), model=model, platform=r['platform'],
                           cartridge=c, dia=dia, twist=r.get('twist_rate_in'),
                           dir=r.get('twist_direction'), barrel=bl, src=r['source_url']))
for r in json.load(open(HERE / 'mke/data/mke/rifles.json')):
    c = cartridge(r['caliber'])
    if c is None:
        skipped.append(('rifle', 'MKE', r['model'], r['caliber']))
        continue
    rifles.append(dict(brand='MKE', model=base_model(r['model'], '', 'MKE')[0], platform='firearm', cartridge=c,
                       dia=CARTRIDGES[c], twist=r.get('twist_rate_in'), dir=r.get('twist_direction'),
                       barrel=r.get('barrel_length_mm'), src=r['source_url']))
# de-duplicate identical variants
seen, uniq = set(), []
for r in rifles:
    k = (r['brand'].lower(), r['model'].lower(), r['cartridge'], r['barrel'], r['twist'])
    if k in seen:
        continue
    seen.add(k)
    uniq.append(r)
rifles = sorted(uniq, key=lambda r: (r['platform'], r['brand'].lower(), r['model'].lower(), r['cartridge'], r['barrel'] or 0))

# ------------------------------------------------------------------ factory ammo
sys.path.insert(0, str(REPO / 'tools'))
import offline_solver_crosscheck as osc  # noqa: E402

G1 = osc.load_tables()['g1']


def muzzle_from(v_at, dist_m, bc):
    """Back-integrates G1 drag from v(dist) to the muzzle (ICAO standard air)."""
    rho, c = 1.225, 340.294
    v, x, dx = v_at, dist_m, 0.01
    while x > 1e-9:
        a = 0.5 * rho * osc.cd_at(G1, v / c) * (math.pi / 4) * v * v / (bc * 703.0695796391593)
        v += a / v * dx  # dv/dx = -a/v, integrating backwards
        x -= dx
    return v


lib_text = (REPO / 'lib/data/bullet_library.dart').read_text()
LIB = []
_S = r"'((?:[^'\\]|\\.)*)'"
_N = r"([\d.]+|null)"
_RX = re.compile(r"LibraryBullet\(" + _S + ", " + _S + ", " + _S + ", " + _N + ", " + _N + ", " + _N + ", " + _N + ", " + _N
                 + r", BallisticModel\.(\w+), " + _N + r", \[.*?\], " + _N + r", AmmunitionType\.(\w+), WeaponPlatform\.(\w+), ")
for m in _RX.finditer(lib_text):
    brand, name, item, cal, dia, grain, g1, g7, model, bc, length, typ, plat = m.groups()
    LIB.append(dict(brand=brand, name=name, dia=float(dia if dia != 'null' else cal), grain=float(grain),
                    g1=None if g1 == 'null' else g1, g7=None if g7 == 'null' else g7, plat=plat))
print('library bullets parsed', len(LIB))


def simp(s):
    return re.sub(r'[^a-z0-9]', '', s.lower())


def lib_bc(brand, bullet, grain, dia):
    if not bullet:
        return None
    hits = [b for b in LIB if b['brand'] and simp(b['brand']) == simp(brand) and b['plat'] and 'firearm' in b['plat']
            and abs(b['grain'] - grain) < 0.6 and abs(b['dia'] - dia) < 0.06 and simp(bullet) in simp(b['name'])]
    if len(hits) != 1:
        return None
    b = hits[0]
    if b['g7'] not in (None, 'null'):
        return float(b['g7']), 'g7'
    if b['g1'] not in (None, 'null'):
        return float(b['g1']), 'g1'
    return None


ammo = []
for f in sorted(glob.glob(str(HERE / 'ammo/data/ammo/*.json'))):
    for r in json.load(open(f)):
        # MKE velocities are V23.7 m; data/mke is read below and corrected.
        if r['brand'] == 'MKE':
            continue
        c = cartridge(r['cartridge'])
        if c is None or not r.get('muzzle_velocity_fps'):
            skipped.append(('ammo', r['brand'], r['product'], r['cartridge']))
            continue
        dia = CARTRIDGES[c]
        bc, model, bcsrc = None, None, None
        if r.get('g7_bc'):
            bc, model, bcsrc = r['g7_bc'], 'g7', 'fişek'
        elif r.get('g1_bc'):
            bc, model, bcsrc = r['g1_bc'], 'g1', 'fişek'
        else:
            hit = lib_bc(r['brand'], r.get('bullet'), r['weight_gr'], dia)
            if hit:
                bc, model = hit
                bcsrc = 'mermi'
        name = r['product']
        for token in sorted({r['cartridge'], c}, key=len, reverse=True):
            name = name.replace(token, ' ')
        name = re.sub(r'\s+', ' ', name).strip(' -')
        ammo.append(dict(brand=r['brand'], name=name, cartridge=c, dia=dia, grain=r['weight_gr'],
                         bc=bc, model=model, bcsrc=bcsrc, mv=r['muzzle_velocity_fps'],
                         barrel=r.get('test_barrel_in'), item=r.get('item_number'), src=r['source_url'],
                         note=None))
for r in json.load(open(HERE / 'mke/data/mke/ammo.json')):
    c = cartridge(r['cartridge'])
    notes = r.get('notes') or ''
    measured_far = '23.7 m' in notes
    if c is None:
        skipped.append(('ammo', 'MKE', r['product'], r['cartridge']))
        continue
    if measured_far and not r.get('g1_bc'):
        skipped.append(('ammo-no-bc-for-23.7m', 'MKE', r['product'], r['cartridge']))
        continue
    mv_fps = r['muzzle_velocity_fps']
    note = None
    if measured_far:
        mps = muzzle_from(mv_fps / 3.28084, 23.7, r['g1_bc'])
        note = f"MKE hızı 23,7 m'de ölçülmüş ({mv_fps:.0f} fps); namlu ağzı hızı G1 BC ile hesaplandı."
        mv_fps = round(mps * 3.28084)
    ammo.append(dict(brand='MKE', name=re.sub(r'\s+', ' ', r['product'].replace(r['cartridge'], ' ').replace('Fişek', 'Fişek')).strip(),
                     cartridge=c, dia=CARTRIDGES[c], grain=r['weight_gr'], bc=r.get('g1_bc'),
                     model='g1' if r.get('g1_bc') else None, bcsrc='fişek' if r.get('g1_bc') else None,
                     mv=mv_fps, barrel=None, item=None, src=r['source_url'], note=note))
seen, uniq = set(), []
for a in ammo:
    k = (a['brand'].lower(), a['name'].lower(), a['cartridge'], a['grain'])
    if k in seen:
        continue
    seen.add(k)
    uniq.append(a)
ammo = sorted(uniq, key=lambda a: (a['cartridge'], a['brand'].lower(), a['name'].lower(), a['grain']))

# ------------------------------------------------------------------ write
hdr = '// GENERATED by scratchpad gen.py from the data/* branches. Do not edit.\n// dart format off\n'
order = POPULAR + sorted([n for n in CARTRIDGES if n not in POPULAR],
                         key=lambda n: re.sub(r'^\.', '', n).lower())
out = [hdr, "/// Cartridge names and the bullet diameter the solver uses (mm).\n",
       "/// The first [popularCount] are the common ones, the rest A-Z.\n",
       "abstract final class Cartridges {\n  static const popularCount = %d;\n\n" % len(POPULAR),
       "  static const firearm = <(String, double)>[\n"]
for n in order:
    out.append(f"    ({dart_str(n)}, {num(CARTRIDGES[n])}),\n")
out.append("  ];\n\n  /// PCP calibers (mm, label).\n  static const pcp = <(double, String)>[\n")
for mm, label in PCP:
    out.append(f"    ({num(mm)}, {dart_str(label)}),\n")
out.append("  ];\n\n  /// Bullet diameter of [name]; null when unknown.\n"
           "  static double? diameterOf(String name) {\n"
           "    for (final (n, d) in firearm) {\n      if (n == name) return d;\n    }\n    return null;\n  }\n}\n")
(REPO / 'lib/data/cartridges.dart').write_text(''.join(out))

out = [hdr, "import '../models/domain.dart';\n\n",
       "/// A manufacturer-sourced rifle variant for the Profil Marka / Model /\n",
       "/// Kalibre lists (owner, 2026-10-11). [cartridge] is a [Cartridges] name\n",
       "/// (firearm) or the PCP list label.\n",
       "class LibraryRifle {\n  final String brand, model, cartridge, sourceUrl;\n  final WeaponPlatform platform;\n",
       "  final double diameterMm;\n  final double? twistRateIn, barrelLengthMm;\n  final TwistDirection? twistDirection;\n",
       "  const LibraryRifle(this.brand, this.model, this.platform, this.cartridge, this.diameterMm,\n"
       "      this.twistRateIn, this.twistDirection, this.barrelLengthMm, this.sourceUrl);\n}\n\n",
       "abstract final class RifleLibrary {\n  static const all = <LibraryRifle>[\n"]
for r in rifles:
    d = {'right': 'TwistDirection.right', 'left': 'TwistDirection.left'}.get(r['dir'], 'null')
    out.append(f"    LibraryRifle({dart_str(r['brand'])}, {dart_str(r['model'])}, WeaponPlatform.{r['platform']}, "
               f"{dart_str(r['cartridge'])}, {num(r['dia'])}, {num(r['twist'])}, {d}, {num(r['barrel'])}, {dart_str(r['src'])}),\n")
out.append("  ];\n}\n")
(REPO / 'lib/data/rifle_library.dart').write_text(''.join(out))

out = [hdr, "import '../models/domain.dart';\n\n",
       "/// A manufacturer-sourced factory cartridge (owner, 2026-10-11: \"Fabrika\n",
       "/// fişeği\" Marka / Model). [muzzleVelocityFps] is the maker's figure from\n",
       "/// its test barrel ([testBarrelIn], null when not published). [bc] is null\n",
       "/// when neither the cartridge nor the bullet maker publishes one.\n",
       "/// [bcFromBullet]: the BC is the bullet maker's figure for the same bullet.\n",
       "class FactoryAmmo {\n  final String brand, name, cartridge, sourceUrl;\n  final double diameterMm, grain, muzzleVelocityFps;\n",
       "  final double? bc, testBarrelIn;\n  final BallisticModel? model;\n  final bool bcFromBullet;\n  final String? note;\n",
       "  const FactoryAmmo(this.brand, this.name, this.cartridge, this.diameterMm, this.grain, this.bc,\n"
       "      this.model, this.muzzleVelocityFps, this.testBarrelIn, this.sourceUrl,\n"
       "      {this.bcFromBullet = false, this.note});\n}\n\n",
       "abstract final class FactoryAmmoLibrary {\n  static const all = <FactoryAmmo>[\n"]
for a in ammo:
    model = f"BallisticModel.{a['model']}" if a['model'] else 'null'
    extra = ''
    if a['bcsrc'] == 'mermi':
        extra += ', bcFromBullet: true'
    if a['note']:
        extra += f", note: {dart_str(a['note'])}"
    out.append(f"    FactoryAmmo({dart_str(a['brand'])}, {dart_str(a['name'])}, {dart_str(a['cartridge'])}, {num(a['dia'])}, "
               f"{num(a['grain'])}, {num(a['bc'])}, {model}, {num(a['mv'])}, {num(a['barrel'])}, {dart_str(a['src'])}{extra}),\n")
out.append("  ];\n}\n")
(REPO / 'lib/data/factory_ammo_library.dart').write_text(''.join(out))

print('rifles', len(rifles), 'firearm', sum(r['platform'] == 'firearm' for r in rifles),
      'pcp', sum(r['platform'] == 'pcp' for r in rifles))
print('ammo', len(ammo), 'with bc', sum(a['bc'] is not None for a in ammo),
      'bc from bullet', sum(a['bcsrc'] == 'mermi' for a in ammo))
print('skipped', len(skipped))
for s in skipped:
    print('  ', s, file=sys.stderr)
