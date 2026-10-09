#!/usr/bin/env python3
"""Wire the Google Maps iOS SDK key into the generated iOS scaffold.

The key comes ONLY from the environment (GOOGLE_MAPS_IOS_API_KEY, a GitHub
Actions secret) and is never committed. It is written into Info.plist as
`GMSApiKey`; AppDelegate reads it from there and calls
`GMSServices.provideAPIKey` before the Flutter engine registers plugins.

Without a key nothing is written to Info.plist, the AppDelegate guard skips
the call and the app uses its keyless Esri map (the Dart side is told through
--dart-define=GOOGLE_MAPS_ENABLED).

Idempotent: running it twice leaves one import and one provideAPIKey call.
Fails closed when the generated AppDelegate has an unexpected shape.
"""
from __future__ import annotations

import os
import plistlib
import re
import sys
from pathlib import Path

IMPORT_LINE = "import GoogleMaps"
MARKER = "// sniper-turk: google-maps-key"
CALL = (
    f"    {MARKER}\n"
    "    if let key = Bundle.main.object(forInfoDictionaryKey: \"GMSApiKey\") as? String,\n"
    "      !key.isEmpty {\n"
    "      GMSServices.provideAPIKey(key)\n"
    "    }\n"
)
PLIST_KEY = "GMSApiKey"


def patch_app_delegate(text: str) -> str:
    if MARKER in text and IMPORT_LINE in text:
        return text
    if "import Flutter" not in text:
        raise ValueError("AppDelegate.swift has no 'import Flutter' line")
    if IMPORT_LINE not in text:
        text = text.replace("import Flutter", f"import Flutter\n{IMPORT_LINE}", 1)
    if MARKER not in text:
        match = re.search(r"didFinishLaunchingWithOptions[^{]*\{\n", text)
        if not match:
            raise ValueError(
                "AppDelegate.swift has no application(_:didFinishLaunchingWithOptions:)"
            )
        text = text[: match.end()] + CALL + text[match.end():]
    return text


def patch_info_plist(path: Path, key: str) -> None:
    with path.open("rb") as f:
        info = plistlib.load(f)
    if key:
        info[PLIST_KEY] = key
    else:
        info.pop(PLIST_KEY, None)
    with path.open("wb") as f:
        plistlib.dump(info, f)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            "usage: configure_ios_google_maps.py APP_DELEGATE_SWIFT INFO_PLIST",
            file=sys.stderr,
        )
        return 2
    delegate, plist = map(Path, argv[1:])
    for p in (delegate, plist):
        if not p.is_file():
            print(f"missing iOS scaffold file: {p}", file=sys.stderr)
            return 2
    try:
        delegate.write_text(
            patch_app_delegate(delegate.read_text(encoding="utf-8")),
            encoding="utf-8",
        )
    except ValueError as e:
        print(f"cannot wire Google Maps: {e}", file=sys.stderr)
        return 1
    key = os.environ.get("GOOGLE_MAPS_IOS_API_KEY", "").strip()
    patch_info_plist(plist, key)
    print("Google Maps key " + ("installed" if key else "absent: Esri map is used"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
