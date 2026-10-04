#!/usr/bin/env python3
"""Structural regression checks for source-artifact hygiene in iOS CI."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "ios-ci.yml"


class CiSourceHygieneTests(unittest.TestCase):
    def test_ci_checks_tracked_files_not_generated_worktree_files(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("git ls-files | grep -E", text)
        self.assertNotIn("find . -path './.git' -prune", text)

    def test_release_tree_has_no_temporary_or_backup_source_files(self):
        bad = []
        for path in ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts:
                continue
            name = path.name
            # Runtime Python caches may be created by the test runner itself;
            # CI checks whether those are committed via git ls-files. This
            # release-tree assertion targets editor/temp artifacts that must
            # never ship in the source archive.
            if name.endswith((".tmp", ".bak", "~")):
                bad.append(str(path.relative_to(ROOT)))
        self.assertEqual([], bad)


if __name__ == "__main__":
    unittest.main()
