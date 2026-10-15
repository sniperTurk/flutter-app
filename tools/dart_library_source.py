"""Source text of a Dart library: the main file followed by its part files.

profiles_screen.dart was split into part files (Tüfek, Dürbün, Mühimmat, Ek
mühimmat bilgileri, summary, editor; owner, 2026-10-15). It is still ONE
Dart library, so the offline source guards read all of it: an assertNotIn
cannot pass just because the text moved to a part file.
"""
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
_PART = re.compile(r"^part\s+'([^']+)';", re.M)


def library_text(rel: str) -> str:
    main = ROOT / rel
    text = main.read_text(encoding='utf-8')
    parts = [
        (main.parent / p).read_text(encoding='utf-8') for p in _PART.findall(text)
    ]
    return '\n'.join([text, *parts])
