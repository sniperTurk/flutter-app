import plistlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class RunnerPrivacySourceContractTests(unittest.TestCase):
    def test_canonical_manifest_declares_user_defaults_reason(self):
        path = ROOT / "release/ios/PrivacyInfo.xcprivacy"
        with path.open("rb") as fh:
            payload = plistlib.load(fh)
        entries = payload.get("NSPrivacyAccessedAPITypes", [])
        self.assertIn({
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
        }, entries)
        self.assertIs(payload.get("NSPrivacyTracking"), False)

    def test_bootstrap_wires_app_owned_manifest(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text()
        self.assertIn("ruby tools/configure_ios_privacy_manifest.rb", text)
        self.assertIn("ios/Runner/PrivacyInfo.xcprivacy", text)
        ruby = (ROOT / "tools/configure_ios_privacy_manifest.rb").read_text()
        self.assertIn("target.resources_build_phase.add_file_reference", ruby)
        self.assertIn("release', 'ios', 'PrivacyInfo.xcprivacy", ruby)

    def test_ci_requires_app_owned_manifest_in_archive(self):
        workflow = (ROOT / ".github/workflows/ios-ci.yml").read_text()
        self.assertIn("--require-runner-manifest", workflow)

if __name__ == "__main__":
    unittest.main()
