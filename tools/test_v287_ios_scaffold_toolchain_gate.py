import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class IOSScaffoldToolchainGateTests(unittest.TestCase):
    def test_scaffold_delegates_to_canonical_fail_closed_verifier(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        self.assertIn("python3 tools/verify_flutter_toolchain.py", text)
        self.assertNotIn("json.load(sys.stdin)", text)

    def test_scaffold_still_requires_flutter_before_verification(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        command_check = text.index("command -v flutter")
        verifier = text.index("python3 tools/verify_flutter_toolchain.py")
        create = text.index("flutter create --platforms=ios")
        self.assertLess(command_check, verifier)
        self.assertLess(verifier, create)


if __name__ == "__main__":
    unittest.main()
