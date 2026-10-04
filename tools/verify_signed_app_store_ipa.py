#!/usr/bin/env python3
"""Fail-closed verification of an exported App Store IPA.

Requires macOS signing tools because provisioning profiles are CMS containers.
No credential or identity value is inferred: the expected Team ID is explicit.
"""
from __future__ import annotations
import argparse, datetime as dt, os, plistlib, re, shutil, subprocess, sys, tempfile, zipfile
from pathlib import Path

BUNDLE_ID = "com.sniperturk.sniperTurk"
TEAM_RE = re.compile(r"^[A-Z0-9]{10}$")

def fail(msg: str) -> None:
    raise SystemExit(msg)

def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, text=True, capture_output=True, check=False)

def safe_extract_zip(zf: zipfile.ZipFile, destination: Path) -> None:
    """Extract an IPA without allowing members to escape the temp root."""
    root = destination.resolve()
    for member in zf.infolist():
        name = member.filename
        # IPA members are POSIX paths. Reject absolute paths, parent traversal,
        # and backslashes so extraction semantics cannot vary by platform.
        if not name or name.startswith(("/", "\\")) or "\\" in name:
            fail(f"unsafe IPA zip member: {name!r}")
        parts = Path(name).parts
        if any(part in ("", ".", "..") for part in parts):
            fail(f"unsafe IPA zip member: {name!r}")
        target = (root / Path(*parts)).resolve()
        try:
            target.relative_to(root)
        except ValueError:
            fail(f"unsafe IPA zip member escapes extraction root: {name!r}")
    zf.extractall(root)

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ipa", required=True, type=Path)
    ap.add_argument("--team-id", required=True)
    ap.add_argument("--bundle-id", default=BUNDLE_ID)
    ns = ap.parse_args()
    if sys.platform != "darwin": fail("signed IPA verification requires macOS")
    if not TEAM_RE.fullmatch(ns.team_id): fail("invalid Apple Team ID")
    if not ns.ipa.is_file() or ns.ipa.stat().st_size == 0: fail("missing or empty IPA")
    for tool in ("codesign", "security"):
        if shutil.which(tool) is None: fail(f"required Apple tool missing: {tool}")
    with tempfile.TemporaryDirectory(prefix="sniper-turk-ipa-") as td:
        root = Path(td)
        try:
            with zipfile.ZipFile(ns.ipa) as zf: safe_extract_zip(zf, root)
        except (zipfile.BadZipFile, OSError) as exc: fail(f"invalid IPA zip: {exc}")
        apps = list((root / "Payload").glob("*.app"))
        if len(apps) != 1: fail(f"expected exactly one Payload/*.app, found {len(apps)}")
        app = apps[0]
        info = plistlib.loads((app / "Info.plist").read_bytes())
        if info.get("CFBundleIdentifier") != ns.bundle_id: fail("IPA bundle identifier mismatch")
        sig = run("codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app))
        if sig.returncode: fail("codesign verification failed: " + (sig.stderr or sig.stdout).strip())
        ent = run("codesign", "-d", "--entitlements", ":-", str(app))
        if ent.returncode: fail("cannot read signed entitlements")
        try: entitlements = plistlib.loads(ent.stdout.encode())
        except Exception as exc: fail(f"invalid signed entitlements: {exc}")
        expected_app_id = f"{ns.team_id}.{ns.bundle_id}"
        if entitlements.get("application-identifier") != expected_app_id: fail("signed application-identifier mismatch")
        if entitlements.get("com.apple.developer.team-identifier") != ns.team_id: fail("signed team identifier mismatch")
        profile = app / "embedded.mobileprovision"
        if not profile.is_file() or profile.stat().st_size == 0: fail("embedded.mobileprovision missing")
        decoded = root / "profile.plist"
        cms = run("security", "cms", "-D", "-i", str(profile))
        if cms.returncode: fail("cannot decode embedded provisioning profile")
        try: pp = plistlib.loads(cms.stdout.encode())
        except Exception as exc: fail(f"invalid provisioning profile plist: {exc}")
        teams = pp.get("TeamIdentifier") or []
        if ns.team_id not in teams: fail("provisioning profile TeamIdentifier mismatch")
        pent = pp.get("Entitlements") or {}
        if pent.get("application-identifier") != expected_app_id: fail("provisioning application-identifier mismatch")
        if pent.get("com.apple.developer.team-identifier") != ns.team_id: fail("provisioning team identifier mismatch")

        # A cryptographically valid development/ad-hoc profile is still not an
        # App Store distribution profile. Fail closed on release-only invariants
        # so an installable developer IPA cannot be mislabeled as the store
        # deliverable. Apple provisioning dates are decoded as datetime values.
        expiration = pp.get("ExpirationDate")
        if not isinstance(expiration, dt.datetime):
            fail("provisioning profile ExpirationDate missing or invalid")
        now = dt.datetime.now(dt.timezone.utc)
        if expiration.tzinfo is None:
            expiration = expiration.replace(tzinfo=dt.timezone.utc)
        if expiration <= now:
            fail("provisioning profile is expired")
        if pp.get("ProvisionedDevices"):
            fail("provisioning profile contains ProvisionedDevices; not App Store distribution")
        if pp.get("ProvisionsAllDevices") is True:
            fail("enterprise provisioning profile is not valid for App Store distribution")
        if entitlements.get("get-task-allow") is not False:
            fail("signed IPA permits debugging; get-task-allow must be false for App Store")
        if pent.get("get-task-allow") is not False:
            fail("provisioning profile permits debugging; get-task-allow must be false for App Store")
    print(f"SIGNED_APP_STORE_IPA_VERIFIED bundle={ns.bundle_id} team={ns.team_id}")
    return 0
if __name__ == "__main__": raise SystemExit(main())
