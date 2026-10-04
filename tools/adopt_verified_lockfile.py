#!/usr/bin/env python3
"""Adopt a generated pubspec.lock only after fail-closed provenance verification."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import sys
import tempfile

from verify_lockfile_provenance import verify


def _replace_pair_or_restore(project_root: Path, replacements: list[tuple[Path, Path]], post_verify=None) -> list[str]:
    """Replace every (temp_source, destination) pair, or restore prior state.

    Both destinations end up updated, or neither does. A destination that did
    not previously exist is removed again on rollback rather than left as a
    half-adopted new file.
    """
    backups: list[tuple[Path, Path, bool]] = []  # (destination, backup_path, existed)
    applied: list[Path] = []
    failure: str | None = None
    try:
        for _, destination in replacements:
            existed = destination.exists()
            if not existed:
                backups.append((destination, destination, False))
                continue
            fd, backup_name = tempfile.mkstemp(prefix=f".{destination.name}.backup.", dir=project_root)
            os.close(fd)
            backup_path = Path(backup_name)
            # Register for cleanup immediately: if the copy below fails (e.g.
            # `destination` turns out to be a directory), the temp file mkstemp
            # already created on disk must still be removed by the `finally`.
            backups.append((destination, backup_path, True))
            try:
                shutil.copyfile(destination, backup_path)
            except OSError as exc:
                failure = f"could not back up existing {destination.name} before adoption: {exc}"
                break

        if failure is None:
            for temp_source, destination in replacements:
                try:
                    os.replace(temp_source, destination)
                except OSError as exc:
                    failure = f"adoption failed while installing {destination.name}: {exc}"
                    break
                applied.append(destination)

        # Do not commit the filesystem transaction until the installed pair
        # itself has passed provenance verification.  v203 deleted backups
        # before this final verification, so a post-install verification
        # failure could still leave an invalid pair in the project root.
        if failure is None and post_verify is not None:
            verify_errors = post_verify()
            if verify_errors:
                failure = "installed pair failed verification: " + "; ".join(verify_errors)
    finally:
        # A failed rollback is materially different from a successful rollback:
        # the backup may be the only remaining copy of the user's pre-adoption
        # file. Never delete that recovery copy merely to make temp cleanup look
        # tidy. Keep it on disk and report its exact path in the error so a
        # human/CI artifact collector can recover the original state.
        preserved_backups: set[Path] = set()
        if failure is not None:
            rollback_errors: list[str] = []
            for destination, backup_path, existed in reversed(backups):
                if destination not in applied:
                    continue
                try:
                    if existed:
                        os.replace(backup_path, destination)
                    else:
                        destination.unlink(missing_ok=True)
                except OSError as exc:
                    if existed and backup_path != destination and backup_path.exists():
                        preserved_backups.add(backup_path)
                        rollback_errors.append(
                            f"could not roll back {destination.name}: {exc}; "
                            f"original preserved at {backup_path}"
                        )
                    else:
                        rollback_errors.append(f"could not roll back {destination.name}: {exc}")
            if rollback_errors:
                failure += "; rollback incomplete: " + "; ".join(rollback_errors)
        for destination, backup_path, existed in backups:
            if existed and backup_path != destination and backup_path not in preserved_backups:
                backup_path.unlink(missing_ok=True)
    return [failure] if failure else []


def adopt(project_root: Path, artifact_dir: Path) -> list[str]:
    project_root = project_root.resolve()
    artifact_dir = artifact_dir.resolve()
    pubspec = project_root / "pubspec.yaml"
    artifact_lock = artifact_dir / "pubspec.lock"
    provenance = artifact_dir / "lockfile-provenance.txt"

    # Adoption is a trust-boundary operation. Do not follow symlinks supplied
    # by an artifact bundle: otherwise a locally unpacked/untrusted bundle can
    # make verification and staging read a file outside artifact_dir.
    for path, label in ((artifact_lock, "pubspec.lock"), (provenance, "lockfile-provenance.txt")):
        if path.is_symlink():
            return [f"verified artifact {label} must be a regular file, not a symlink: {path}"]

    errors = verify(pubspec, artifact_lock, provenance)
    if errors:
        return errors

    destination = project_root / "pubspec.lock"
    provenance_destination = project_root / "lockfile-provenance.txt"

    # Likewise, never silently replace a project-root symlink. Besides being
    # surprising, backup via shutil.copyfile() follows the link and cannot
    # faithfully restore the original filesystem object on rollback.
    for path, label in ((destination, "pubspec.lock"), (provenance_destination, "lockfile-provenance.txt")):
        if path.is_symlink():
            return [f"project destination {label} must not be a symlink: {path}"]

    # Stage both verified files as new content first (cheap, and failure here
    # touches nothing in the project). Only then attempt to install the pair,
    # which is rolled back as a unit on any failure -- see
    # _replace_pair_or_restore. This never raises: every expected failure mode
    # (copy failure, full disk, a destination path that turns out to be a
    # directory, ...) is reported as a clean error list, matching every other
    # verifier in this project.
    staged: list[tuple[Path, Path]] = []
    try:
        for source, destination_path, prefix, label in (
            (artifact_lock, destination, ".pubspec.lock.", "lockfile"),
            (provenance, provenance_destination, ".lockfile-provenance.", "provenance"),
        ):
            fd, temp_name = tempfile.mkstemp(prefix=prefix, dir=project_root)
            os.close(fd)
            temp_path = Path(temp_name)
            # Register immediately: copyfile can fail after creating or partly
            # writing this file, and finally must still remove it.
            staged.append((temp_path, destination_path))
            shutil.copyfile(source, temp_path)
            if temp_path.stat().st_size == 0:
                return [f"verified artifact {label} became empty during adoption"]

        replace_errors = _replace_pair_or_restore(
            project_root,
            staged,
            post_verify=lambda: verify(pubspec, destination, provenance_destination),
        )
        if replace_errors:
            return replace_errors
    except OSError as exc:
        return [f"lockfile adoption failed: {exc}"]
    finally:
        for temp_path, _ in staged:
            temp_path.unlink(missing_ok=True)
    return []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact_dir", type=Path, help="Directory containing pubspec.lock and lockfile-provenance.txt")
    parser.add_argument("--project-root", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        errors = adopt(args.project_root, args.artifact_dir)
    except Exception as exc:  # belt-and-suspenders: adopt() should never raise, but
        errors = [f"unexpected adoption failure: {type(exc).__name__}: {exc}"]
    if errors:
        print("LOCKFILE ADOPTION: BLOCKED", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("LOCKFILE ADOPTION: OK — verified pubspec.lock + provenance installed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
