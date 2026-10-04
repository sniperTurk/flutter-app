from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IOSCILockfileGateWiringTests(unittest.TestCase):
    def test_lockfile_gate_runs_before_flutter_setup_and_pub_get(self):
        text = (ROOT / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
        lock_gate = text.index('name: Require committed dependency lockfile')
        flutter_setup = text.index('name: Set up Flutter')
        pub_get = text.index('flutter pub get')
        self.assertLess(lock_gate, flutter_setup)
        self.assertLess(lock_gate, pub_get)

    def test_lockfile_gate_is_fail_closed_and_not_duplicated(self):
        text = (ROOT / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
        self.assertEqual(1, text.count('name: Require committed dependency lockfile'))
        self.assertIn('test -s pubspec.lock || {', text)
        self.assertIn('exit 1', text[text.index('name: Require committed dependency lockfile'):text.index('name: Set up Flutter')])


if __name__ == '__main__':
    unittest.main()
