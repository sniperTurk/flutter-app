#!/usr/bin/env python3
"""Select one available iOS Simulator UDID from `xcrun simctl` JSON."""
from __future__ import annotations
import json
import subprocess
import sys
from typing import Any


def select_available_ios_udid(data: dict[str, Any]) -> str | None:
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime or not isinstance(devices, list):
            continue
        for device in devices:
            if isinstance(device, dict) and device.get("isAvailable") and device.get("udid"):
                return str(device["udid"])
    return None


def main() -> int:
    try:
        raw = subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "-j"],
            text=True,
        )
        data = json.loads(raw)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(f"Could not query iOS Simulator devices: {exc}", file=sys.stderr)
        return 2
    udid = select_available_ios_udid(data)
    if not udid:
        print("No available iOS Simulator device found", file=sys.stderr)
        return 1
    print(udid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
