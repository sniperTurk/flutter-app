#!/usr/bin/env python3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/ios-ci.yml"
BOOTSTRAP = ROOT / "tools/bootstrap_ios_scaffold.sh"

class IOSCISigningWiringTests(unittest.TestCase):
    def test_ci_passes_owner_team_variable_to_bootstrap(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        marker = "- name: Generate and verify pinned iOS scaffold"
        start = text.index(marker)
        end = text.index("- name: Enforce App Store source preflight", start)
        step = text[start:end]
        self.assertIn("SNIPER_TURK_IOS_DEVELOPMENT_TEAM: ${{ vars.IOS_DEVELOPMENT_TEAM }}", step)
        self.assertIn("run: tools/bootstrap_ios_scaffold.sh", step)

    def test_bootstrap_consumes_same_environment_contract(self):
        text = BOOTSTRAP.read_text(encoding="utf-8")
        self.assertIn('SNIPER_TURK_IOS_DEVELOPMENT_TEAM', text)
        self.assertIn('python3 tools/configure_ios_signing.py', text)

if __name__ == "__main__":
    unittest.main()
