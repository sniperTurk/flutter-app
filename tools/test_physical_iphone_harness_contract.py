from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools/run_physical_iphone_test.sh"


class PhysicalIphoneHarnessContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SCRIPT.read_text(encoding="utf-8")

    def test_requires_macos_flutter_xcrun_and_lockfile(self):
        for marker in ('uname -s', 'command -v flutter', 'command -v xcrun', 'pubspec.lock'):
            self.assertIn(marker, self.text)

    def test_uses_machine_device_discovery_and_physical_selector(self):
        self.assertIn('flutter devices --machine', self.text)
        self.assertIn('select_physical_ios_device.py', self.text)
        self.assertIn('xcrun devicectl list devices', self.text)

    def test_runs_integration_test_on_selected_hardware(self):
        self.assertIn('flutter test integration_test/app_launch_test.dart -d "$DEVICE_ID"', self.text)
        self.assertIn('PHYSICAL_IPHONE_TEST_PASS', self.text)

    def test_pub_get_cannot_silently_rewrite_lockfile(self):
        self.assertIn('BEFORE_LOCK_SHA=', self.text)
        self.assertIn('AFTER_LOCK_SHA=', self.text)
        self.assertIn('[[ "$BEFORE_LOCK_SHA" == "$AFTER_LOCK_SHA" ]]', self.text)
        self.assertIn('flutter pub get changed pubspec.lock', self.text)

    def test_lock_stability_gate_precedes_physical_test_pass(self):
        self.assertLess(self.text.index('BEFORE_LOCK_SHA='), self.text.index('\nflutter pub get\n'))
        self.assertLess(self.text.index('flutter pub get changed pubspec.lock'), self.text.index('flutter test integration_test/app_launch_test.dart'))
        self.assertLess(self.text.index('flutter test integration_test/app_launch_test.dart'), self.text.index('PHYSICAL_IPHONE_TEST_PASS'))


if __name__ == "__main__":
    unittest.main()
