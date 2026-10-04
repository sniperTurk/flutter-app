#!/usr/bin/env python3
"""Regression guard for GitHub-hosted runner JavaScript action runtimes."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'ios-ci.yml'

class IosCiActionRuntimeWiringTest(unittest.TestCase):
    def test_node24_compatible_official_action_majors_are_used(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        self.assertIn('actions/checkout@v6', text)
        self.assertIn('actions/setup-python@v7', text)
        self.assertIn('actions/upload-artifact@v7', text)
        deprecated = re.findall(r'actions/(?:checkout@v[1-4]|setup-python@v[1-5]|upload-artifact@v[1-6])\\b', text)
        self.assertEqual([], deprecated, f'deprecated GitHub-hosted action runtime(s): {deprecated}')

if __name__ == '__main__':
    unittest.main()
