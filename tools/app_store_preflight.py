#!/usr/bin/env python3
"""Fail-closed source preflight for SNIPER TÜRK iOS/App Store release readiness.

This does not replace Xcode archive, Simulator/device testing, App Store Connect
metadata, privacy answers, signing, or App Review. It only makes source-side
release blockers explicit and machine-checkable.
"""
from __future__ import annotations
import argparse, hashlib, ipaddress, json, plistlib, re, sys
from xml.parsers.expat import ExpatError
from pathlib import Path
from urllib.parse import urlparse

from verify_ios_privacy_manifests import ALLOWED_REASONS, _manifest_problem

PLACEHOLDERS = ("example.com", "replace-me", "todo", "tbd", "your-domain")
RESERVED_HOSTS = {"localhost"}
RESERVED_TLDS = (".test", ".invalid", ".example", ".localhost")
EXPECTED_IOS_BUNDLE_ID = "com.sniperturk.sniperTurk"
EXPECTED_RELEASE_VERSION = "1.0.0"
EXPECTED_MIN_IOS = (15, 0)


def _is_public_https_url(value: str) -> bool:
    """Validate URL shape without pretending to prove network reachability."""
    try:
        parsed = urlparse(value)
        host = (parsed.hostname or "").rstrip(".").lower()
        if parsed.scheme != "https" or not host or parsed.username or parsed.password:
            return False
        if host in RESERVED_HOSTS or host.endswith(RESERVED_TLDS):
            return False
        if "." not in host:
            return False
        try:
            ip = ipaddress.ip_address(host)
        except ValueError:
            # Conservative hostname syntax check. DNS/reachability is an external gate.
            labels = host.split(".")
            if any(not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label) for label in labels):
                return False
        else:
            if not ip.is_global:
                return False
        return True
    except ValueError:
        return False


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return ""


def _sha256_file(path: Path) -> str | None:
    """Hash a release input without allowing an I/O race to crash preflight."""
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError:
        return None


def _symlink_component(path: Path, base: Path) -> Path | None:
    """Return the first symlink from base through path without resolving it."""
    try:
        relative = path.relative_to(base)
    except ValueError:
        return path
    current = base
    if current.is_symlink():
        return current
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            return current
    return None


