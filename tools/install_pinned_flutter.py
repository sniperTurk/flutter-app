#!/usr/bin/env python3
"""Install the Flutter version pinned in .fvmrc from Google's official archive.

This is a fallback for environments where github.com is blocked. It deliberately
uses the Flutter release manifest and verifies the archive SHA-256 before extract.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import shutil
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
import uuid
from pathlib import Path

MANIFESTS = {
    "linux": "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json",
    "darwin": "https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json",
}


def _platform_key(system: str | None = None) -> str:
    value = (system or platform.system()).lower()
    if value == "linux":
        return "linux"
    if value == "darwin":
        return "darwin"
    raise ValueError(f"unsupported host platform: {value}")


def _arch_candidates(machine: str | None = None) -> tuple[str, ...]:
    value = (machine or platform.machine()).lower()
    if value in {"arm64", "aarch64"}:
        return ("arm64", "aarch64")
    if value in {"x86_64", "amd64"}:
        return ("x64", "x86_64", "amd64")
    raise ValueError(f"unsupported host architecture: {value}")


def select_release(payload: dict, version: str, machine: str | None = None) -> dict:
    # The manifest is fetched over TLS from Google's official endpoint, but
    # treat its shape as untrusted input so release automation fails closed
    # with a deterministic diagnostic instead of an AttributeError/TypeError.
    if not isinstance(payload, dict):
        raise ValueError("official Flutter release manifest root must be an object")
    releases = payload.get("releases")
    if not isinstance(releases, list):
        raise ValueError("official Flutter release manifest releases must be a list")
    if any(not isinstance(release, dict) for release in releases):
        raise ValueError("official Flutter release manifest contains a non-object release entry")
    arch_names = _arch_candidates(machine)
    matches = [
        r for r in releases
        if r.get("version") == version and r.get("channel") == "stable"
    ]
    if not matches:
        raise ValueError(f"Flutter {version} stable is not present in the official release manifest")
    for release in matches:
        arch = str(release.get("dart_sdk_arch") or release.get("architecture") or "").lower()
        if not arch or arch in arch_names:
            return release
    raise ValueError(f"Flutter {version} stable has no archive for host architecture {machine or platform.machine()}")


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def _download(url: str, target: Path) -> None:
    with urllib.request.urlopen(url, timeout=60) as response, target.open("wb") as out:
        shutil.copyfileobj(response, out)


def _safe_extract_tar(tf: tarfile.TarFile, destination: Path) -> None:
    """Extract a trusted-hash archive without allowing filesystem escape.

    Hash verification proves the archive is the official artifact, but extraction
    still fails closed if a future/corrupted manifest ever points at an archive
    containing absolute paths, parent traversal, or escaping link targets.
    """
    root = destination.resolve()
    for member in tf.getmembers():
        name = member.name
        if not name or Path(name).is_absolute():
            raise ValueError(f"unsafe absolute/empty path in Flutter archive: {name!r}")
        target = (root / name).resolve()
        if target != root and root not in target.parents:
            raise ValueError(f"unsafe path traversal in Flutter archive: {name!r}")
        if member.issym() or member.islnk():
            link = Path(member.linkname)
            if link.is_absolute():
                raise ValueError(f"unsafe absolute link in Flutter archive: {name!r}")
            link_target = ((target.parent if member.issym() else root) / link).resolve()
            if link_target != root and root not in link_target.parents:
                raise ValueError(f"unsafe escaping link in Flutter archive: {name!r}")
    # Python 3.14 changes tarfile extraction defaults. We already validate every
    # member above, so request the legacy metadata-preserving behavior explicitly
    # instead of letting interpreter-version defaults silently change release SDK
    # extraction semantics.
    tf.extractall(root, filter="fully_trusted")


def _safe_extract_zip(zf: zipfile.ZipFile, destination: Path) -> None:
    """Extract ZIP archives only when every member stays below destination."""
    root = destination.resolve()
    for info in zf.infolist():
        name = info.filename
        # ZIP paths are POSIX-style even on Windows; reject both slash styles
        # so the policy remains fail-closed if this helper is reused there.
        normalized = name.replace("\\", "/")
        path = Path(normalized)
        if not name or path.is_absolute() or (len(normalized) >= 2 and normalized[1] == ":"):
            raise ValueError(f"unsafe absolute/empty path in Flutter ZIP archive: {name!r}")
        target = (root / path).resolve()
        if target != root and root not in target.parents:
            raise ValueError(f"unsafe path traversal in Flutter ZIP archive: {name!r}")
        # Unix symlinks can be represented in ZIP external attributes. Refuse
        # them entirely: the official Flutter ZIP does not require them and
        # following them would make later members capable of escaping root.
        mode = (info.external_attr >> 16) & 0o170000
        if mode == 0o120000:
            raise ValueError(f"unsafe symbolic link in Flutter ZIP archive: {name!r}")
    zf.extractall(root)


def _resolve_install_destination(destination: Path) -> Path:
    """Resolve an SDK destination without following a replaceable final symlink.

    The installer deletes an existing destination before moving the verified SDK
    into place.  Following a final-component symlink here would turn that delete
    into an arbitrary-directory removal outside the intended SDK location.
    Parent-directory symlinks remain supported (for example a symlinked home or
    workspace), but the destination itself must be a real directory/path.
    """
    lexical = destination.expanduser()
    if lexical.is_symlink():
        raise ValueError(f"Flutter install destination must not be a symbolic link: {lexical}")
    return lexical.resolve()


def _remove_path(path: Path) -> None:
    """Remove one filesystem entry without following symlinks."""
    if path.is_symlink() or (path.exists() and not path.is_dir()):
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def _replace_install_transactionally(source: Path, destination: Path) -> None:
    """Replace an existing SDK without losing it when the final move fails."""
    backup = destination.parent / f".{destination.name}.backup-{uuid.uuid4().hex}"
    had_existing = destination.exists()
    if had_existing:
        os.replace(destination, backup)
    try:
        shutil.move(str(source), str(destination))
    except Exception as install_exc:
        # shutil.move may have created a partial destination before failing.
        if destination.exists() or destination.is_symlink():
            try:
                _remove_path(destination)
            except OSError:
                # Preserve the original install exception; rollback below still
                # gets a chance to restore the previous SDK.
                pass
        if had_existing:
            try:
                os.replace(backup, destination)
            except Exception as rollback_exc:
                raise RuntimeError(
                    f"Flutter SDK replacement failed ({install_exc}); rollback also failed ({rollback_exc}); "
                    f"previous SDK remains at {backup}"
                ) from install_exc
        raise
    else:
        if had_existing:
            _remove_path(backup)


def install(version: str, destination: Path) -> None:
    host = _platform_key()
    manifest_url = MANIFESTS[host]
    with urllib.request.urlopen(manifest_url, timeout=30) as response:
        payload = json.load(response)
    release = select_release(payload, version)
    archive = release.get("archive")
    expected = str(release.get("sha256") or "").lower()
    base_url = str(payload.get("base_url") or "https://storage.googleapis.com/flutter_infra_release/releases").rstrip("/")
    if not archive or not expected:
        raise ValueError("official release entry is missing archive or sha256")
    url = f"{base_url}/{archive.lstrip('/')}"

    destination = _resolve_install_destination(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="sniper-turk-flutter-") as tmp:
        tmpdir = Path(tmp)
        archive_path = tmpdir / Path(archive).name
        print(f"Downloading Flutter {version} from official archive: {url}")
        _download(url, archive_path)
        actual = _sha256(archive_path)
        if actual != expected:
            raise ValueError(f"Flutter archive SHA-256 mismatch: expected {expected}, got {actual}")
        extract_root = tmpdir / "extract"
        extract_root.mkdir()
        if archive_path.suffix == ".zip":
            with zipfile.ZipFile(archive_path) as zf:
                _safe_extract_zip(zf, extract_root)
        elif archive_path.name.endswith((".tar.xz", ".tar.gz")):
            with tarfile.open(archive_path, "r:*") as tf:
                _safe_extract_tar(tf, extract_root)
        else:
            raise ValueError(f"unsupported Flutter archive format: {archive_path.name}")
        source = extract_root / "flutter"
        if not (source / "bin" / "flutter").exists():
            raise ValueError("downloaded archive does not contain flutter/bin/flutter")
        _replace_install_transactionally(source, destination)
    print(f"Flutter {version} installed at {destination}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--destination", required=True, type=Path)
    args = parser.parse_args()
    try:
        install(args.version, args.destination)
    except Exception as exc:
        print(f"OFFICIAL FLUTTER ARCHIVE INSTALL FAILED: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
