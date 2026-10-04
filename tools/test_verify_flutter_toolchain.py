import json
import tempfile
import unittest
from pathlib import Path
from verify_flutter_toolchain import EXPECTED_FLUTTER_VERSION, read_project_pin, verify


class FlutterToolchainVerifierTests(unittest.TestCase):
    def test_accepts_exact_pinned_version(self):
        self.assertEqual(verify(json.dumps({"frameworkVersion": EXPECTED_FLUTTER_VERSION})), [])

    def test_rejects_version_drift(self):
        errors = verify(json.dumps({"frameworkVersion": "3.47.3"}))
        self.assertTrue(any("exactly" in error for error in errors))

    def test_rejects_missing_version(self):
        self.assertTrue(verify("{}"))

    def test_rejects_non_json_output(self):
        self.assertTrue(verify("Flutter 3.47.2"))

    def test_rejects_non_object_json_output(self):
        errors = verify("[]")
        self.assertTrue(any("JSON root" in error for error in errors))

    def test_reads_project_pin_from_fvmrc(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / ".fvmrc").write_text('{"flutter":"3.47.2"}', encoding="utf-8")
            self.assertEqual(read_project_pin(root), ("3.47.2", []))

    def test_rejects_malformed_fvmrc(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / ".fvmrc").write_text('{broken', encoding="utf-8")
            pin, errors = read_project_pin(root)
            self.assertIsNone(pin)
            self.assertTrue(errors)

    def test_rejects_symlink_fvmrc(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            target = root / "pin.json"
            target.write_text('{"flutter":"3.47.2"}', encoding="utf-8")
            (root / ".fvmrc").symlink_to(target)
            pin, errors = read_project_pin(root)
            self.assertIsNone(pin)
            self.assertTrue(any("symbolic link" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
