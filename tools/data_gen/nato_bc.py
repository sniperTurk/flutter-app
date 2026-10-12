"""NATO standart mermi BC'si (owner, 2026-10-12).

Reads data/nato-bc/nato_bc.json (data/nato-bc branch): for MKE and military
cartridges whose maker publishes no BC, the BC of the same NATO standard
bullet from an official public report (ARL/BRL on DTIC, NATO open
publications). Only entries with status 'uygulandı' are used, and each must
name an allowed source; anything else is refused rather than guessed.
"""
import json
import math
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# Official public-release hosts only (owner rule: no forum, blog, dealer,
# ChairGun, Strelok, Applied Ballistics, JBM, QuickLOAD, GRT).
ALLOWED_HOSTS = ('apps.dtic.mil', 'ndia.dtic.mil', 'www.nato.int', 'nso.nato.int', 'www.sto.nato.int')
ALLOWED_LICENSES = ('us-government-public-release', 'nato-public-release')


def _check(e):
    rec = f"{e.get('dataset')}/{e.get('record')}"
    url = e.get('source_url') or ''
    m = re.match(r'^https://([^/]+)/', url)
    if not m or m.group(1) not in ALLOWED_HOSTS:
        raise ValueError(f'{rec}: source_url not an allowed official https host: {url!r}')
    if e.get('license') not in ALLOWED_LICENSES:
        raise ValueError(f"{rec}: license {e.get('license')!r} not allowed")
    if e.get('bc_model') not in ('g1', 'g7'):
        raise ValueError(f"{rec}: bc_model {e.get('bc_model')!r}")
    bc = e.get('bc')
    if not isinstance(bc, (int, float)) or not 0 < bc < 2:
        raise ValueError(f'{rec}: bc {bc!r}')
    if e.get('bc_source') != 'nato-standard' or not e.get('nato_standard') or not e.get('source_title'):
        raise ValueError(f'{rec}: bc_source/nato_standard/source_title missing')
    if e.get('match') not in ('kesin', 'muhtemel'):
        raise ValueError(f"{rec}: match {e.get('match')!r}")


def nato_entries(path):
    """{(dataset, record): entry} for the applied entries of [path]."""
    out = {}
    for e in json.loads(Path(path).read_text(encoding='utf-8')):
        if e.get('status') != 'uygulandı':
            continue
        _check(e)
        out[(e['dataset'], e['record'])] = e
    return out


def report_id(e):
    """Report number from the title, e.g. 'ARL-TR-5182', 'BRL-MR-3733'."""
    m = re.search(r'\b((?:ARL|BRL|ARBRL)-[A-Z]{2}-\d+)\b', e['source_title'])
    if not m:
        raise ValueError(f"{e['record']}: no report number in source_title")
    return m.group(1)


def short_standard(name):
    """'M855 Ball (5.56×45, SS109 tipi)' -> 'M855'."""
    return name.split()[0]


def _osc():
    sys.path.insert(0, str(REPO / 'tools'))
    import offline_solver_crosscheck as osc  # noqa: E402
    return osc


def load_tables():
    return _osc().load_tables()


def muzzle_from(v_at, dist_m, bc, model, tables):
    """Back-integrates [model] drag from v(dist) to the muzzle (ICAO standard air)."""
    table, cd_at = tables[model], _osc().cd_at
    rho, c = 1.225, 340.294
    v, x, dx = v_at, dist_m, 0.01
    while x > 1e-9:
        a = 0.5 * rho * cd_at(table, v / c) * (math.pi / 4) * v * v / (bc * 703.0695796391593)
        v += a / v * dx  # dv/dx = -a/v, integrating backwards
        x -= dx
    return v
