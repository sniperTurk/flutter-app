"""Owner, 2026-10-10: the iOS app ships for iPhone only (no iPad target)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IphoneOnlyContract(unittest.TestCase):
    def test_bootstrap_sets_iphone_device_family(self):
        text = (ROOT / 'tools/bootstrap_ios_scaffold.sh').read_text(encoding='utf-8')
        self.assertIn('TARGETED_DEVICE_FAMILY = 1;', text)
        self.assertIn("grep -q 'TARGETED_DEVICE_FAMILY = 1;'", text)


if __name__ == '__main__':
    unittest.main()
