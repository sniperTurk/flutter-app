"""Read the projectile records the app ships (research only, no app code).

Parses `lib/data/bullet_library.dart` (LibraryBullet rows) and
`lib/data/factory_ammo_library.dart` (FactoryAmmo rows) into plain dicts.
Used by `tools/research/bc_estimator_cv.py` (docs/research/tahmini_bc_hata.md).
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BULLETS = ROOT / "lib" / "data" / "bullet_library.dart"
FACTORY = ROOT / "lib" / "data" / "factory_ammo_library.dart"


def _split_args(s: str) -> list[str]:
    """Split a Dart argument list at top-level commas (quotes, (), [] aware)."""
    out, cur, depth, quote, esc = [], [], 0, None, False
    for ch in s:
        if quote:
            cur.append(ch)
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == quote:
                quote = None
            continue
        if ch in "'\"":
            quote = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return out


def _str(tok: str) -> str:
    tok = tok.strip()
    if tok[0] in "'\"" and tok[-1] == tok[0]:
        return tok[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\$", "$")
    raise ValueError(tok)


def _num(tok: str) -> float | None:
    tok = tok.strip()
    return None if tok == "null" else float(tok)


def _calls(text: str, ctor: str) -> list[str]:
    """Bodies of every `ctor(...)` call (balanced parentheses, quote aware)."""
    bodies, i = [], 0
    needle = ctor + "("
    while True:
        j = text.find(needle, i)
        if j < 0:
            return bodies
        # skip the class declaration / const constructor
        prev = text[max(0, j - 6):j]
        k, depth, quote, esc = j + len(needle), 1, None, False
        start = k
        while depth:
            ch = text[k]
            if quote:
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == quote:
                    quote = None
            elif ch in "'\"":
                quote = ch
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
            k += 1
        body = text[start:k - 1]
        if "const " not in prev and not body.lstrip().startswith("this."):
            bodies.append(body)
        i = k


def load_bullets() -> list[dict]:
    rows = []
    for body in _calls(BULLETS.read_text(encoding="utf-8"), "LibraryBullet"):
        a = _split_args(body)
        if len(a) != 15:
            continue
        rows.append(dict(
            brand=_str(a[0]), name=_str(a[1]), item=_str(a[2]),
            caliber_mm=_num(a[3]), diameter_mm=_num(a[4]), grain=_num(a[5]),
            g1=_num(a[6]), g7=_num(a[7]), model=a[8].split(".")[-1], bc=_num(a[9]),
            length_mm=_num(a[11]), type=a[12].split(".")[-1], platform=a[13].split(".")[-1],
            source=_str(a[14]), origin="bullet_library"))
    return rows


def load_factory() -> list[dict]:
    rows = []
    for body in _calls(FACTORY.read_text(encoding="utf-8"), "FactoryAmmo"):
        a = _split_args(body)
        pos = [x for x in a if not re.match(r"^\w+\s*:", x)]
        named = dict(re.match(r"^(\w+)\s*:\s*(.*)$", x, re.S).groups() for x in a
                     if re.match(r"^\w+\s*:", x))
        if len(pos) < 10:
            continue
        model = pos[6].split(".")[-1] if pos[6] != "null" else None
        rows.append(dict(
            brand=_str(pos[0]), name=_str(pos[1]), cartridge=_str(pos[2]),
            diameter_mm=_num(pos[3]), grain=_num(pos[4]), bc=_num(pos[5]), model=model,
            mv_fps=_num(pos[7]), bc_from_bullet=named.get("bcFromBullet", "false") == "true",
            bc_source=named.get("bcSource"), origin="factory_ammo"))
    return rows


if __name__ == "__main__":
    b, f = load_bullets(), load_factory()
    print(len(b), "bullet rows;", len(f), "factory rows")
