from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IosScaffoldRefreshContractTests(unittest.TestCase):
    def test_bootstrap_always_refreshes_flutter_ios_scaffold(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        command = 'flutter create --platforms=ios --org "$ORG" --project-name "$PROJECT" .'
        self.assertIn(command, text)
        self.assertNotIn('if [[ ! -d ios ]]; then', text)

    def test_ci_uses_scaffold_bootstrap_before_ios_build(self):
        workflow = (ROOT / ".github/workflows/ios-ci.yml").read_text(encoding="utf-8")
        scaffold = workflow.index("run: tools/bootstrap_ios_scaffold.sh")
        simulator = workflow.index("run: flutter build ios --simulator --debug")
        self.assertLess(scaffold, simulator)


if __name__ == "__main__":
    unittest.main()
