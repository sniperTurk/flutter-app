#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15c, area PROFIL (main e7b29bf).

Stdlib-only reference for test/audit_2026_10_15c/profil_audit_test.dart.
Nothing here imports app code; the Dart data files are parsed as text and
the editor's rules are re-stated by hand from the source and checked.

PRs in scope (merged after 4c51b77):

* #327 (28bbe43) Tür keeps the chosen Kalibre (PRF-7, PRF-8).
* #329 (9104632) Profiller list on top, one summary line per card.
* #344 (a25a639) PRF-1/3/4/5, #346 (8dd0966) unit suffixes, #322
  (f8b36b5) default name "Profil", #350 / #351 info texts: screened for
  number changes.

Independent references (no other ballistic app):

* Unit definitions: 1 ft = 0.3048 m, 1 yd = 0.9144 m, 1 in = 25.4 mm,
  1 gr = 1/7000 lb, 1 MOA = pi/10800 rad.
* Sectional density SD = (grain / 7000) / d_in^2 (lb/in^2).
* The catalogs (lib/data/cartridges.dart, rifle_library.dart,
  factory_ammo_library.dart, bullet_library.dart) are parsed here to
  enumerate EVERY caliber the user can reach.

Findings:

* PRF-11 (medium): the chosen cartridge name is not saved (the rifle record
  keeps only ``caliberMm``); Profili Düzenle infers it again by diameter
  (and twist for a listed rifle). A listed rifle offering two cartridges of
  one diameter and twist comes back as the other cartridge (Anschütz 1782
  Classic .300 Win Mag -> .30-06 Springfield): the Fabrika fişeği Model box
  shows "Seçiniz" and the MUH-1 guard (BC modeli change empties a G1-only
  maker BC) no longer finds the saved round, so G7 keeps the G1 number.
  A typed rifle comes back as the first cartridge of its diameter
  (.300 Win Mag -> .308 Win; display only).
* PRF-12 (low): a custom drag curve stores the sectional density in
  ``bc`` with ``bcModel: g1``; the profile card summary (and the active
  Mühimmat summary) shows it as "BC 0,2637... G1". Display only.

