#!/usr/bin/env python3
"""Fail-closed verifier for generated Flutter lockfile provenance."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import sys

EXPECTED_FLUTTER = "3.47.2"
EXPECTED_KEYS = {"flutter", "pubspec_sha256", "lockfile_sha256"}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify(pubspec: Path, lockfile: Path, provenance: Path) -> list[str]:
    errors: list[str] = []
    for path, label in ((pubspec, "pubspec.yaml"), (lockfile, "pubspec.lock"), (provenance, "lockfile provenance")):
        # Provenance verification is a trust boundary: never follow symlinks.
        # Otherwise a checked path can resolve outside the workspace between
        # generation/adoption and verification.
        if path.is_symlink():
            errors.append(f"{label} must not be a symbolic link: {path}")
            continue
        try:
            if not path.is_file() or path.stat().st_size == 0:
                errors.append(f"{label} is missing or empty: {path}")
        except OSError as exc:
            errors.append(f"{label} could not be inspected: {path}: {exc}")
    if errors:
        return errors

    values: dict[str, str] = {}
    try:
        provenance_lines = provenance.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        return [f"lockfile provenance could not be read as UTF-8: {exc}"]
    for line_number, raw in enumerate(provenance_lines, 1):
        if not raw or "=" not in raw:
            errors.append(f"invalid provenance line {line_number}")
            continue
        key, value = raw.split("=", 1)
        if key not in EXPECTED_KEYS:
            errors.append(f"unknown provenance key: {key!r}")
            continue
        if key in values:
            errors.append(f"duplicate provenance key: {key!r}")
            continue
        values[key] = value

    missing = EXPECTED_KEYS - values.keys()
    for key in sorted(missing):
        errors.append(f"missing provenance key: {key}")
    if errors:
        return errors

    if values["flutter"] != EXPECTED_FLUTTER:
        errors.append(f"Flutter provenance must be exactly {EXPECTED_FLUTTER}; got {values['flutter']!r}")
    for key in ("pubspec_sha256", "lockfile_sha256"):
        if not SHA256_RE.fullmatch(values[key]):
            errors.append(f"{key} is not a lowercase SHA-256 digest")
    if errors:
        return errors

    try:
        actual_pubspec = sha256(pubspec)
        actual_lockfile = sha256(lockfile)
    except OSError as exc:
        return [f"lockfile provenance inputs changed or became unreadable during verification: {exc}"]
    if values["pubspec_sha256"] != actual_pubspec:
        errors.append("pubspec.yaml SHA-256 does not match provenance")
    if values["lockfile_sha256"] != actual_lockfile:
        errors.append("pubspec.lock SHA-256 does not match provenance")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    parser.add_argument("--lockfile", type=Path, default=Path("pubspec.lock"))
    parser.add_argument("--provenance", type=Path, default=Path("lockfile-provenance.txt"))
    args = parser.parse_args()
    errors = verify(args.pubspec, args.lockfile, args.provenance)
    if errors:
        print("LOCKFILE PROVENANCE VERIFY: BLOCKED", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"LOCKFILE PROVENANCE VERIFY: OK — Flutter {EXPECTED_FLUTTER}, source and lock hashes match")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
