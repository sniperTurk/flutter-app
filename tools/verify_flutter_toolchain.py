#!/usr/bin/env python3
"""Fail-closed verifier for the Flutter release toolchain version."""
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

EXPECTED_FLUTTER_VERSION = "3.47.2"


def read_project_pin(root: Path) -> tuple[str | None, list[str]]:
    """Read the project Flutter pin fail-closed from .fvmrc."""
    path = root / ".fvmrc"
    try:
        if path.is_symlink():
            return None, [".fvmrc must not be a symbolic link"]
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except FileNotFoundError:
        return None, [".fvmrc is missing"]
    except UnicodeDecodeError:
        return None, [".fvmrc is not valid UTF-8"]
    except (OSError, json.JSONDecodeError) as exc:
        return None, [f".fvmrc could not be read as JSON: {exc}"]
    if not isinstance(data, dict):
        return None, [".fvmrc JSON root must be an object"]
    pin = data.get("flutter")
    if not isinstance(pin, str) or not pin.strip():
        return None, [".fvmrc must contain a non-empty flutter version"]
    return pin.strip(), []


def verify(payload: str) -> list[str]:
    errors: list[str] = []
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return ["flutter --version --machine did not return valid JSON"]
    if not isinstance(data, dict):
        return ["flutter --version --machine JSON root must be an object"]
    actual = data.get("frameworkVersion")
    if actual != EXPECTED_FLUTTER_VERSION:
        errors.append(f"Flutter must be exactly {EXPECTED_FLUTTER_VERSION}; got {actual!r}")
    return errors


def main() -> int:
    project_root = Path(__file__).resolve().parent.parent
    expected, pin_errors = read_project_pin(project_root)
    if pin_errors:
        print("FLUTTER TOOLCHAIN VERIFY: BLOCKED", file=sys.stderr)
        for error in pin_errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    if expected != EXPECTED_FLUTTER_VERSION:
        print(
            f"FLUTTER TOOLCHAIN VERIFY: BLOCKED — verifier policy expects "
            f"{EXPECTED_FLUTTER_VERSION}, but .fvmrc pins {expected}", file=sys.stderr
        )
        return 1
    try:
        proc = subprocess.run(
            ["flutter", "--version", "--machine"],
            check=False, capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"FLUTTER TOOLCHAIN VERIFY: BLOCKED — {exc}", file=sys.stderr)
        return 1
    if proc.returncode != 0:
        print("FLUTTER TOOLCHAIN VERIFY: BLOCKED — flutter version command failed", file=sys.stderr)
        if proc.stderr.strip():
            print(proc.stderr.strip(), file=sys.stderr)
        return 1
    errors = verify(proc.stdout)
    if errors:
        print("FLUTTER TOOLCHAIN VERIFY: BLOCKED", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"FLUTTER TOOLCHAIN VERIFY: OK — Flutter {EXPECTED_FLUTTER_VERSION}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
