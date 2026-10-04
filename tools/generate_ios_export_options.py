#!/usr/bin/env python3
"""Generate deterministic App Store Connect ExportOptions.plist.

This is source-side release plumbing only. It does not install Apple credentials,
sign an archive, export an IPA, or claim App Store readiness.
"""
from __future__ import annotations
import argparse, os, plistlib, re, tempfile
from pathlib import Path

TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")


def build(team_id: str) -> dict[str, object]:
    if not TEAM_RE.fullmatch(team_id):
        raise ValueError("Apple Development Team ID must be exactly 10 uppercase letters/digits")
    return {
        "destination": "export",
        "manageAppVersionAndBuildNumber": False,
        "method": "app-store-connect",
        "signingStyle": "automatic",
        "stripSwiftSymbols": True,
        "teamID": team_id,
        "uploadSymbols": True,
    }


def write_atomic(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = plistlib.dumps(payload, fmt=plistlib.FMT_XML, sort_keys=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as fh:
            fh.write(data)
            fh.flush()
            os.fsync(fh.fileno())
        os.replace(tmp, path)
    except BaseException:
        try: os.unlink(tmp)
        except FileNotFoundError: pass
        raise


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--team-id", default=os.environ.get("SNIPER_TURK_IOS_DEVELOPMENT_TEAM", ""))
    p.add_argument("--output", type=Path, default=Path("build/ios/ExportOptions.plist"))
    a = p.parse_args()
    try:
        payload = build(a.team_id)
        write_atomic(a.output, payload)
    except (ValueError, OSError) as exc:
        print(f"iOS export options FAILED: {exc}", file=os.sys.stderr)
        return 1
    print(f"iOS export options: PASS ({a.output})")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
