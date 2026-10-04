from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "tools/verify_signed_app_store_ipa.py"
EXPORT = ROOT / "tools/export_signed_app_store_ipa.sh"

class AppStoreDistributionProfileGateTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.verify = VERIFIER.read_text(encoding="utf-8")
        cls.export = EXPORT.read_text(encoding="utf-8")

    def test_rejects_expired_and_non_store_profiles(self):
        for token in ["ExpirationDate", "ProvisionedDevices", "ProvisionsAllDevices", "profile is expired"]:
            self.assertIn(token, self.verify)

    def test_requires_debugging_disabled_in_signature_and_profile(self):
        self.assertGreaterEqual(self.verify.count('get-task-allow'), 4)
        self.assertIn('entitlements.get("get-task-allow") is not False', self.verify)
        self.assertIn('pent.get("get-task-allow") is not False', self.verify)

    def test_export_gate_invokes_distribution_profile_verifier(self):
        self.assertIn("verify_signed_app_store_ipa.py", self.export)
        self.assertIn("SIGNED_APP_STORE_IPA_PASS", self.export)

if __name__ == "__main__":
    unittest.main()