Run: python3 tools/denetim_2026_10_15c_profil.py
"""
from __future__ import annotations

import math
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dart_library_source import library_text  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = 'lib/features/profiles/profiles_screen.dart'

M_PER_FT = 0.3048
M_PER_YD = 0.9144
MM_PER_IN = 25.4
GRAIN_PER_LB = 7000.0
RAD_PER_MOA = math.pi / 10800
RAD_PER_MRAD = 0.001

# The editor compares diameters with these tolerances (stated in the source,
# re-checked in the tests below).
SAME_DIAMETER = 0.005  # _cartridgeFor, _caliberItem, _variantFor
SAME_BULLET = 0.02  # _factoryHere / _libraryHere / _applyBullet

_S = r"'((?:[^'\\]|\\.)*)'"
_N = r"(-?[\d.]+|null)"


def _read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def _num(v: str) -> float | None:
    return None if v == 'null' else float(v)


# ---- Catalog parsing --------------------------------------------------------

def firearm_cartridges() -> list[tuple[str, float]]:
    """Cartridges.firearm: (name, bullet diameter mm), list order."""
    src = _read('lib/data/cartridges.dart')
    start = src.index('firearm = <')
    block = src[start:src.index('];', start)]
    return [(m.group(1), float(m.group(2)))
            for m in re.finditer(_S + r", ([\d.]+)\)", block)]


def pcp_calibers() -> list[tuple[float, str]]:
    src = _read('lib/data/cartridges.dart')
    start = src.index('pcp = <')
    block = src[start:src.index('];', start)]
    return [(float(m.group(1)), m.group(2))
            for m in re.finditer(r"\(([\d.]+), " + _S + r"\)", block)]


def rifle_library() -> list[dict]:
    out = []
    pat = re.compile(
        r"LibraryRifle\(" + _S + ", " + _S + r", WeaponPlatform\.(\w+), "
        + _S + ", " + _N + ", " + _N)
    for line in _read('lib/data/rifle_library.dart').splitlines():
        m = pat.search(line)
        if m:
            out.append({'brand': m.group(1), 'model': m.group(2),
                        'platform': m.group(3), 'cartridge': m.group(4),
                        'diameter': float(m.group(5)),
                        'twist': _num(m.group(6))})
    return out


def factory_ammo() -> list[dict]:
    out = []
    pat = re.compile(r"FactoryAmmo\(" + _S + ", " + _S + ", " + _S + ", "
                     + _N + ", " + _N + ", " + _N + r", (BallisticModel\.\w+"
                     r"|null)")
    for line in _read('lib/data/factory_ammo_library.dart').splitlines():
        m = pat.search(line)
        if m:
            g7 = re.search(r"bcG7: ([\d.]+)", line)
            out.append({'brand': m.group(1), 'name': m.group(2),
                        'cartridge': m.group(3),
                        'diameter': float(m.group(4)),
                        'grain': float(m.group(5)), 'bc': _num(m.group(6)),
                        'model': None if m.group(7) == 'null'
                        else m.group(7).split('.')[1],
                        'bcG7': float(g7.group(1)) if g7 else None})
    return out


def bullet_library() -> list[dict]:
    out = []
    pat = re.compile(r"LibraryBullet\(" + _S + ", " + _S + ", " + _S + ", "
                     + _N + ", " + _N + ", " + _N)
    for line in _read('lib/data/bullet_library.dart').splitlines():
        m = pat.search(line)
        if m:
            out.append({'brand': m.group(1), 'name': m.group(2),
                        'caliber': float(m.group(4)),
                        'diameter': float(m.group(5)),
                        'grain': float(m.group(6)),
                        'platform': re.findall(r"WeaponPlatform\.(\w+)",
                                               line)[-1]})
    return out


def cartridge_name_map() -> list[tuple[str, str]]:
    """RiflePickerScreen.cartridgeName: (lower-case model key, name)."""
    src = _read('lib/features/profiles/rifle_picker_screen.dart')
    start = src.index('static String? cartridgeName')
    block = src[start:src.index('];', start)]
    return re.findall(r"\(" + _S + ", " + _S + r"\)", block)


# ---- The editor's rules, restated -------------------------------------------

def cartridge_for(mm: float, firearm=None) -> str | None:
    """_cartridgeFor: the FIRST list cartridge of this diameter."""
    for name, d in firearm or firearm_cartridges():
        if abs(d - mm) < SAME_DIAMETER:
            return name
    return None


def cartridge_from_model(model: str, mapping=None) -> str | None:
    m = model.lower()
    for k, v in mapping or cartridge_name_map():
        if k in m:
            return v
    return None


def reload_variant(saved: dict, rifles: list[dict], mapping) -> dict:
    """initState -> _variantFor for a saved listed firearm rifle.

    The record keeps brand, model, caliberMm and twist only; _cartridge
    comes from cartridgeName(model) (usually null), then the first variant
    of the same diameter whose twist is unknown or equal wins.
    """
    c = cartridge_from_model(saved['model'], mapping)
    same = [r for r in rifles
            if r['platform'] == 'firearm' and r['brand'] == saved['brand']
            and r['model'] == saved['model']]
    d, t = saved['diameter'], saved['twist']
    for r in same:
        if (abs(r['diameter'] - d) < SAME_DIAMETER
                and (c is None or r['cartridge'] == c)
                and (r['twist'] is None or r['twist'] == t)):
            return r
    return next(r for r in same if abs(r['diameter'] - d) < SAME_DIAMETER)


def prf11_typed_shadowed() -> list[str]:
    """Typed rifle: cartridges that come back as another name on reload."""
    fa = firearm_cartridges()
    return [n for n, d in fa if cartridge_for(d, fa) != n]


def prf11_listed_affected() -> list[tuple[str, str, str, str]]:
    """(brand, model, saved cartridge, cartridge shown on reload)."""
    rifles = rifle_library()
    mapping = cartridge_name_map()
    seen, out = set(), []
    for r in rifles:
        if r['platform'] != 'firearm':
            continue
        key = (r['brand'], r['model'], r['cartridge'])
        if key in seen:
            continue
        seen.add(key)
        back = reload_variant(r, rifles, mapping)
        if back['cartridge'] != r['cartridge']:
            out.append(key + (back['cartridge'],))
    return out


def prf11_muh1_bypass(affected=None) -> list[tuple[str, str, str, str]]:
    """Affected listed rifles whose saved cartridge has factory rounds: the
    saved round is missing from the reloaded Fabrika list (MUH-1 guard)."""
    fac = {a['cartridge'] for a in factory_ammo()}
    return [a for a in (affected or prf11_listed_affected()) if a[2] in fac]


def muh1_box_after_g7(round_: dict, listed: bool) -> str | None:
    """_factoryBcForModel after BC modeli -> G7 on a listed factory round.

    listed=True: the round is in _factoryHere (correct cartridge): the
    maker's G7 or an empty box. listed=False (PRF-11): the loop finds
    nothing and the box keeps the G1 number.
    """
    if not listed:
        return trim_num(round_['bc'])
    if round_['model'] == 'g7':
        return trim_num(round_['bc'])
    return '' if round_['bcG7'] is None else trim_num(round_['bcG7'])


# ---- Summary line (#329), from definitions ----------------------------------

def trim_num(v: float) -> str:
    """_trimNum: whole -> no decimals, else repr with a decimal comma."""
    return f'{v:.0f}' if v % 1 == 0 else repr(v).replace('.', ',')


def summary_line(caliber_mm: float | None, zero_m: float, unit: str,
                 mps: float, bc: float | None, model: str | None) -> str:
    parts = []
    if caliber_mm:
        parts.append(f'{caliber_mm:.2f}'.replace('.', ',') + ' mm')
    if unit == 'yard':
        parts.append('sıfır ' + f'{zero_m / M_PER_YD:.1f}'.replace('.', ',')
                     + ' yd')
    else:
        parts.append(f'sıfır {zero_m:.0f} m')
    parts.append(f'{mps / M_PER_FT:.0f} fps')
    if bc:
        parts.append(' '.join(p for p in ('BC', trim_num(bc),
                                          (model or '').upper()) if p))
    return ', '.join(parts)


def sectional_density(grain: float, diameter_mm: float) -> float:
    d_in = diameter_mm / MM_PER_IN
    return grain / GRAIN_PER_LB / (d_in * d_in)


# ---- Other screened numbers ---------------------------------------------------

def quarter_moa_half_click_mrad() -> float:
    """#344: a list MRAD scope on a MOA profile keeps its own click; the
    travel box rounds to whole 1/4 MOA clicks: at most half a click."""
    return 0.125 * RAD_PER_MOA / RAD_PER_MRAD


INFO_BC_EXAMPLES = {
    # (ProfileFieldInfo constant, example, typical range the text gives)
    'bc': (0.032, (0.02, 0.04)),  # pellet 0,02–0,04
    'bcFirearm': (0.324, (0.25, 0.60)),  # G1 0,25–0,60
    'bandBc': (0.310, (0.25, 0.60)),  # firearm-only band rows
}


def info_example_present(name: str, example: str) -> bool:
    src = _read('lib/features/profiles/profile_field_info.dart')
    start = src.index(f'static const {name} =')
    # The constant ends at the closing quote + ';' (the text has ';' too).
    end = src.index("';\n", start)
    return example in src[start:end]


# ---- Source checks ----------------------------------------------------------

def editor_source() -> str:
    return library_text(LIBRARY)


def tur_handler(src: str | None = None) -> str:
    src = src or editor_source()
    start = src.index("key: const Key('profile-platform')")
    return src[start:src.index("key: const Key('rifle-origin')", start)]


def tur_clears_only_when_changed(src: str | None = None) -> bool:
    """#327: every Kalibre reset of the Tür handler is inside if (changed)."""
    h = tur_handler(src)
    i = h.index('if (changed) {')
    depth, j = 0, i + len('if (changed) ')
    while True:
        ch = h[j]
        depth += ch == '{'
        depth -= ch == '}'
        j += 1
        if depth == 0:
            break
    inside, outside = h[i:j], h[:i] + h[j:]
    resets = ('_cartridge = null', "rifleCaliber.text = ''",
              '_caliberByDiameter = false', '_rifleVariant = null')
    return (all(r in inside for r in resets)
            and not any(r in outside for r in resets))


