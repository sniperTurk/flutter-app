import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FormatHelperContractTest(unittest.TestCase):
    def test_helper_formats_exactly_what_the_ci_gate_checks(self):
        workflow = (ROOT / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
        helper = (ROOT / 'tools/format_dart.sh').read_text(encoding='utf-8')
        gate = 'dart format --output=none --set-exit-if-changed lib test integration_test tools'
        self.assertIn(gate, workflow)
        self.assertIn('dart format lib test integration_test tools', helper)
        self.assertIn('set -euo pipefail', helper)


if __name__ == '__main__':
    unittest.main()
