"""Source text of a Dart library: the file followed by its `part` files.

Module split (owner, 2026-10-15): ballistics_screen.dart and
scope_dial_view.dart keep their state and calculations, their page pieces
moved verbatim into `part` files. Source-text guards read the whole library
so every assertIn / assertNotIn still covers all of the code it covered
before the split.
"""
from __future__ import annotations

import re
from pathlib import Path

_PART = re.compile(r"^part\s+'([^']+)';", re.MULTILINE)


def library_text(path: Path | str) -> str:
    """The library file's text plus each of its parts, in directive order."""
    path = Path(path)
    text = path.read_text(encoding="utf-8")
    parts = [
        (path.parent / rel).read_text(encoding="utf-8")
        for rel in _PART.findall(text)
    ]
    return "\n".join([text, *parts])
