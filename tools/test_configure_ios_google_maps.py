"""Contract tests for tools/configure_ios_google_maps.py."""
from __future__ import annotations

import os
import plistlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import configure_ios_google_maps as gm  # noqa: E402

TEMPLATE = """import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
"""


class GoogleMapsScaffoldTests(unittest.TestCase):
    def test_patch_inserts_import_and_guarded_call_once(self):
        out = gm.patch_app_delegate(TEMPLATE)
        self.assertEqual(1, out.count("import GoogleMaps"))
        self.assertEqual(1, out.count("GMSServices.provideAPIKey(key)"))
        # Key is provided before super.application (engine start).
        self.assertLess(
            out.index("GMSServices.provideAPIKey"),
            out.index("return super.application"),
        )
        self.assertEqual(out, gm.patch_app_delegate(out))

    def test_unexpected_delegate_fails_closed(self):
        with self.assertRaises(ValueError):
            gm.patch_app_delegate("import UIKit\n")
        with self.assertRaises(ValueError):
            gm.patch_app_delegate("import Flutter\nclass A {}\n")

    def _run(self, key: str | None):
        with tempfile.TemporaryDirectory() as d:
            delegate = Path(d) / "AppDelegate.swift"
            plist = Path(d) / "Info.plist"
            delegate.write_text(TEMPLATE, encoding="utf-8")
            with plist.open("wb") as f:
                plistlib.dump({"CFBundleName": "x", "GMSApiKey": "old"}, f)
            env = dict(os.environ)
            env.pop("GOOGLE_MAPS_IOS_API_KEY", None)
            if key is not None:
                env["GOOGLE_MAPS_IOS_API_KEY"] = key
            r = subprocess.run(
                [sys.executable, str(ROOT / "tools/configure_ios_google_maps.py"),
                 str(delegate), str(plist)],
                env=env, capture_output=True, text=True,
            )
            with plist.open("rb") as f:
                info = plistlib.load(f)
            return r, info

    def test_key_from_environment_only(self):
        r, info = self._run("test-key")
        self.assertEqual(0, r.returncode, r.stderr)
        self.assertEqual("test-key", info["GMSApiKey"])
        self.assertNotIn("test-key", r.stdout)

    def test_no_key_leaves_no_plist_entry(self):
        r, info = self._run(None)
        self.assertEqual(0, r.returncode, r.stderr)
        self.assertNotIn("GMSApiKey", info)

    def test_scaffold_and_testflight_wiring(self):
        boot = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        self.assertIn("tools/configure_ios_google_maps.py", boot)
        tf = (ROOT / ".github/workflows/ios-testflight.yml").read_text(encoding="utf-8")
        self.assertIn("GOOGLE_MAPS_IOS_API_KEY: ${{ secrets.GOOGLE_MAPS_IOS_API_KEY }}", tf)
        self.assertIn("--dart-define=GOOGLE_MAPS_ENABLED=", tf)

    def test_key_is_never_committed(self):
        for path in ROOT.rglob("*"):
            if not path.is_file() or ".git" in path.parts or "build" in path.parts:
                continue
            if path.suffix not in {".dart", ".py", ".sh", ".yml", ".yaml", ".plist", ".swift", ".json"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            self.assertNotRegex(text, r"AIza[0-9A-Za-z_\-]{35}", str(path))


if __name__ == "__main__":
    unittest.main()
