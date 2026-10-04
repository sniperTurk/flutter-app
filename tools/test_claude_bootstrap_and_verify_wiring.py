from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "tools" / "claude_bootstrap_and_verify.sh").read_text()
CLAUDE = (ROOT / "CLAUDE.md").read_text()

class ClaudeBootstrapVerifyWiringTest(unittest.TestCase):
    def test_pinned_flutter_is_read_from_fvmrc(self):
        self.assertIn("Path('.fvmrc')", SCRIPT)
        self.assertIn('checkout --detach "$EXPECTED_FLUTTER"', SCRIPT)

    def test_missing_sdk_can_be_bootstrapped_without_claiming_success_early(self):
        self.assertIn("https://github.com/flutter/flutter.git", SCRIPT)
        self.assertIn("BOOTSTRAP BLOCKED", SCRIPT)
        self.assertIn("claude_flutter_verify.sh", SCRIPT)

    def test_missing_lockfile_uses_explicit_bootstrap_mode(self):
        self.assertIn("SNIPER_TURK_BOOTSTRAP_LOCKFILE=1", SCRIPT)

    def test_claude_instructions_use_bootstrap_entrypoint(self):
        self.assertIn("tools/claude_bootstrap_and_verify.sh", CLAUDE)

if __name__ == "__main__":
    unittest.main()
