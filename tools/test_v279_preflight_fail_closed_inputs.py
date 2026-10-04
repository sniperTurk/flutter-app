"""Regression guard: preflight returns blockers for corrupted release inputs."""
import hashlib
import os
import plistlib
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import app_store_preflight as preflight
URL = "https://policy.sniperturk.app/privacy"
PUBSPEC = "name: x\nversion: 1.0.0+1\n"
def write_provenance(root: Path, pubspec: bytes = PUBSPEC.encode(), lock: bytes = b"lock"):
    (root / "lockfile-provenance.txt").write_text(f"flutter=3.47.2\npubspec_sha256={hashlib.sha256(pubspec).hexdigest()}\nlockfile_sha256={hashlib.sha256(lock).hexdigest()}\n", encoding="utf-8")
def make_ios(root: Path):
    for rel in ("Runner.xcodeproj/project.pbxproj", "Runner.xcworkspace/contents.xcworkspacedata", "Runner/Info.plist", "Runner/AppDelegate.swift", "Runner/Assets.xcassets/AppIcon.appiconset/Contents.json", "Flutter/Debug.xcconfig", "Flutter/Release.xcconfig"):
        p = root / "ios" / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("x", encoding="utf-8")
class PreflightFailClosedInputs(unittest.TestCase):
    def check(self, root): return preflight.check(root, URL)
    def test_missing_pubspec_with_lock_and_provenance_does_not_crash(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); (root / "pubspec.lock").write_text("lock"); write_provenance(root)
            errors = self.check(root)
            self.assertIn("pubspec.yaml is missing or unreadable", errors)
            self.assertIn("pubspec.yaml does not match lockfile provenance", errors)
    def test_dangling_pubspec_symlink_does_not_crash(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); os.symlink(root / "nowhere", root / "pubspec.yaml")
            (root / "pubspec.lock").write_text("lock"); write_provenance(root)
            self.assertTrue(any("symbolic link" in e for e in self.check(root)))
    def test_symlinked_pubspec_is_never_hashed_as_a_match(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); (root / "real.yaml").write_text(PUBSPEC)
            os.symlink(root / "real.yaml", root / "pubspec.yaml")
            (root / "pubspec.lock").write_text("lock"); write_provenance(root)
            self.assertIn("pubspec.yaml does not match lockfile provenance", self.check(root))
    def test_non_utf8_release_inputs_are_blocked_not_crashing(self):
        for name, expected in {"pubspec.yaml": "pubspec.yaml is missing or unreadable", ".fvmrc": ".fvmrc is missing or unreadable; Flutter release toolchain is not pinned"}.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as d:
                root = Path(d); (root / name).write_bytes(b"\xff\xfe")
                self.assertIn(expected, self.check(root))
    def test_non_utf8_lockfile_and_provenance_are_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); (root / "pubspec.yaml").write_text(PUBSPEC)
            (root / "pubspec.lock").write_bytes(b"\xff\xfe"); write_provenance(root, lock=b"\xff\xfe")
            self.assertTrue(any("pubspec.lock is missing or empty" in e for e in self.check(root)))
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); (root / "pubspec.yaml").write_text(PUBSPEC)
            (root / "pubspec.lock").write_text("lock")
            (root / "lockfile-provenance.txt").write_bytes(b"\xff\xfe")
            self.assertTrue(any("provenance is missing or empty" in e for e in self.check(root)))
    def test_malformed_info_plist_and_non_utf8_project_are_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); make_ios(root)
            (root / "ios/Runner/Info.plist").write_text("<plist><dict><key>")
            self.assertIn("iOS Info.plist is unreadable or invalid", self.check(root))
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); make_ios(root)
            (root / "ios/Runner.xcodeproj/project.pbxproj").write_bytes(b"\xff\xfe")
            self.assertTrue(any("deployment target is missing" in e for e in self.check(root)))
    def test_non_utf8_dart_source_does_not_crash_capability_scan(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); make_ios(root); (root / "lib").mkdir()
            (root / "lib/a.dart").write_bytes(b"\xff\xfe")
            (root / "ios/Runner/Info.plist").write_bytes(plistlib.dumps({"CFBundleDisplayName": "SNIPER TÜRK", "ITSAppUsesNonExemptEncryption": False}))
            self.check(root)
    def test_symlinked_ios_tree_reports_one_accurate_error(self):
        with tempfile.TemporaryDirectory() as d, tempfile.TemporaryDirectory() as other:
            root = Path(d); os.symlink(other, root / "ios")
            errors = self.check(root)
            self.assertIn("ios must be a real directory, not a symbolic link", errors)
            self.assertNotIn("iOS scaffold is absent; generate it with the pinned Flutter toolchain", errors)
if __name__ == "__main__": unittest.main()
