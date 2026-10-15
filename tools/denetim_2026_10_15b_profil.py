#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15b, area PROFIL SPLIT (#318) + TUR ZORUNLU
(#323).

Stdlib-only reference for test/audit_2026_10_15b/profil_split_audit_test.dart.

Hand calculations from definitions only (no app constants, no other
ballistic app):

* 1 ft = 0.3048 m, 1 yd = 0.9144 m, 1 in = 25.4 mm (exact, 1959 agreement).
* 1 MOA = pi / (180 * 60) rad; 1 SMOA = 1 in at 100 yd = 0.0254 / 91.44 rad;
  1 mrad = 0.001 rad.
* The editor's display rounding: muzzle velocity in fps with one decimal,
  BC band thresholds in whole fps, the zero to 0.1 of its unit, turret
  travel in whole clicks. The worst-case error of each is half a display
  step converted to SI: these are the tolerances of the Dart round trips.
* PRF-7 size: flat-fire vacuum trajectory y(x) = x tan(theta) - h -
  g x^2 / (2 v^2) (h = sight height), zeroed where y(Z) = 0. A wrong zero
  Z' instead of Z changes the bore angle by theta(Z') - theta(Z); the
  impact moves by that angle times the range. Drag only adds drop, so this
  is an order-of-magnitude estimate, not the app's number.

Source scans (the editor is ONE Dart library, read whole):

* every MenzilInput / MenzilSelect of the profile editor carries ``info:``
  unless it is a plain identity box (Marka, Model, Dürbün markası, Profil
  adı), CLAUDE.md "explain every entered value";
* every TextEditingController of the editor is read by the save path
  (a controller that is never read on save would be data loss);
* "Tür" blocks only a NEW profile: ``_platformSet`` starts true and is set
  false only inside ``if (p == null)``;
* PRF-7 detector: the Mesafe birimi onChanged converts the typed zero from
  the internal default unit even while the box still says "Seçiniz".

