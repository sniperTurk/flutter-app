#!/usr/bin/env python3
"""Deterministically apply an Apple Development Team to generated Xcode settings.

The team id is deliberately supplied by the release environment; it is never
invented or committed as user/account-specific source data.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import tempfile

TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")
STYLE_LINE_RE = re.compile(r"(?m)^(\s*)CODE_SIGN_STYLE = Automatic;\s*$")
TEAM_LINE_RE = re.compile(r"(?m)^\s*DEVELOPMENT_TEAM = [^;]+;\s*$\n?")


def configure(path: Path, team: str) -> int:
    if not TEAM_RE.fullmatch(team):
        raise ValueError("Apple Development Team id must be exactly 10 uppercase alphanumeric characters")
    original = path.read_text(encoding="utf-8")
    # Generated Flutter projects may be reconfigured repeatedly. Remove old
    # deterministic team lines first so the operation is idempotent.
    cleaned = TEAM_LINE_RE.sub("", original)
    matches = list(STYLE_LINE_RE.finditer(cleaned))
    if not matches:
        raise ValueError("project.pbxproj has no Automatic code-sign build settings")
    configured = STYLE_LINE_RE.sub(
        lambda m: f"{m.group(1)}CODE_SIGN_STYLE = Automatic;\n{m.group(1)}DEVELOPMENT_TEAM = {team};",
        cleaned,
    )
    if configured.count(f"DEVELOPMENT_TEAM = {team};") != len(matches):
        raise ValueError("failed to configure every Automatic code-sign build setting")
    fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(configured)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_name, path)
    finally:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass
    return len(matches)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("project")
    parser.add_argument("--team", required=True)
    args = parser.parse_args()
    try:
        count = configure(Path(args.project), args.team)
    except (OSError, ValueError) as exc:
        print(f"iOS signing configuration FAILED: {exc}", file=os.sys.stderr)
        return 2
    print(f"iOS signing configuration: PASS ({count} build settings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
