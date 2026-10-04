from pathlib import Path
import unittest


class IOSCIReleasePreflightWiringTest(unittest.TestCase):
    def test_release_preflight_runs_after_scaffold_and_before_ios_build(self):
        workflow = (Path(__file__).resolve().parents[1] / ".github/workflows/ios-ci.yml").read_text(encoding="utf-8")
        scaffold = workflow.index("run: tools/bootstrap_ios_scaffold.sh")
        preflight = workflow.index("python3 tools/app_store_preflight.py --privacy-url")
        live_privacy = workflow.index('python3 tools/verify_privacy_policy_url.py --url "$PRIVACY_POLICY_URL"')
        simulator_build = workflow.index("run: flutter build ios --simulator --debug")
        self.assertLess(scaffold, preflight)
        self.assertLess(preflight, live_privacy)
        self.assertLess(live_privacy, simulator_build)
        self.assertIn("PRIVACY_POLICY_URL: ${{ vars.PRIVACY_POLICY_URL }}", workflow)


if __name__ == "__main__":
    unittest.main()
