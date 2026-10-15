#!/usr/bin/env python3
"""Wire the phone-side Garmin bridge into a generated iOS scaffold (opt-in).

Copies garmin/ios_runner/SniperTurkGarminBridge.{h,m} into ios/Runner,
imports the header in the Swift bridging header, registers the plugin in
AppDelegate right after GeneratedPluginRegistrant and adds what the Garmin
Connect IQ Mobile SDK needs to Info.plist:

* CFBundleURLTypes: ``sniperturk-ciq`` (Garmin Connect returns the user's
  device selection to this scheme),
* LSApplicationQueriesSchemes: ``gcm-ciq`` (SDK checks Garmin Connect),
* Bluetooth purpose strings (the SDK talks to the watch over BLE).

Adding the sources, the Swift package (ConnectIQ) and ``-ObjC`` to the Runner
target is done by configure_ios_garmin_bridge.rb.

Only the manual Garmin workflow (.github/workflows/garmin-sim.yml) runs this.
bootstrap_ios_scaffold.sh, iOS CI and TestFlight never do, so the shipped
app is unchanged until the owner decides to wire it in.

Idempotent; fails closed on an AppDelegate without GeneratedPluginRegistrant
or a scaffold without a bridging header.
"""
from __future__ import annotations

import plistlib
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    ROOT / "garmin" / "ios_runner" / "SniperTurkGarminBridge.h",
    ROOT / "garmin" / "ios_runner" / "SniperTurkGarminBridge.m",
)
MARKER = "// sniper-turk: garmin-bridge"
HEADER_IMPORT = '#import "SniperTurkGarminBridge.h"'
URL_SCHEME = "sniperturk-ciq"
URL_NAME = "com.sniperturk.garmin"
QUERY_SCHEME = "gcm-ciq"
BLUETOOTH_TEXT = (
    "Bluetooth yalnızca eşlediğiniz Garmin saatine Atış çözümünü göndermek "
    "ve saatten mesafe isteğini almak için kullanılır."
)
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
        f"{indent}let garminRegistrar: FlutterPluginRegistrar? =\n"
        f'{indent}  {registry}.registrar(forPlugin: "SniperTurkGarminBridge")\n'
        f"{indent}if let garminRegistrar {{\n"
        f"{indent}  SniperTurkGarminBridge.register(with: garminRegistrar)\n"
        f"{indent}}}\n"
    )
    return text[: match.end()] + block + text[match.end():]


def patch_bridging_header(text: str) -> str:
    if HEADER_IMPORT in text:
        return text
    if text and not text.endswith("\n"):
        text += "\n"
    return text + HEADER_IMPORT + "\n"


def patch_info_plist(info: dict) -> dict:
    out = dict(info)
    url_types = [dict(t) for t in out.get("CFBundleURLTypes", [])]
    if not any(URL_SCHEME in t.get("CFBundleURLSchemes", []) for t in url_types):
        url_types.append(
            {
                "CFBundleTypeRole": "Editor",
                "CFBundleURLName": URL_NAME,
                "CFBundleURLSchemes": [URL_SCHEME],
            }
        )
    out["CFBundleURLTypes"] = url_types
    queries = list(out.get("LSApplicationQueriesSchemes", []))
    if QUERY_SCHEME not in queries:
        queries.append(QUERY_SCHEME)
    out["LSApplicationQueriesSchemes"] = queries
    out.setdefault("NSBluetoothAlwaysUsageDescription", BLUETOOTH_TEXT)
    out.setdefault("NSBluetoothPeripheralUsageDescription", BLUETOOTH_TEXT)
    return out


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: configure_ios_garmin_bridge.py IOS_RUNNER_DIR", file=sys.stderr)
        return 2
    runner = Path(argv[1])
    delegate = runner / "AppDelegate.swift"
    header = runner / "Runner-Bridging-Header.h"
    plist = runner / "Info.plist"
    for required in (delegate, header, plist):
        if not required.is_file():
            print(f"missing iOS scaffold file: {required}", file=sys.stderr)
            return 2
    try:
        patched = patch_app_delegate(delegate.read_text(encoding="utf-8"))
    except ValueError as e:
        print(f"cannot wire Garmin bridge: {e}", file=sys.stderr)
        return 1
    delegate.write_text(patched, encoding="utf-8")
    header.write_text(patch_bridging_header(header.read_text(encoding="utf-8")), encoding="utf-8")
    with plist.open("rb") as f:
        info = plistlib.load(f)
    with plist.open("wb") as f:
        plistlib.dump(patch_info_plist(info), f)
    for source in SOURCES:
        shutil.copyfile(source, runner / source.name)
    print("Garmin bridge copied, registered in AppDelegate and Info.plist updated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
