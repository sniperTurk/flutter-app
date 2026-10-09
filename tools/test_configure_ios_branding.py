"""Contract tests for tools/configure_ios_branding.py."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import configure_ios_branding as cb  # noqa: E402

STORYBOARD = """<?xml version="1.0" encoding="UTF-8"?>
<document>
  <view key="view" id="Ze5-6b-2t3">
    <subviews>
      <imageView image="LaunchImage" id="YRO-k0-Ey4"/>
    </subviews>
    <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
  </view>
</document>
"""


class BrandingTests(unittest.TestCase):
    def test_committed_sources_are_valid(self):
        cb.check_sources(ROOT / "branding" / "ios")
        for name in cb.LAUNCH:
            w, h, _ = cb.png_info(ROOT / "branding" / "ios" / name)
            self.assertEqual(w, h)

    def test_install_is_complete_and_idempotent(self):
        with tempfile.TemporaryDirectory() as d:
            runner = Path(d) / "Runner"
            (runner / "Base.lproj").mkdir(parents=True)
            (runner / "Base.lproj" / "LaunchScreen.storyboard").write_text(STORYBOARD)
            old = runner / "Assets.xcassets" / "AppIcon.appiconset"
            old.mkdir(parents=True)
            (old / "Icon-App-20x20@1x.png").write_bytes(b"x")
            for _ in range(2):
                r = subprocess.run(
                    [sys.executable, str(ROOT / "tools/configure_ios_branding.py"),
                     str(ROOT / "branding/ios"), str(runner)],
                    capture_output=True, text=True,
                )
                self.assertEqual(0, r.returncode, r.stderr)
            icons = sorted(p.name for p in old.iterdir())
            self.assertEqual(["AppIcon-1024.png", "Contents.json"], icons)
            contents = json.loads((old / "Contents.json").read_text())
            self.assertEqual("1024x1024", contents["images"][0]["size"])
            launch = runner / "Assets.xcassets" / "LaunchImage.imageset"
            self.assertEqual(4, len(list(launch.iterdir())))
            sb = (runner / "Base.lproj" / "LaunchScreen.storyboard").read_text()
            self.assertEqual(1, sb.count(cb.BG_TAG))
            self.assertNotIn('red="1" green="1" blue="1"', sb)

    def test_alpha_icon_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            b = Path(d)
            for name in cb.LAUNCH:
                shutil.copyfile(ROOT / "branding/ios" / name, b / name)
            # LaunchImage has alpha (RGBA) and is 260 px: wrong as an icon.
            shutil.copyfile(ROOT / "branding/ios/LaunchImage.png", b / cb.ICON)
            with self.assertRaises(ValueError):
                cb.check_sources(b)

    def test_bootstrap_wiring(self):
        boot = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        self.assertIn("tools/configure_ios_branding.py branding/ios ios/Runner", boot)


if __name__ == "__main__":
    unittest.main()