def check(root: Path, privacy_url: str | None) -> list[str]:
    errors: list[str] = []
    pubspec_path = root / "pubspec.yaml"
    if pubspec_path.is_symlink():
        errors.append("pubspec.yaml must be a regular file, not a symbolic link")
        pubspec = ""
    else:
        pubspec = _read(pubspec_path)
    if not pubspec:
        errors.append("pubspec.yaml is missing or unreadable")
    else:
        m = re.search(r"(?m)^version:\s*([^\s]+)\s*$", pubspec)
        if not m:
            errors.append("pubspec version is missing")
        elif not re.fullmatch(r"\d+\.\d+\.\d+\+[1-9]\d*", m.group(1)):
            errors.append("pubspec version must use semver+positive-build, e.g. 1.0.0+1")
        else:
            marketing, build = m.group(1).split("+", 1)
            if marketing != EXPECTED_RELEASE_VERSION:
                errors.append(f"V1 release version must be {EXPECTED_RELEASE_VERSION}+<positive build>, got {m.group(1)}")

    # A committed lockfile is required for a reproducible application release.
    # Never synthesize it: it must come from the pinned Flutter/Dart resolver.
    lockfile = root / "pubspec.lock"
    if lockfile.is_symlink():
        errors.append("pubspec.lock must be a regular file, not a symbolic link")
    if lockfile.is_symlink() or not lockfile.is_file() or not _read(lockfile).strip():
        errors.append("pubspec.lock is missing or empty; run flutter pub get with the pinned Flutter toolchain and commit the generated lockfile")
    else:
        # A lockfile by itself is not enough: bind the App Store preflight to
        # the same provenance contract used by CI/local verification. This
        # prevents a hand-edited or differently-resolved lockfile from being
        # accepted merely because the file exists.
        provenance = root / "lockfile-provenance.txt"
        if provenance.is_symlink():
            errors.append("lockfile provenance must be a regular file, not a symbolic link")
        if provenance.is_symlink() or not provenance.is_file() or not _read(provenance).strip():
            errors.append("lockfile provenance is missing or empty; generate it with the pinned Flutter 3.47.2 resolver")
        else:
            values = {}
            malformed = False
            for raw in _read(provenance).splitlines():
                if not raw or "=" not in raw:
                    malformed = True
                    continue
                key, value = raw.split("=", 1)
                if key in values:
                    malformed = True
                values[key] = value
            expected_keys = {"flutter", "pubspec_sha256", "lockfile_sha256"}
            if malformed or set(values) != expected_keys:
                errors.append("lockfile provenance is malformed or has unexpected keys")
            else:
                if values["flutter"] != "3.47.2":
                    errors.append("lockfile provenance must declare Flutter 3.47.2")
                pubspec_digest = _sha256_file(pubspec_path)
                lockfile_digest = _sha256_file(lockfile)
                if (
                    not pubspec
                    or pubspec_path.is_symlink()
                    or not pubspec_path.is_file()
                    or pubspec_digest is None
                    or values["pubspec_sha256"] != pubspec_digest
                ):
                    errors.append("pubspec.yaml does not match lockfile provenance")
                if lockfile_digest is None or values["lockfile_sha256"] != lockfile_digest:
                    errors.append("pubspec.lock does not match lockfile provenance")

    fvmrc = root / ".fvmrc"
    if fvmrc.is_symlink():
        errors.append(".fvmrc must be a regular file, not a symbolic link")
        fvmrc_text = ""
    else:
        fvmrc_text = _read(fvmrc)
    if not fvmrc_text:
        errors.append(".fvmrc is missing or unreadable; Flutter release toolchain is not pinned")
    else:
        try:
            fvmrc_payload = json.loads(fvmrc_text)
        except json.JSONDecodeError:
            errors.append(".fvmrc must be valid JSON and pin Flutter 3.47.2")
        else:
            if not isinstance(fvmrc_payload, dict):
                errors.append(".fvmrc must be a JSON object that pins Flutter 3.47.2")
            elif fvmrc_payload.get("flutter") != "3.47.2":
                errors.append(".fvmrc must pin Flutter 3.47.2 to match the iOS bootstrap contract")

    tools_dir = root / "tools"
    if tools_dir.is_symlink():
        errors.append("tools must be a real directory, not a symbolic link")

    bootstrap = tools_dir / "bootstrap_ios_scaffold.sh"
    if bootstrap.is_symlink():
        errors.append("tools/bootstrap_ios_scaffold.sh must be a regular file, not a symbolic link")
    elif not bootstrap.is_file():
        errors.append("tools/bootstrap_ios_scaffold.sh is missing")

    # Validate the app-owned privacy manifest *before* Flutter/Xcode work.
    # The archive gate remains authoritative for the built product, but a
    # malformed or semantically empty source template should fail fast instead
    # of consuming a macOS build only to be rejected after archive creation.
    release_dir = root / "release"
    release_ios_dir = release_dir / "ios"
    if release_dir.is_symlink():
        errors.append("release must be a real directory, not a symbolic link")
    if release_ios_dir.is_symlink():
        errors.append("release/ios must be a real directory, not a symbolic link")

    privacy_manifest = release_ios_dir / "PrivacyInfo.xcprivacy"
    if privacy_manifest.is_symlink():
        errors.append("release/ios/PrivacyInfo.xcprivacy must be a regular file, not a symbolic link")
    elif not privacy_manifest.is_file():
        errors.append("release/ios/PrivacyInfo.xcprivacy is missing")
    else:
        try:
            with privacy_manifest.open("rb") as fh:
                privacy_payload = plistlib.load(fh)
            problem = _manifest_problem(privacy_payload)
            if problem:
                errors.append(f"source iOS privacy manifest is invalid: {problem}")
            else:
                recognized = False
                for entry in privacy_payload.get("NSPrivacyAccessedAPITypes") or []:
                    allowed = ALLOWED_REASONS.get(entry["NSPrivacyAccessedAPIType"])
                    if allowed and any(
                        reason in allowed
                        for reason in entry["NSPrivacyAccessedAPITypeReasons"]
                    ):
                        recognized = True
                        break
                if not recognized:
                    errors.append(
                        "source iOS privacy manifest contains no recognized "
                        "required-reason API declaration"
                    )
        except Exception as exc:
            errors.append(
                "source iOS privacy manifest is unreadable or invalid: "
                f"{type(exc).__name__}"
            )

    # A privacy-policy URL is mandatory App Store metadata. Never invent one.
    if not privacy_url:
        errors.append("privacy policy URL is not configured (pass --privacy-url)")
    else:
        lowered = privacy_url.lower()
        if not _is_public_https_url(privacy_url):
            errors.append("privacy policy URL must use a syntactically public HTTPS host (not localhost, private IP, or reserved test domain)")
        elif any(p in lowered for p in PLACEHOLDERS):
            errors.append("privacy policy URL contains a placeholder")

    ios = root / "ios"
    # Reject a substituted iOS tree, not only symlinked leaf files. Checking
    # children with is_file() follows a symlinked parent directory, which could
    # otherwise make an external/untrusted scaffold appear source-owned.
    if ios.is_symlink():
        errors.append("ios must be a real directory, not a symbolic link")
    if not ios.is_dir() and not ios.is_symlink():
        errors.append("iOS scaffold is absent; generate it with the pinned Flutter toolchain")
    else:
        # Keep source preflight aligned with the bootstrap contract. A partial
        # ios/ tree can otherwise look release-ready here but fail immediately
        # when Flutter/Xcode consumes the workspace or build configurations.
        required = [
            ios / "Runner.xcodeproj" / "project.pbxproj",
            ios / "Runner.xcworkspace" / "contents.xcworkspacedata",
            ios / "Runner" / "Info.plist",
            ios / "Runner" / "AppDelegate.swift",
            ios / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json",
            ios / "Flutter" / "Debug.xcconfig",
            ios / "Flutter" / "Release.xcconfig",
        ]
        unsafe_required: set[Path] = set()
        for path in required:
            symlink = _symlink_component(path, ios)
            if symlink is not None:
                unsafe_required.add(path)
                if symlink == path:
                    errors.append(
                        "required iOS release file must be a regular file, not a symbolic link: "
                        f"{path.relative_to(root)}"
                    )
                else:
                    errors.append(
                        "required iOS release path must not contain symbolic links: "
                        f"{path.relative_to(root)} (via {symlink.relative_to(root)})"
                    )
            elif not path.is_file():
                errors.append(f"required iOS release file missing: {path.relative_to(root)}")

        # Keep the App Store identity deterministic. The bootstrap already
        # generates this identifier, but preflight must also reject a manually
        # modified or stale Xcode project instead of trusting bootstrap history.
        pbxproj = ios / "Runner.xcodeproj" / "project.pbxproj"
        if pbxproj.is_file() and pbxproj not in unsafe_required:
            pbx_text = _read(pbxproj)
            bundle_ids = set(re.findall(r"PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;\s]+)\s*;", pbx_text))
            allowed_bundle_ids = {EXPECTED_IOS_BUNDLE_ID, f"{EXPECTED_IOS_BUNDLE_ID}.RunnerTests"}
            if EXPECTED_IOS_BUNDLE_ID not in bundle_ids:
                errors.append(f"iOS Runner bundle identifier must be {EXPECTED_IOS_BUNDLE_ID}")
            unexpected = sorted(bundle_ids - allowed_bundle_ids)
            if unexpected:
                errors.append("unexpected iOS bundle identifier(s): " + ", ".join(unexpected))

            # Keep the deployment target deterministic across Runner/test build
            # configurations. A stale target can pass source checks but later
            # break plugin compatibility or App Store archive behavior.
            raw_targets = re.findall(r"IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([^;\s]+)\s*;", pbx_text)
            if not raw_targets:
                errors.append("iOS deployment target is missing from project.pbxproj")
            else:
                parsed_targets = []
                invalid_targets = []
                for raw in raw_targets:
                    m = re.fullmatch(r"(\d+)(?:\.(\d+))?", raw)
                    if not m:
                        invalid_targets.append(raw)
                    else:
                        parsed_targets.append((int(m.group(1)), int(m.group(2) or 0)))
                if invalid_targets:
                    errors.append("invalid iOS deployment target(s): " + ", ".join(sorted(set(invalid_targets))))
                if parsed_targets and any(target < EXPECTED_MIN_IOS for target in parsed_targets):
                    errors.append("iOS deployment target must be at least 15.0 for all build configurations")

        info_plist = ios / "Runner" / "Info.plist"
        if info_plist.is_file() and info_plist not in unsafe_required:
            try:
                with info_plist.open("rb") as f:
                    info = plistlib.load(f)
                if info.get("CFBundleDisplayName") != "SNIPER TÜRK":
                    errors.append("iOS CFBundleDisplayName must be SNIPER TÜRK")
                if info.get("ITSAppUsesNonExemptEncryption") is not False:
                    errors.append("iOS ITSAppUsesNonExemptEncryption must be explicitly false for the current V1 export-compliance contract")

                # Fail closed if source starts using a protected iOS capability
                # without the corresponding purpose string. Static source
                # scanning cannot prove runtime behavior, but it catches the
                # common release-crash/review failure where a plugin/API is
                # referenced and Info.plist was never updated.
                dart_bases = (root / "lib", root / "integration_test")
                # A symlinked directory can hide Dart sources from rglob() and
                # therefore bypass capability/purpose-string detection entirely.
                # Reject any symlink in the scanned source trees, not only .dart
                # leaf files. This also prevents source from escaping the project.
                symlinked_scan_paths = [
                    path
                    for base in dart_bases
                    if base.exists()
                    for path in ([base] if base.is_symlink() else base.rglob("*"))
                    if path.is_symlink()
                ]
                for path in symlinked_scan_paths:
                    errors.append(
                        "Dart capability scan path must not contain symbolic links: "
                        f"{path.relative_to(root)}"
                    )
                dart_files = [path for base in dart_bases if base.is_dir() and not base.is_symlink() for path in base.rglob("*.dart")]
                # Do not follow source-file symlinks during a release capability
                # scan. A symlink can escape the project tree or make preflight
                # inspect content that is not actually committed with the app.
                # Treat it as a release blocker instead of silently trusting it.
                symlinked_dart = [path for path in dart_files if path.is_symlink()]
                if symlinked_dart:
                    for path in symlinked_dart:
                        errors.append(
                            "Dart capability scan source must be a regular file, not a symbolic link: "
                            f"{path.relative_to(root)}"
                        )
                regular_dart = [path for path in dart_files if not path.is_symlink()]
                source_parts = [_read(path) for path in regular_dart]
                unreadable = False
                for path, part in zip(regular_dart, source_parts):
                    try:
                        if not part and path.stat().st_size:
                            unreadable = True
                    except OSError:
                        unreadable = True
                if unreadable:
                    errors.append("Dart capability scan contains unreadable source files")
                source_text = "\n".join(source_parts).lower()
                capability_markers = {
                    "NSCameraUsageDescription": ("camera", "image_picker", "cameracontroller"),
                    "NSMicrophoneUsageDescription": ("microphone", "permission.microphone", "audiorecorder", "record("),
                    "NSLocationWhenInUseUsageDescription": ("geolocator", "geocoding", "locationpermission", "permission.location"),
                    "NSPhotoLibraryUsageDescription": ("image_picker", "photolibrary", "permission.photos"),
                    "NSMotionUsageDescription": ("sensors_plus", "accelerometerevent", "motionmanager"),
                }
                for key, markers in capability_markers.items():
                    if any(marker in source_text for marker in markers):
                        value = info.get(key)
                        if not isinstance(value, str) or not value.strip():
                            errors.append(f"iOS {key} is required by detected source capability and must be a non-empty purpose string")
            except (OSError, UnicodeError, ValueError, TypeError, ExpatError, plistlib.InvalidFileException):
                errors.append("iOS Info.plist is unreadable or invalid")

    return errors


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument("--privacy-url")
    args = p.parse_args()
    errors = check(args.root.resolve(), args.privacy_url)
    if errors:
        print("APP STORE PREFLIGHT: BLOCKED")
        for e in errors:
            print(f"- {e}")
        return 1
    print("APP STORE PREFLIGHT: SOURCE CHECKS PASS")
    print("Xcode archive, signing, Simulator/device tests and App Store Connect checks are still required.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
