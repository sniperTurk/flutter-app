from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IOSCIFlutterToolchainWiringTests(unittest.TestCase):
    def test_exact_toolchain_verifier_runs_after_flutter_setup_before_pub_get(self):
        text = (ROOT / ".github/workflows/ios-ci.yml").read_text(encoding="utf-8")
        setup = text.index("uses: subosito/flutter-action@v2")
        verify = text.index("python3 tools/verify_flutter_toolchain.py")
        pub_get = text.index("flutter pub get")
        self.assertLess(setup, verify)
        self.assertLess(verify, pub_get)


if __name__ == "__main__":
    unittest.main()
