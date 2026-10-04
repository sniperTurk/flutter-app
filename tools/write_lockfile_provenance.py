#!/usr/bin/env python3
"""Write deterministic provenance for a lockfile resolved by the pinned Flutter SDK."""
from __future__ import annotations
import argparse
import os
from pathlib import Path
import tempfile
from verify_lockfile_provenance import EXPECTED_FLUTTER, sha256, verify


def write(pubspec: Path, lockfile: Path, output: Path, flutter_version: str) -> list[str]:
    if flutter_version != EXPECTED_FLUTTER:
        return [f"Flutter must be exactly {EXPECTED_FLUTTER}; got {flutter_version!r}"]
    for path, label in ((pubspec, 'pubspec.yaml'), (lockfile, 'pubspec.lock')):
        if path.is_symlink():
            return [f"{label} must not be a symbolic link: {path}"]
        try:
            if not path.is_file() or path.stat().st_size == 0:
                return [f"{label} is missing or empty: {path}"]
        except OSError as exc:
            return [f"{label} could not be inspected: {path}: {exc}"]
    if output.is_symlink():
        return [f"lockfile provenance output must not be a symbolic link: {output}"]

    try:
        content = (
            f"flutter={flutter_version}\n"
            f"pubspec_sha256={sha256(pubspec)}\n"
            f"lockfile_sha256={sha256(lockfile)}\n"
        )
        # Write beside the destination and atomically replace it. This avoids
        # leaving a truncated provenance file if the process/disk fails mid-write.
        fd, temp_name = tempfile.mkstemp(prefix=f".{output.name}.", dir=output.parent)
        temp_path = Path(temp_name)
        try:
            with os.fdopen(fd, 'w', encoding='utf-8', newline='\n') as handle:
                handle.write(content)
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(temp_path, output)
        finally:
            temp_path.unlink(missing_ok=True)
    except OSError as exc:
        return [f"lockfile provenance could not be written atomically: {exc}"]
    return verify(pubspec, lockfile, output)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--pubspec', type=Path, default=Path('pubspec.yaml'))
    p.add_argument('--lockfile', type=Path, default=Path('pubspec.lock'))
    p.add_argument('--output', type=Path, default=Path('lockfile-provenance.txt'))
    p.add_argument('--flutter-version', required=True)
    a = p.parse_args()
    errors = write(a.pubspec, a.lockfile, a.output, a.flutter_version)
    if errors:
        for error in errors: print(f"- {error}")
        return 1
    print('LOCKFILE PROVENANCE WRITE: OK')
    return 0
if __name__ == '__main__': raise SystemExit(main())
