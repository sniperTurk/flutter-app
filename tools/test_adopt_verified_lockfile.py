#!/usr/bin/env python3
from pathlib import Path
import hashlib
import tempfile
import unittest
from unittest.mock import patch

from adopt_verified_lockfile import adopt


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class AdoptVerifiedLockfileTest(unittest.TestCase):
    def fixture(self):
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        project = root / "project"
        artifact = root / "artifact"
        project.mkdir(); artifact.mkdir()
        pub = b"name: sniper_turk\n"
        lock = b"packages:\n  demo: {}\n"
        (project / "pubspec.yaml").write_bytes(pub)
        (artifact / "pubspec.lock").write_bytes(lock)
        (artifact / "lockfile-provenance.txt").write_text(
            f"flutter=3.47.2\npubspec_sha256={digest(pub)}\nlockfile_sha256={digest(lock)}\n",
            encoding="utf-8",
        )
        return temp, project, artifact, lock

    def test_second_stage_copy_failure_cleans_both_temporary_files(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            import shutil
            real_copy = shutil.copyfile
            calls = 0

            def fail_second_copy(source, destination, *args, **kwargs):
                nonlocal calls
                calls += 1
                if calls == 2:
                    Path(destination).write_bytes(b"PARTIAL-SECRET")
                    raise OSError("injected disk write failure")
                return real_copy(source, destination, *args, **kwargs)

            with patch("adopt_verified_lockfile.shutil.copyfile", side_effect=fail_second_copy):
                errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertIn("injected disk write failure", errors[0])
            self.assertFalse((project / "pubspec.lock").exists())
            self.assertFalse((project / "lockfile-provenance.txt").exists())
            self.assertEqual([], [p.name for p in project.iterdir() if p.name.startswith(".")])

    def test_symlinked_artifact_lock_is_rejected_without_touching_project(self):
        temp, project, artifact, lock = self.fixture()
        with temp:
            real = artifact / "real.lock"
            real.write_bytes(lock)
            (artifact / "pubspec.lock").unlink()
            (artifact / "pubspec.lock").symlink_to(real)
            errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertIn("not a symlink", errors[0])
            self.assertFalse((project / "pubspec.lock").exists())

    def test_symlinked_artifact_provenance_is_rejected_without_touching_project(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            real = artifact / "real.provenance"
            real.write_bytes((artifact / "lockfile-provenance.txt").read_bytes())
            (artifact / "lockfile-provenance.txt").unlink()
            (artifact / "lockfile-provenance.txt").symlink_to(real)
            errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertIn("not a symlink", errors[0])
            self.assertFalse((project / "pubspec.lock").exists())

    def test_existing_project_symlink_destination_is_rejected_and_preserved(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            target = project / "outside.lock"
            target.write_bytes(b"DO-NOT-TOUCH\n")
            (project / "pubspec.lock").symlink_to(target)
            errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertIn("must not be a symlink", errors[0])
            self.assertTrue((project / "pubspec.lock").is_symlink())
            self.assertEqual(b"DO-NOT-TOUCH\n", target.read_bytes())

    def test_valid_artifact_is_adopted(self):
        temp, project, artifact, lock = self.fixture()
        with temp:
            self.assertEqual([], adopt(project, artifact))
            self.assertEqual(lock, (project / "pubspec.lock").read_bytes())
            self.assertTrue((project / "lockfile-provenance.txt").is_file())
            self.assertIn(f"lockfile_sha256={digest(lock)}", (project / "lockfile-provenance.txt").read_text())

    def test_stale_source_is_rejected_without_overwriting_existing_lock(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            old = b"old-lock\n"
            (project / "pubspec.lock").write_bytes(old)
            (project / "pubspec.yaml").write_text("name: changed\n", encoding="utf-8")
            self.assertTrue(adopt(project, artifact))
            self.assertEqual(old, (project / "pubspec.lock").read_bytes())
            self.assertFalse((project / "lockfile-provenance.txt").exists())

    def test_tampered_artifact_is_rejected(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (artifact / "pubspec.lock").write_text("tampered\n", encoding="utf-8")
            self.assertTrue(adopt(project, artifact))
            self.assertFalse((project / "pubspec.lock").exists())

    def test_missing_provenance_is_rejected(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (artifact / "lockfile-provenance.txt").unlink()
            self.assertTrue(adopt(project, artifact))
            self.assertFalse((project / "pubspec.lock").exists())

    # --- v203: a failure installing the SECOND file must not leave the FIRST
    # file adopted, must not crash, and must not leak temp files. Reproduces
    # the exact defect found in v202: os.replace() for pubspec.lock succeeded,
    # then os.replace() for lockfile-provenance.txt raised IsADirectoryError
    # uncaught, leaving pubspec.lock silently updated with no matching
    # provenance and a raw traceback instead of a clean BLOCKED result. ---

    def test_second_file_replace_failure_rolls_back_the_first_with_prior_content(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (project / "pubspec.lock").write_bytes(b"OLD-LOCK\n")
            (project / "lockfile-provenance.txt").write_text("old=1\n", encoding="utf-8")
            (project / "lockfile-provenance.txt").unlink()
            (project / "lockfile-provenance.txt").mkdir()  # forces os.replace() to raise
            errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertNotIn("Traceback", "\n".join(errors))
            self.assertEqual(b"OLD-LOCK\n", (project / "pubspec.lock").read_bytes())
            self.assertTrue((project / "lockfile-provenance.txt").is_dir())

    def test_second_file_replace_failure_on_first_ever_adoption_leaves_no_orphan(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (project / "lockfile-provenance.txt").mkdir()  # forces the 2nd replace to fail
            errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertFalse((project / "pubspec.lock").exists(), "first file must not be left orphaned")

    def test_failed_adoption_leaves_no_temp_files_behind(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (project / "lockfile-provenance.txt").mkdir()
            adopt(project, artifact)
            leftovers = [p.name for p in project.iterdir() if p.name.startswith(".")]
            self.assertEqual([], leftovers)

    def test_adopt_never_raises_on_a_filesystem_failure(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            (project / "lockfile-provenance.txt").mkdir()
            try:
                adopt(project, artifact)
            except OSError:
                self.fail("adopt() must report filesystem failures as errors, not raise")

    def test_cli_reports_a_clean_blocked_message_with_no_traceback(self):
        import subprocess
        import sys
        temp, project, artifact, _ = self.fixture()
        with temp:
            (project / "lockfile-provenance.txt").mkdir()
            script = Path(__file__).with_name("adopt_verified_lockfile.py")
            result = subprocess.run(
                [sys.executable, str(script), str(artifact), "--project-root", str(project)],
                capture_output=True, text=True,
            )
            self.assertEqual(1, result.returncode)
            self.assertNotIn("Traceback", result.stderr)
            self.assertIn("LOCKFILE ADOPTION: BLOCKED", result.stderr)

    # --- v204: final installed-pair verification is part of the transaction.
    # If it fails, the pre-existing pair must be restored before returning. ---

    def test_post_install_verification_failure_rolls_back_existing_pair(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            old_lock = b"OLD-LOCK\n"
            old_provenance = "old=1\n"
            (project / "pubspec.lock").write_bytes(old_lock)
            (project / "lockfile-provenance.txt").write_text(old_provenance, encoding="utf-8")
            with patch("adopt_verified_lockfile.verify", side_effect=[[], ["simulated post-install mismatch"]]):
                errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertIn("installed pair failed verification", errors[0])
            self.assertEqual(old_lock, (project / "pubspec.lock").read_bytes())
            self.assertEqual(old_provenance, (project / "lockfile-provenance.txt").read_text(encoding="utf-8"))

    def test_failed_rollback_preserves_original_backup_for_recovery(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            old_lock = b"OLD-LOCK\n"
            old_provenance = "old=1\n"
            (project / "pubspec.lock").write_bytes(old_lock)
            (project / "lockfile-provenance.txt").write_text(old_provenance, encoding="utf-8")

            real_replace = __import__("os").replace
            calls = {"count": 0}

            def fail_first_rollback(src, dst):
                calls["count"] += 1
                # Two installs succeed. The first rollback (provenance, because
                # rollback is reverse-order) succeeds; the second rollback for
                # pubspec.lock fails, simulating a disk/filesystem error.
                if calls["count"] == 4:
                    raise OSError("simulated rollback failure")
                return real_replace(src, dst)

            with patch("adopt_verified_lockfile.verify", side_effect=[[], ["simulated post-install mismatch"]]), \
                 patch("adopt_verified_lockfile.os.replace", side_effect=fail_first_rollback):
                errors = adopt(project, artifact)

            self.assertTrue(errors)
            self.assertIn("rollback incomplete", errors[0])
            self.assertIn("original preserved at", errors[0])
            backups = list(project.glob(".pubspec.lock.backup.*"))
            self.assertEqual(1, len(backups), "failed rollback must preserve the only recovery copy")
            self.assertEqual(old_lock, backups[0].read_bytes())

    def test_both_rollbacks_fail_preserves_both_original_backups(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            old_lock = b"OLD-LOCK\n"
            old_provenance = "old=1\n"
            (project / "pubspec.lock").write_bytes(old_lock)
            (project / "lockfile-provenance.txt").write_text(old_provenance, encoding="utf-8")

            real_replace = __import__("os").replace
            calls = {"count": 0}

            def fail_both_rollbacks(src, dst):
                calls["count"] += 1
                # Calls 1-2 install the staged pair.  Rollback is reverse-order:
                # calls 3-4 restore provenance then pubspec.lock.  Fail both.
                if calls["count"] in (3, 4):
                    raise OSError(f"simulated rollback failure {calls['count']}")
                return real_replace(src, dst)

            with patch("adopt_verified_lockfile.verify", side_effect=[[], ["simulated post-install mismatch"]]), \
                 patch("adopt_verified_lockfile.os.replace", side_effect=fail_both_rollbacks):
                errors = adopt(project, artifact)

            self.assertTrue(errors)
            message = errors[0]
            self.assertIn("rollback incomplete", message)
            self.assertEqual(2, message.count("original preserved at"))
            lock_backups = list(project.glob(".pubspec.lock.backup.*"))
            provenance_backups = list(project.glob(".lockfile-provenance.txt.backup.*"))
            self.assertEqual(1, len(lock_backups))
            self.assertEqual(1, len(provenance_backups))
            self.assertEqual(old_lock, lock_backups[0].read_bytes())
            self.assertEqual(old_provenance, provenance_backups[0].read_text(encoding="utf-8"))
            self.assertIn(str(lock_backups[0]), message)
            self.assertIn(str(provenance_backups[0]), message)

    def test_post_install_verification_failure_on_first_adoption_leaves_no_pair(self):
        temp, project, artifact, _ = self.fixture()
        with temp:
            with patch("adopt_verified_lockfile.verify", side_effect=[[], ["simulated post-install mismatch"]]):
                errors = adopt(project, artifact)
            self.assertTrue(errors)
            self.assertFalse((project / "pubspec.lock").exists())
            self.assertFalse((project / "lockfile-provenance.txt").exists())
            self.assertEqual([], [p.name for p in project.iterdir() if p.name.startswith(".")])


if __name__ == "__main__":
    unittest.main()
