#!/usr/bin/env python3
"""Wire the phone-side watch bridge into a generated iOS scaffold (opt-in).

Copies watch/ios_runner/SniperTurkWatchBridge.swift into ios/Runner and
registers it in AppDelegate right after GeneratedPluginRegistrant. Adding the
file to the Runner target is done by configure_ios_watch_bridge.rb.

Only the manual watch workflow (.github/workflows/watch-sim.yml) runs this.
bootstrap_ios_scaffold.sh, iOS CI and TestFlight never do, so the shipped
app is unchanged until the owner decides to wire it in.

Idempotent; fails closed on an AppDelegate without GeneratedPluginRegistrant.
"""
from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "watch" / "ios_runner" / "SniperTurkWatchBridge.swift"
MARKER = "// sniper-turk: watch-bridge"
_REGISTER = re.compile(
    r"^(?P<indent>[ \t]*)GeneratedPluginRegistrant\.register\(with:\s*(?P<registry>[^)]+?)\s*\)[ \t]*\n",
    re.MULTILINE,
)


def patch_app_delegate(text: str) -> str:
    if MARKER in text:
        return text
    match = _REGISTER.search(text)
    if not match:
        raise ValueError("AppDelegate.swift has no GeneratedPluginRegistrant.register(with:) line")
    indent = match.group("indent")
    registry = match.group("registry").strip()
    block = (
        f"{indent}{MARKER}\n"
        f"{indent}let watchRegistrar: FlutterPluginRegistrar? =\n"
        f'{indent}  {registry}.registrar(forPlugin: "SniperTurkWatchBridge")\n'
        f"{indent}if let watchRegistrar {{\n"
        f"{indent}  SniperTurkWatchBridge.register(with: watchRegistrar)\n"
        f"{indent}}}\n"
    )
    return text[: match.end()] + block + text[match.end():]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: configure_ios_watch_bridge.py IOS_RUNNER_DIR", file=sys.stderr)
        return 2
    runner = Path(argv[1])
    delegate = runner / "AppDelegate.swift"
    if not delegate.is_file():
        print(f"missing iOS scaffold file: {delegate}", file=sys.stderr)
        return 2
    try:
        patched = patch_app_delegate(delegate.read_text(encoding="utf-8"))
    except ValueError as e:
        print(f"cannot wire watch bridge: {e}", file=sys.stderr)
        return 1
    delegate.write_text(patched, encoding="utf-8")
    shutil.copyfile(SOURCE, runner / SOURCE.name)
    print("watch bridge copied and registered in AppDelegate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
