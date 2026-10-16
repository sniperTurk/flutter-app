#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15c, app shell / navigation: static source
checks for #331 (top bar, theme button deleted), #328 (main buttons text
only) and #343 (Rehber "Profil ekle").

Reads lib/ only; no network, no Flutter. Each check returns a list of
"path:line: text" hits; an empty list means clean.

  python3 tools/denetim_2026_10_15c_ust.py   # prints every check
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

# Names of the deleted theme switch (#331) and the old stored key read.
THEME_LEFTOVERS = (
    "MenzilThemeController",
    "MenzilThemeScope",
    "MenzilBarButton",
    "themeLabel",
    "onThemeTap",
    "'theme.dark'",
    '"theme.dark"',
)

# Button / top-bar labels replaced by #328 and #331.
OLD_LABELS = (
    "'Pro Ayarlara Geç'",
    "'Profil yok'",
)


def _dart_files() -> list[Path]:
    return sorted(LIB.rglob("*.dart"))


def _hits(words: tuple[str, ...], files: list[Path] | None = None) -> list[str]:
    out = []
    for f in files or _dart_files():
        for no, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for w in words:
                if w in line:
                    out.append(f"{f.relative_to(ROOT)}:{no}: {w}")
    return out


def theme_leftovers() -> list[str]:
    return _hits(THEME_LEFTOVERS)


def old_labels() -> list[str]:
    return _hits(OLD_LABELS)


def light_theme_in_app() -> list[str]:
    """UST-3: MenzilTheme.light() used by an app screen (lib/main.dart)."""
    return _hits(("MenzilTheme.light()",), [LIB / "main.dart"])


def icon_lead_layout() -> list[str]:
    """DGM-2: the oneLine + icon layout of MenzilPrimaryButton."""
    return _hits(("iconLead", "iconLabelGap"), [LIB / "ui" / "menzil_widgets.dart"])


def guide_profile_button() -> tuple[str, bool]:
    """DGM-1: the button the guide's first profile step names, and whether
    the welcome page (Profil without profiles) uses that label."""
    guide = (LIB / "features" / "guide" / "usage_guide_content.dart").read_text(
        encoding="utf-8"
    )
    m = re.search(r"'1\. Profil sayfasında \"([^\"]+)\"a dokun", guide)
    label = m.group(1) if m else ""
    empty = (LIB / "features" / "home" / "empty_states.dart").read_text(
        encoding="utf-8"
    )
    welcome = re.search(
        r"_EmptyActions\(onCreate: onCreate, createLabel: '([^']+)'\)", empty
    )
    return label, bool(welcome) and welcome.group(1) == label


def main() -> int:
    print("theme leftovers:", theme_leftovers() or "none")
    print("old labels:", old_labels() or "none")
    print("UST-3 light theme in lib/main.dart:", light_theme_in_app() or "none")
    print("DGM-2 iconLead layout:", icon_lead_layout() or "none")
    label, ok = guide_profile_button()
    print(f"DGM-1 guide names {label!r} on Profil; welcome page matches: {ok}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
