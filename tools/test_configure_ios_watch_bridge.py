"""Contract tests for tools/configure_ios_watch_bridge.py."""
from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import configure_ios_watch_bridge as wb  # noqa: E402

# Flutter 3.41+ (UISceneDelegate, implicit engine) template.
IMPLICIT = """import Flutter
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

# Older template: plugins registered on the app delegate itself.
CLASSIC = """import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
"""


class WatchBridgeAppDelegateTests(unittest.TestCase):
    def test_implicit_engine_registers_on_the_engine_registry(self):
        out = wb.patch_app_delegate(IMPLICIT)
        self.assertEqual(1, out.count(wb.MARKER))
        self.assertIn(
            'engineBridge.pluginRegistry.registrar(forPlugin: "SniperTurkWatchBridge")',
            out,
        )
        # Registered right after the generated plugins.
        self.assertLess(
            out.index("GeneratedPluginRegistrant.register"), out.index(wb.MARKER)
        )

    def test_classic_template_registers_on_self(self):
        out = wb.patch_app_delegate(CLASSIC)
        self.assertIn('self.registrar(forPlugin: "SniperTurkWatchBridge")', out)
        self.assertLess(out.index(wb.MARKER), out.index("return super.application"))

    def test_patch_is_idempotent(self):
        once = wb.patch_app_delegate(IMPLICIT)
        self.assertEqual(once, wb.patch_app_delegate(once))

    def test_optional_or_plain_registrar_both_compile_shape(self):
        # The registrar is bound through an explicit optional so the line
        # compiles whether the SDK returns FlutterPluginRegistrar or ...?.
        out = wb.patch_app_delegate(IMPLICIT)
        self.assertIn("let watchRegistrar: FlutterPluginRegistrar? =", out)

    def test_unexpected_delegate_fails_closed(self):
        with self.assertRaises(ValueError):
            wb.patch_app_delegate("import Flutter\n")

    def test_cli_patches_file_and_copies_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            runner = Path(tmp) / "Runner"
            runner.mkdir()
            (runner / "AppDelegate.swift").write_text(IMPLICIT, encoding="utf-8")
            done = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "configure_ios_watch_bridge.py"), str(runner)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, done.returncode, done.stderr)
            self.assertIn(wb.MARKER, (runner / "AppDelegate.swift").read_text(encoding="utf-8"))
            copied = (runner / "SniperTurkWatchBridge.swift").read_text(encoding="utf-8")
            self.assertIn("updateApplicationContext", copied)

    def test_testflight_scaffold_does_not_run_the_bridge(self):
        # The bridge is opt-in: only the manual watch workflow wires it.
        for name in ("bootstrap_ios_scaffold.sh",):
            self.assertNotIn("watch_bridge", (ROOT / "tools" / name).read_text(encoding="utf-8"))
        for wf in ("ios-testflight.yml", "ios-ci.yml"):
            text = (ROOT / ".github" / "workflows" / wf).read_text(encoding="utf-8")
            self.assertNotIn("watch_bridge", text)


if __name__ == "__main__":
    unittest.main()
