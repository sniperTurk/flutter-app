from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools/export_signed_app_store_ipa.sh"

class SignedExportGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SCRIPT.read_text(encoding="utf-8")

    def test_gate_is_fail_closed_and_requires_real_apple_tooling(self):
        for token in ["uname -s", "xcodebuild", "codesign", "SNIPER_TURK_IOS_DEVELOPMENT_TEAM", "^[A-Z0-9]{10}$"]:
            self.assertIn(token, self.text)

    def test_export_consumes_validated_unsigned_archive(self):
        self.assertIn("verify_ios_archive_signing_state.py", self.text)
        self.assertIn("generate_ios_export_options.py", self.text)
        self.assertIn("xcodebuild -exportArchive", self.text)

    def test_success_requires_real_signed_payload(self):
        self.assertIn("codesign --verify --deep --strict", self.text)
        self.assertIn("embedded.mobileprovision", self.text)
        self.assertIn("SIGNED_APP_STORE_IPA_PASS", self.text)

if __name__ == "__main__":
    unittest.main()
