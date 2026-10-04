from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CleanIosScaffoldContractTests(unittest.TestCase):
    def test_bootstrap_rejects_symlink_then_removes_ios_before_create(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        symlink_guard = "if [[ -L ios ]]; then"
        remove = "rm -rf -- ios"
        create = 'flutter create --platforms=ios --org "$ORG" --project-name "$PROJECT" .'
        self.assertIn(symlink_guard, text)
        self.assertIn(remove, text)
        self.assertIn(create, text)
        self.assertLess(text.index(symlink_guard), text.index(remove))
        self.assertLess(text.index(remove), text.index(create))

    def test_bootstrap_does_not_claim_existing_tree_is_refreshed_in_place(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        self.assertNotIn("intentionally idempotent", text)


if __name__ == "__main__":
    unittest.main()
