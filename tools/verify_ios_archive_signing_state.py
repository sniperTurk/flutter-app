#!/usr/bin/env python3
"""Fail closed if an iOS archive's signing state is not exactly as expected."""
from __future__ import annotations
import argparse
import plistlib
import subprocess
from pathlib import Path


def _bundle_id(app: Path) -> str:
    with (app / 'Info.plist').open('rb') as fh:
        return str(plistlib.load(fh).get('CFBundleIdentifier', ''))


def verify_unsigned(archive: Path, expected_bundle_id: str) -> None:
    app = archive / 'Products/Applications/Runner.app'
    if not app.is_dir():
        raise SystemExit(f'archive app missing: {app}')
    actual = _bundle_id(app)
    if actual != expected_bundle_id:
        raise SystemExit(f'unexpected bundle identifier: {actual!r}')
    embedded = app / 'embedded.mobileprovision'
    if embedded.exists():
        raise SystemExit('unsigned archive unexpectedly contains embedded.mobileprovision')
    proc = subprocess.run(
        ['codesign', '-d', '--entitlements', ':-', str(app)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    # `codesign -d` must fail for the deliberately unsigned archive. Accepting a
    # signed app here would let CI blur the distinction between source readiness
    # and an owner-authorized distribution artifact.
    if proc.returncode == 0:
        raise SystemExit('archive app is signed; expected deliberately unsigned archive')


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('--archive', type=Path, required=True)
    p.add_argument('--bundle-id', required=True)
    a = p.parse_args()
    verify_unsigned(a.archive, a.bundle_id)
    print('iOS archive signing state: verified unsigned')

if __name__ == '__main__':
    main()
