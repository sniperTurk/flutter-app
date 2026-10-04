#!/usr/bin/env python3
"""Regression guard: iOS CI must execute every offline Python regression test.

A hand-maintained unittest module list silently skips newly added test files.  The
release workflow must use discovery so adding tools/test_*.py automatically
extends the production gate.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'ios-ci.yml'


class IosCiPythonSuiteWiringTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = WORKFLOW.read_text(encoding='utf-8')

    def test_offline_suite_uses_unittest_discovery(self):
        self.assertIn(
            "python3 -m unittest discover -s tools -p 'test_*.py' -v",
            self.text,
        )

    def test_offline_dart_lint_is_wired_before_flutter_setup(self):
        self.assertIn('python3 tools/offline_dart_lint.py', self.text)
        self.assertLess(self.text.index('python3 tools/offline_dart_lint.py'), self.text.index('name: Set up Flutter'))

    def test_ci_does_not_keep_manual_unittest_module_list(self):
        self.assertNotIn('PYTHONPATH=tools python3 -m unittest tools/', self.text)


if __name__ == '__main__':
    unittest.main()