Run: python3 tools/denetim_2026_10_15b_profil.py
"""
from __future__ import annotations

import math
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dart_library_source import library_text  # noqa: E402

M_PER_FT = 0.3048
M_PER_YD = 0.9144
M_PER_IN = 0.0254
G = 9.80665
RAD_PER_MOA = math.pi / (180 * 60)
RAD_PER_SMOA = M_PER_IN / (100 * M_PER_YD)
RAD_PER_MRAD = 0.001

LIBRARY = 'lib/features/profiles/profiles_screen.dart'
IDENTITY_LABELS = {'Marka', 'Model', 'Dürbün markası', 'Profil adı'}


# ---- Hand calculations ------------------------------------------------------

def fps_to_mps(fps: float) -> float:
    return fps * M_PER_FT


def mps_to_fps(mps: float) -> float:
    return mps / M_PER_FT


def velocity_round_trip(mps: float) -> float:
    """Stored m/s -> box (fps, one decimal) -> stored m/s."""
    return fps_to_mps(round(mps_to_fps(mps), 1))


def zero_round_trip_yd(meters: float) -> float:
    """Stored zero (m) -> box (yd, 0.1) -> stored m."""
    return round(meters / M_PER_YD, 1) * M_PER_YD


def band_round_trip(mps: float) -> float:
    """Stored band threshold (m/s) -> box (whole fps) -> stored m/s."""
    return fps_to_mps(round(mps_to_fps(mps)))


def travel_clicks(mrad: float, click: float, unit: str) -> int:
    rad_per_unit = {'moa': RAD_PER_MOA, 'smoa': RAD_PER_SMOA,
                    'mrad': RAD_PER_MRAD}[unit]
    return round(mrad * RAD_PER_MRAD / rad_per_unit / click)


def clicks_to_mrad(clicks: int, click: float, unit: str) -> float:
    rad_per_unit = {'moa': RAD_PER_MOA, 'smoa': RAD_PER_SMOA,
                    'mrad': RAD_PER_MRAD}[unit]
    return clicks * click * rad_per_unit / RAD_PER_MRAD


# Worst-case display rounding, in SI (half a display step).
VELOCITY_TOL_MPS = 0.05 * M_PER_FT          # 0.01524 m/s
BAND_TOL_MPS = 0.5 * M_PER_FT               # 0.1524 m/s
ZERO_TOL_M = 0.05 * M_PER_YD                # 0.04572 m


def bore_angle_mrad(zero_m: float, v_mps: float, sight_m: float) -> float:
    """Vacuum flat-fire bore angle above the line of sight for zero Z."""
    return math.atan((sight_m + G * zero_m ** 2 / (2 * v_mps ** 2))
                     / zero_m) / RAD_PER_MRAD


def prf7_effect(typed: float, v_fps: float, sight_mm: float,
                range_m: float) -> dict:
    """User types [typed] while Mesafe birimi is "Seçiniz", then picks Yard.

    Intended zero: typed yd. Stored: typed m (the box then shows typed m in
    yd). Returns the shown value, both zeros and the vacuum aim error.
    """
    intended = typed * M_PER_YD
    shown = round(typed / M_PER_YD, 1)  # the box after picking Yard
    stored = shown * M_PER_YD  # metres, what Kaydet writes
    v = fps_to_mps(v_fps)
    h = sight_mm / 1000
    d = bore_angle_mrad(stored, v, h) - bore_angle_mrad(intended, v, h)
    return {
        'shown_yd': shown,
        'intended_m': intended,
        'stored_m': stored,
        'angle_error_mrad': d,
        'offset_mm_at_range': d * RAD_PER_MRAD * range_m * 1000,
    }


# ---- Source scans -----------------------------------------------------------

def editor_source() -> str:
    return library_text(LIBRARY)


def _call_body(src: str, open_paren: int) -> str:
    depth = 0
    i = open_paren
    while i < len(src):
        ch = src[i]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0:
                return src[open_paren + 1:i]
        elif ch in '\'"':
            j = src.find(ch, i + 1)
            while j > 0 and src[j - 1] == '\\':
                j = src.find(ch, j + 1)
            i = j if j > 0 else i
        i += 1
    return src[open_paren + 1:]


_FIELD = re.compile(r'\b(MenzilInput|MenzilSelect(?:<[^>(]*>)?)\(')
_LABEL = re.compile(r"\blabel:\s*('(?:[^'\\]|\\.)*'|[\w.]+)")


def fields_without_info(src: str | None = None) -> list[tuple[str, str]]:
    """(widget, label) of every editor box without ``info:``, identity
    boxes excluded."""
    src = src if src is not None else editor_source()
    out = []
    for m in _FIELD.finditer(src):
        body = _call_body(src, m.end() - 1)
        label_m = _LABEL.search(body)
        label = label_m.group(1).strip("'") if label_m else '?'
        if re.search(r'\binfo:', body):
            continue
        if label in IDENTITY_LABELS:
            continue
        out.append((m.group(1), label))
    return out


_CONTROLLER = re.compile(
    r'late final (?:List<TextEditingController>|TextEditingController)\s+'
    r'(\w+);')

# Methods of the save path: everything _save writes reads through these.
_SAVE_METHODS = ('_save', '_rifleEntry', '_ammoEntry', '_scopeEntry',
                 '_bandEntries', '_travelMrad', '_zeroMetersText',
                 '_savedLengthMm', '_scopeDesignation', '_curveSd')


def _method_text(src: str, name: str) -> str:
    """Text of the member [name] (block or arrow body)."""
    m = re.search(
        r'(?:Future<void>|Map<String, dynamic>|String|double\?|'
        r'List<Map<String, double>>)\s+(?:get\s+)?' + re.escape(name) +
        r'\b', src)
    if not m:
        return ''
    brace = src.find('{', m.end())
    arrow = src.find('=>', m.end())
    if arrow >= 0 and (brace < 0 or arrow < brace):
        depth, i = 0, arrow
        while i < len(src):
            if src[i] in '([{':
                depth += 1
            elif src[i] in ')]}':
                depth -= 1
            elif src[i] == ';' and depth == 0:
                return src[m.start():i + 1]
            i += 1
        return src[m.start():]
    depth, i = 0, brace
    while i < len(src):
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
            if depth == 0:
                return src[m.start():i + 1]
        i += 1
    return src[m.start():]


def controllers_not_saved(src: str | None = None) -> list[str]:
    src = src if src is not None else editor_source()
    save_text = '\n'.join(_method_text(src, n) for n in _SAVE_METHODS)
    # ProfileInput.validate reads its controllers inside _save.
    return [c for c in _CONTROLLER.findall(src)
            if not re.search(r'\b' + re.escape(c) + r'\b', save_text)]


def tur_blocks_only_new_profile(src: str | None = None) -> bool:
    src = src if src is not None else editor_source()
    if not re.search(r'bool _platformSet = true;', src):
        return False
    if "(_platformSet, 'Tür')" not in src:
        return False
    falses = [m.start() for m in re.finditer(r'_platformSet = false;', src)]
    if len(falses) != 1:
        return False
    head = src[:falses[0]]
    block = head.rfind('if (p == null) {')
    return block >= 0 and '}' not in head[block + len('if (p == null) {'):]


def prf7_present(src: str | None = None) -> bool:
    """The Mesafe birimi onChanged converts the zero without asking whether
    a unit was set before (finding PRF-7)."""
    src = src if src is not None else editor_source()
    i = src.find("key: const Key('profile-distance-unit')")
    if i < 0:
        return False
    j = src.find('onChanged:', i)
    body = src[j:src.find('distanceUnit = next;', j)]
    converts = 'next != distanceUnit' in body
    guarded = re.search(r'_distanceUnitSet\s*&&|if\s*\(\s*_distanceUnitSet',
                        body.split('_distanceUnitSet = v != null;')[-1])
    return converts and guarded is None


def main() -> int:
    print('Velocity round trip worst case: %.5f m/s' % VELOCITY_TOL_MPS)
    print('Band threshold worst case:      %.4f m/s' % BAND_TOL_MPS)
    print('Zero (yd, 0.1) worst case:      %.5f m' % ZERO_TOL_M)
    print('100 MOA = %.12f mrad; 120 SMOA = %.12f mrad'
          % (clicks_to_mrad(400, 0.25, 'moa'),
             clicks_to_mrad(480, 0.25, 'smoa')))
    for typed, v, h, r in [(100, 2650, 45, 600), (300, 2650, 45, 800),
                           (30, 920, 55, 60)]:
        e = prf7_effect(typed, v, h, r)
        print('PRF-7 typed %g then Yard: box %.1f yd, stored %.2f m '
              '(meant %.2f m), aim error %.3f mrad = %.0f mm at %g m'
              % (typed, e['shown_yd'], e['stored_m'], e['intended_m'],
                 e['angle_error_mrad'], e['offset_mm_at_range'], r))
    print('Boxes without info:', fields_without_info() or 'none')
    print('Controllers not read on save:', controllers_not_saved() or 'none')
    print('Tür blocks only a new profile:', tur_blocks_only_new_profile())
    print('PRF-7 present in source:', prf7_present())
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
