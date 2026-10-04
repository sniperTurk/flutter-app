#!/usr/bin/env python3
"""Select exactly one connected physical iOS device from `flutter devices --machine` JSON.

Fail closed on simulators, ambiguous device sets, malformed input, or a requested
identifier that is not a connected physical iOS target.
"""
from __future__ import annotations
import argparse, json, sys


def physical_ios_devices(payload: object) -> list[dict]:
    if not isinstance(payload, list):
        raise ValueError("Flutter device payload must be a JSON array")
    result = []
    for item in payload:
        if not isinstance(item, dict):
            continue
        if item.get("targetPlatform") != "ios" or item.get("emulator") is not False:
            continue
        device_id = item.get("id")
        name = item.get("name")
        if isinstance(device_id, str) and device_id.strip() and isinstance(name, str) and name.strip():
            result.append(item)
    return result


def select(payload: object, requested_id: str | None = None) -> dict:
    devices = physical_ios_devices(payload)
    if requested_id:
        matches = [d for d in devices if d.get("id") == requested_id]
        if len(matches) != 1:
            raise ValueError(f"requested physical iOS device is not connected: {requested_id}")
        return matches[0]
    if not devices:
        raise ValueError("no connected physical iOS device found")
    if len(devices) != 1:
        ids = ", ".join(str(d.get("id")) for d in devices)
        raise ValueError(f"multiple physical iOS devices found; pass --device-id explicitly: {ids}")
    return devices[0]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--device-id")
    args = parser.parse_args()
    try:
        payload = json.load(sys.stdin)
        device = select(payload, args.device_id)
    except (ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print(device["id"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
