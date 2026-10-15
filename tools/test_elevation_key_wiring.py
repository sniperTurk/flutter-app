"""Hava Durumu → İrtifa → "Haritadan" (owner, 2026-10-14): the Google Maps
iOS key reaches the app only as a TestFlight dart-define from the secret and
is never committed."""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ElevationKeyWiringTest(unittest.TestCase):
    def test_testflight_passes_the_key_from_the_secret(self):
        tf = (ROOT / ".github/workflows/ios-testflight.yml").read_text(encoding="utf-8")
        self.assertIn(
            '--dart-define=GOOGLE_MAPS_IOS_API_KEY="${GOOGLE_MAPS_IOS_API_KEY:-}"', tf
        )
        self.assertIn("GOOGLE_MAPS_IOS_API_KEY: ${{ secrets.GOOGLE_MAPS_IOS_API_KEY }}", tf)

    def test_adapter_reads_the_dart_define_and_sends_the_bundle_header(self):
        src = (ROOT / "lib/tools/adapters/google_elevation_provider.dart").read_text(
            encoding="utf-8"
        )
        self.assertIn("String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY')", src)
        self.assertIn("'X-Ios-Bundle-Identifier': bundleId", src)
        self.assertIn("com.sniperturk.sniperTurk", src)

    def test_no_google_key_is_committed(self):
        pattern = re.compile(r"AIza[0-9A-Za-z_\-]{30,}")
        for folder in ("lib", "test", "tools", ".github", "ios", "docs"):
            base = ROOT / folder
            if not base.exists():
                continue
            for path in base.rglob("*"):
                if not path.is_file() or path.suffix in {".png", ".jpg", ".ttf", ".otf"}:
                    continue
                try:
                    text = path.read_text(encoding="utf-8")
                except (UnicodeDecodeError, OSError):
                    continue
                self.assertIsNone(pattern.search(text), str(path))


if __name__ == "__main__":
    unittest.main()
