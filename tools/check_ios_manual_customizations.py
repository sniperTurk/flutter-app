#!/usr/bin/env python3
"""Fail closed when an iOS scaffold contains non-reproducible Xcode customization."""
from __future__ import annotations
import os
import re
import sys
from pathlib import Path


def find_customizations(pbxproj: Path, runner_dir: Path) -> list[str]:
    text = pbxproj.read_text(encoding="utf-8", errors="strict")
    found: list[str] = []
    checks = {
        "development team": r"DEVELOPMENT_TEAM\s*=\s*[^;\s]+\s*;",
        "provisioning profile": r"PROVISIONING_PROFILE_SPECIFIER\s*=\s*[^;\n]+;",
        "code-sign entitlements": r"CODE_SIGN_ENTITLEMENTS\s*=\s*[^;\n]+;",
        "target capabilities": r"SystemCapabilities\s*=\s*\{",
    }
    # tools/configure_ios_signing.py writes the team supplied through
    # SNIPER_TURK_IOS_DEVELOPMENT_TEAM into every generated build setting. A tree
    # whose only team entries equal that value is reproducible, not manual.
    allowed_team = os.environ.get("SNIPER_TURK_IOS_DEVELOPMENT_TEAM", "").strip()
    for label, pattern in checks.items():
        if label == "development team":
            teams = re.findall(r"DEVELOPMENT_TEAM\s*=\s*([^;\s]+)\s*;", text)
            if any(team != allowed_team for team in teams):
                found.append(label)
            continue
        if re.search(pattern, text):
            found.append(label)
    if runner_dir.is_dir() and any(runner_dir.glob("*.entitlements")):
        found.append("Runner entitlements file")
    return found


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: check_ios_manual_customizations.py PROJECT_PBXPROJ RUNNER_DIR", file=sys.stderr)
        return 2
    pbxproj, runner = map(Path, argv[1:])
    if not pbxproj.is_file():
        print(f"missing Xcode project file: {pbxproj}", file=sys.stderr)
        return 2
    found = find_customizations(pbxproj, runner)
    if found:
        print("manual iOS customization detected: " + ", ".join(found), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
