#!/usr/bin/env python3
"""Install the independently pinned trajectory validator from verified wheels.

Every wheel participating in reference-vector generation is selected from PyPI
metadata by the SHA-256 frozen in validation/acceptance.json, downloaded, hashed
again locally, then installed from the local wheel set with --no-index/--no-deps.
No resolver-selected network artifact is trusted implicitly.
"""
from __future__ import annotations

import hashlib
import importlib.metadata
import json
import os
import subprocess
import sys
import tempfile
import venv
import urllib.error
import urllib.request
import urllib.parse
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "validation" / "acceptance.json"
PYPI_JSON = "https://pypi.org/pypi/{package}/{version}/json"
PYPI_HOSTS = {"pypi.org", "files.pythonhosted.org"}


def _trusted_pypi_url(url: str) -> bool:
    parsed = urllib.parse.urlparse(url)
    try:
        port = parsed.port
    except ValueError:
        return False
    return (
        parsed.scheme == "https"
        and parsed.hostname in PYPI_HOSTS
        and port in (None, 443)
        and not parsed.username
        and not parsed.password
    )


class _TrustedPyPIRedirect(urllib.request.HTTPRedirectHandler):
    """Allow redirects only within the explicitly trusted PyPI HTTPS hosts."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not _trusted_pypi_url(newurl):
            raise urllib.error.HTTPError(
                req.full_url, code, f"untrusted PyPI redirect target: {newurl}", headers, fp
            )
        return super().redirect_request(req, fp, code, msg, headers, newurl)


_TRUSTED_OPENER = urllib.request.build_opener(_TrustedPyPIRedirect())


def _trusted_urlopen(url: str, timeout: int):
    if not _trusted_pypi_url(url):
        fail(f"refusing untrusted PyPI URL: {url}")
    return _TRUSTED_OPENER.open(url, timeout=timeout)


def fail(message: str) -> NoReturn:
    print(f"validator bootstrap FAILED: {message}", file=sys.stderr)
    raise SystemExit(2)


def _digest(value: object, label: str) -> str:
    if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
        fail(f"{label} must be a lowercase SHA-256 digest")
    return value


def _matching_wheel(package: str, version: str, expected_hash: str) -> dict:
    url = PYPI_JSON.format(package=package, version=version)
    try:
        with _trusted_urlopen(url, timeout=30) as response:
            metadata = json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
        fail(f"could not read PyPI metadata for {package}=={version}: {exc}")
    if not isinstance(metadata, dict):
        fail(f"invalid PyPI metadata for {package}=={version}")
    # Match the artifact by the cryptographic identity frozen in policy, not
    # by a guessed wheel tag.  Universal wheels legitimately use both
    # ``py3-none-any`` (typing-extensions) and ``py2.py3-none-any``
    # (Deprecated 1.2.18).  The old py3-only suffix filter therefore rejected
    # a correctly pinned dependency before its hash could even be verified.
    wheels = [
        f for f in metadata.get("urls", [])
        if f.get("packagetype") == "bdist_wheel"
        and f.get("filename", "").endswith(".whl")
        and f.get("digests", {}).get("sha256") == expected_hash
    ]
    if len(wheels) != 1:
        fail(f"PyPI metadata did not contain exactly one policy-matching wheel for {package}=={version}")
    return wheels[0]


def _download_verified(wheel: dict, expected_hash: str, directory: Path) -> Path:
    filename = wheel.get("filename")
    download_url = wheel.get("url")
    if not isinstance(filename, str) or not filename.endswith(".whl"):
        fail("PyPI wheel metadata is missing a valid filename")
    if not isinstance(download_url, str):
        fail(f"PyPI wheel metadata for {filename} is missing an HTTPS download URL")
    parsed = urllib.parse.urlparse(download_url)
    if parsed.scheme != "https" or parsed.hostname not in PYPI_HOSTS or parsed.username or parsed.password:
        fail(f"PyPI wheel metadata for {filename} points outside trusted PyPI artifact hosts")
    path = directory / filename
    try:
        with _trusted_urlopen(download_url, timeout=60) as response, path.open("wb") as out:
            while chunk := response.read(1024 * 1024):
                out.write(chunk)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        path.unlink(missing_ok=True)
        fail(f"could not download pinned wheel {filename}: {exc}")
    actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual_hash != expected_hash:
        fail(f"wheel hash mismatch for {path.name}: expected {expected_hash}, got {actual_hash}")
    return path



def _cached_verified(directory: Path, expected_hash: str, label: str) -> Path:
    """Return the unique cached wheel matching the policy hash, or fail closed."""
    if not directory.is_dir():
        fail(f"validator wheel cache is not a directory: {directory}")
    matches: list[Path] = []
    for path in directory.glob("*.whl"):
        try:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
        except OSError as exc:
            fail(f"could not read cached validator wheel {path}: {exc}")
        if digest == expected_hash:
            matches.append(path)
    if len(matches) != 1:
        fail(f"validator wheel cache did not contain exactly one policy-matching wheel for {label}")
    return matches[0]

def _read_policy(path: Path = POLICY) -> dict:
    """Read acceptance policy fail-closed, without leaking parser/IO tracebacks."""
    try:
        raw = path.read_text(encoding="utf-8")
        policy = json.loads(raw)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        fail(f"could not read acceptance policy: {exc}")
    if not isinstance(policy, dict):
        fail("acceptance policy root must be a JSON object")
    return policy


def main() -> None:
    policy = _read_policy()
    ref = policy.get("reference", {})
    package = ref.get("package")
    version = ref.get("version")
    expected_hash = _digest(ref.get("wheel_sha256"), "wheel_sha256")
    if not all(isinstance(v, str) and v for v in (package, version)):
        fail("acceptance policy is missing package/version")

    dependencies = ref.get("dependencies")
    if not isinstance(dependencies, dict) or not dependencies:
        fail("acceptance policy is missing pinned validator dependencies")
    locked: dict[str, tuple[str, str]] = {}
    for name, spec in dependencies.items():
        if not isinstance(name, str) or not name or not isinstance(spec, dict):
            fail("validator dependency locks must be package objects")
        dep_version = spec.get("version")
        if not isinstance(dep_version, str) or not dep_version:
            fail(f"validator dependency {name} is missing version")
        locked[name] = (dep_version, _digest(spec.get("wheel_sha256"), f"{name}.wheel_sha256"))

    cache_value = os.environ.get("SNIPER_TURK_VALIDATOR_WHEEL_DIR")
    if cache_value:
        cache = Path(cache_value).expanduser().resolve()
        artifacts = [_cached_verified(cache, expected_hash, f"{package}=={version}")]
        for name, (dep_version, dep_hash) in locked.items():
            artifacts.append(_cached_verified(cache, dep_hash, f"{name}=={dep_version}"))
        install_artifacts = artifacts
        temp_context = None
    else:
        temp_context = tempfile.TemporaryDirectory(prefix="sniper-turk-validator-")
        directory = Path(temp_context.name)
        artifacts = [_download_verified(_matching_wheel(package, version, expected_hash), expected_hash, directory)]
        for name, (dep_version, dep_hash) in locked.items():
            artifacts.append(_download_verified(_matching_wheel(name, dep_version, dep_hash), dep_hash, directory))
        install_artifacts = artifacts

    # Install into a project-local isolated virtual environment. Installing the
    # pinned validator into the runner's global interpreter can downgrade or
    # replace unrelated dependencies and, conversely, pre-existing newer
    # packages can make reference generation fail with dependency drift.
    venv_dir = ROOT / ".validator_venv"
    try:
        if venv_dir.exists():
            import shutil
            shutil.rmtree(venv_dir)
        venv.EnvBuilder(with_pip=True, clear=True).create(venv_dir)
        venv_python = venv_dir / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
        subprocess.run(
            [str(venv_python), "-m", "pip", "install", "--disable-pip-version-check", "--no-index", "--no-deps", *map(str, install_artifacts)],
            check=True,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        fail(f"could not create isolated validator environment: {exc}")
    finally:
        if temp_context is not None:
            temp_context.cleanup()

    # Verify versions inside the isolated interpreter rather than inspecting
    # the host process metadata. This makes bootstrap deterministic on CI and
    # developer machines that already contain newer dependencies.
    expected_versions = {package: version, **{name: spec[0] for name, spec in locked.items()}}
    verify_code = (
        "import importlib.metadata,json; "
        "names=" + repr(list(expected_versions)) + "; "
        "print(json.dumps({n:importlib.metadata.version(n) for n in names}))"
    )
    try:
        result = subprocess.run([str(venv_python), "-c", verify_code], check=True, capture_output=True, text=True)
        actual_versions = json.loads(result.stdout)
    except (subprocess.CalledProcessError, OSError, json.JSONDecodeError) as exc:
        fail(f"could not verify isolated validator environment: {exc}")
    for name, expected_version in expected_versions.items():
        if actual_versions.get(name) != expected_version:
            fail(f"validator package drift for {name}: expected {expected_version}, got {actual_versions.get(name)}")

    # Persist a machine-readable bootstrap receipt inside the isolated venv.
    # Reference generation requires this receipt, preventing a manually
    # assembled same-version environment from masquerading as hash-verified.
    receipt = {
        "schema": 1,
        "package": package,
        "version": version,
        "wheel_sha256": expected_hash,
        "dependencies": {
            name: {"version": dep_version, "wheel_sha256": dep_hash}
            for name, (dep_version, dep_hash) in locked.items()
        },
    }
    (venv_dir / "sniper_turk_validator_receipt.json").write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(f"installed {len(expected_versions)} hash-verified pinned validator wheels")


if __name__ == "__main__":
    main()
