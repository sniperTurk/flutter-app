import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("signed_ipa_verifier", ROOT / "tools/verify_signed_app_store_ipa.py")
MOD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MOD)

class SignedIpaZipPathSafetyTest(unittest.TestCase):
    def test_rejects_parent_traversal_before_extraction(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            archive = base / "evil.ipa"
            out = base / "out"
            out.mkdir()
            escaped = base / "escaped.txt"
            with zipfile.ZipFile(archive, "w") as zf:
                zf.writestr("../escaped.txt", "owned")
            with zipfile.ZipFile(archive) as zf:
                with self.assertRaises(SystemExit):
                    MOD.safe_extract_zip(zf, out)
            self.assertFalse(escaped.exists())

    def test_accepts_normal_ipa_member_paths(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            archive = base / "ok.ipa"
            out = base / "out"
            out.mkdir()
            with zipfile.ZipFile(archive, "w") as zf:
                zf.writestr("Payload/Runner.app/Info.plist", b"plist")
            with zipfile.ZipFile(archive) as zf:
                MOD.safe_extract_zip(zf, out)
            self.assertEqual((out / "Payload/Runner.app/Info.plist").read_bytes(), b"plist")

if __name__ == "__main__":
    unittest.main()
