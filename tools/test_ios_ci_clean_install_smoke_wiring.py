#!/usr/bin/env python3
"""Lock iOS CI smoke tests to deterministic clean-install state."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "ios-ci.yml"


class IosCiCleanInstallSmokeWiringTest(unittest.TestCase):
    def test_smoke_uninstalls_before_raw_launch_and_before_integration_test(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        step = text.split("- name: Boot iOS Simulator and run launch smoke test", 1)[1]
        self.assertIn('BUNDLE_ID="com.sniperturk.sniperTurk"', step)
        uninstall = 'xcrun simctl uninstall "$UDID" "$BUNDLE_ID"'
        self.assertGreaterEqual(step.count(uninstall), 2)
        first_uninstall = step.index(uninstall)
        install = step.index('xcrun simctl install "$UDID" "$APP_PATH"')
        second_uninstall = step.index(uninstall, first_uninstall + 1)
        integration = step.index('flutter test integration_test/app_launch_test.dart')
        self.assertLess(first_uninstall, install)
        self.assertLess(install, second_uninstall)
        self.assertLess(second_uninstall, integration)

    def test_built_bundle_id_must_match_release_identity(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn('[[ "$BUILT_BUNDLE_ID" == "$BUNDLE_ID" ]]', text)


if __name__ == "__main__":
    unittest.main()
