#!/usr/bin/env python3
"""Fail closed when an iOS archive contains no valid privacy manifest.

Apple's required-reason API declarations can be supplied by the app or embedded
frameworks/plugins. This verifier inspects the *built archive*, not source
assumptions, and only trusts manifests inside the built
``Products/Applications/Runner.app`` payload (never dSYMs or other archive
folders). It requires:

* every manifest to be a parseable plist dictionary (any parse failure, not just
  ``InvalidFileException``, is reported as an invalid manifest);
* every declared required-reason entry to be well formed: a dict whose reasons
  are a list of strings shaped like Apple reason codes (for example ``CA92.1``),
  so a junk value cannot ride along next to a real code;
* at least one recognized category/reason pair used by this application's
  dependency contract (``NSPrivacyAccessedAPICategoryUserDefaults`` / ``CA92.1``).

It does not claim App Review compliance. By default the app's own top-level
``Runner.app/PrivacyInfo.xcprivacy`` is reported as a warning when absent;
pass ``--require-runner-manifest`` to make that an error once the project
ships its own manifest.
"""
from __future__ import annotations
import argparse, plistlib, re, sys
from pathlib import Path

# Known category/reason pairs used by this application dependency set.
ALLOWED_REASONS = {
    "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
}
# Apple required-reason codes look like CA92.1 / 1C8F.1 / C56D.1 / 35F9.1.
REASON_CODE_SHAPE = re.compile(r"^[0-9A-Z]{4}\.[0-9]$")


def _manifest_problem(payload: object) -> str | None:
    """Return a description when a parsed manifest is structurally malformed."""
    if not isinstance(payload, dict):
        return "root is not a dictionary"
    accessed = payload.get("NSPrivacyAccessedAPITypes")
    if accessed is None:
        return None
    if not isinstance(accessed, list):
        return "NSPrivacyAccessedAPITypes is not a list"
    for entry in accessed:
        if not isinstance(entry, dict):
            return "NSPrivacyAccessedAPITypes entry is not a dictionary"
        if not isinstance(entry.get("NSPrivacyAccessedAPIType"), str):
            return "required-reason entry has no NSPrivacyAccessedAPIType string"
        reasons = entry.get("NSPrivacyAccessedAPITypeReasons")
        if not isinstance(reasons, list):
            return "NSPrivacyAccessedAPITypeReasons is not a list"
        for reason in reasons:
            if not isinstance(reason, str) or not REASON_CODE_SHAPE.match(reason):
                return f"malformed required-reason code {reason!r}"
    return None


def warnings(archive: Path) -> list[str]:
    app_root = archive / "Products/Applications/Runner.app"
    if app_root.is_dir() and not (app_root / "PrivacyInfo.xcprivacy").is_file():
        return ["Runner.app has no top-level PrivacyInfo.xcprivacy; only embedded "
                "framework/plugin manifests were found. Ship an app manifest for the "
                "app's own required-reason API use, then enable --require-runner-manifest."]
    return []


def verify(archive: Path, require_runner_manifest: bool = False) -> list[str]:
    errors: list[str] = []
    if not archive.is_dir():
        return [f"iOS archive is missing: {archive}"]
    app_root = archive / "Products/Applications/Runner.app"
    if not app_root.is_dir():
        return [f"built Runner.app is missing from archive: {app_root}"]
    manifests = sorted(app_root.rglob("PrivacyInfo.xcprivacy"))
    if not manifests:
        return ["built Runner.app contains no PrivacyInfo.xcprivacy manifest"]
    if require_runner_manifest and not (app_root / "PrivacyInfo.xcprivacy").is_file():
        errors.append("Runner.app/PrivacyInfo.xcprivacy (the app's own manifest) is missing")

    valid_required_reason = False
    invalid: list[str] = []
    for manifest in manifests:
        rel = str(manifest.relative_to(archive))
        try:
            with manifest.open("rb") as fh:
                payload = plistlib.load(fh)
        except Exception as exc:  # ExpatError, ValueError, OSError, ... all fail closed
            invalid.append(f"{rel} ({type(exc).__name__})")
            continue
        problem = _manifest_problem(payload)
        if problem:
            invalid.append(f"{rel} ({problem})")
            continue
        for entry in payload.get("NSPrivacyAccessedAPITypes") or []:
            allowed = ALLOWED_REASONS.get(entry["NSPrivacyAccessedAPIType"])
            if allowed and any(r in allowed for r in entry["NSPrivacyAccessedAPITypeReasons"]):
                valid_required_reason = True
    if invalid:
        errors.append("invalid privacy manifest(s): " + ", ".join(invalid))
    if not valid_required_reason:
        errors.append("Runner.app privacy manifests contain no recognized required-reason API declaration")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path, default=Path("build/ios/archive/Runner.xcarchive"))
    parser.add_argument("--require-runner-manifest", action="store_true")
    args = parser.parse_args()
    errors = verify(args.archive, args.require_runner_manifest)
    if errors:
        print("IOS PRIVACY MANIFEST GATE: BLOCKED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("IOS PRIVACY MANIFEST GATE: PASS")
    for warning in warnings(args.archive):
        print(f"WARNING: {warning}")
    print("Archive contains valid required-reason API privacy metadata; App Review compliance still requires separate verification.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