def cartridge_saved(src: str | None = None) -> bool:
    """PRF-11 root: does the rifle record keep the cartridge name?"""
    src = src or editor_source()
    start = src.index('Map<String, dynamic> _rifleEntry()')
    body = src[start:src.index('Map<String, dynamic> _ammoEntry()', start)]
    return re.search(r"'cartridge'\s*:", body) is not None


def summary_shows_curve_sd(src: str | None = None) -> bool:
    """PRF-12: profileListSummary prints ammo.ballisticCoefficient without
    looking at dragCurve."""
    src = src or editor_source()
    start = src.index('String profileListSummary(RifleProfile p)')
    body = src[start:src.index('\n}\n', start)]
    return 'ballisticCoefficient' in body and 'dragCurve' not in body


def main() -> int:
    fa = firearm_cartridges()
    print(f'firearm cartridges: {len(fa)}, PCP calibers: {len(pcp_calibers())}')
    print('Tür resets Kalibre only when changed:', tur_clears_only_when_changed())
    shadow = prf11_typed_shadowed()
    print(f'PRF-11 typed rifle: {len(shadow)} of {len(fa)} cartridges come '
          'back as another name')
    aff = prf11_listed_affected()
    print(f'PRF-11 listed rifle: {len(aff)} (brand, model, cartridge) come '
          f'back as another cartridge; {len(prf11_muh1_bypass(aff))} with '
          'factory rounds (MUH-1 guard bypassed)')
    sd = sectional_density(175, 7.82)
    print(f'PRF-12: 175 gr 7.82 mm curve -> "BC {trim_num(sd)} G1" on the card')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
