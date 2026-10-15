"""Contract tests for tools/configure_ios_garmin_bridge.py."""
from __future__ import annotations

import plistlib
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import configure_ios_garmin_bridge as gb  # noqa: E402

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

HEADER = '#import "GeneratedPluginRegistrant.h"\n'


class GarminBridgeTests(unittest.TestCase):
    def test_registers_after_generated_plugins(self):
        out = gb.patch_app_delegate(IMPLICIT)
        self.assertEqual(1, out.count(gb.MARKER))
        self.assertIn('engineBridge.pluginRegistry.registrar(forPlugin: "SniperTurkGarminBridge")', out)
        self.assertIn("SniperTurkGarminBridge.register(with: garminRegistrar)", out)
        self.assertLess(out.index("GeneratedPluginRegistrant.register"), out.index(gb.MARKER))
        self.assertEqual(out, gb.patch_app_delegate(out))

    def test_coexists_with_the_apple_watch_bridge(self):
        import configure_ios_watch_bridge as wb

        both = gb.patch_app_delegate(wb.patch_app_delegate(IMPLICIT))
        self.assertIn(wb.MARKER, both)
        self.assertIn(gb.MARKER, both)

    def test_bridging_header_imports_once(self):
        out = gb.patch_bridging_header(HEADER)
        self.assertEqual(1, out.count(gb.HEADER_IMPORT))
        self.assertEqual(out, gb.patch_bridging_header(out))

    def test_info_plist_gets_scheme_query_and_bluetooth_text(self):
        info = {
            "CFBundleURLTypes": [{"CFBundleURLSchemes": ["other"]}],
            "LSApplicationQueriesSchemes": ["https"],
        }
        out = gb.patch_info_plist(info)
        schemes = [s for t in out["CFBundleURLTypes"] for s in t["CFBundleURLSchemes"]]
        self.assertEqual(schemes, ["other", "sniperturk-ciq"])
        self.assertEqual(out["LSApplicationQueriesSchemes"], ["https", "gcm-ciq"])
        self.assertTrue(out["NSBluetoothAlwaysUsageDescription"].strip())
        self.assertEqual(out, gb.patch_info_plist(out))
        # The input is not modified in place.
        self.assertEqual(info["LSApplicationQueriesSchemes"], ["https"])

    def test_scheme_and_app_id_match_the_native_source_and_manifest(self):
        source = (ROOT / "garmin/ios_runner/SniperTurkGarminBridge.m").read_text(encoding="utf-8")
        self.assertIn(f'kURLScheme = @"{gb.URL_SCHEME}"', source)
        self.assertIn('kChannelName = @"sniper_turk/garmin"', source)
        manifest = ET.parse(ROOT / "garmin/manifest.xml").getroot()
        app = manifest.find("{http://www.garmin.com/xml/connectiq}application")
        raw = app.get("id")
        dashed = f"{raw[:8]}-{raw[8:12]}-{raw[12:16]}-{raw[16:20]}-{raw[20:]}"
        self.assertIn(f'kWatchAppUUID = @"{dashed}"', source)
        dart = (ROOT / "lib/services/watch/watch_bridge.dart").read_text(encoding="utf-8")
        self.assertIn("channelName = 'sniper_turk/garmin'", dart)

    def test_bridge_source_handles_cold_launch_lazy_sdk_and_transient_sends(self):
        source = (ROOT / "garmin/ios_runner/SniperTurkGarminBridge.m").read_text(encoding="utf-8")
        # 1: cold launch through a UIScene or a plain application delegate.
        self.assertIn("willConnectToSession:(UISceneSession *)session", source)
        self.assertIn("connectionOptions.URLContexts", source)
        self.assertIn("UIApplicationLaunchOptionsURLKey", source)
        # 2: the SDK (and its Bluetooth prompt) starts lazily, exactly once.
        self.assertIn("- (void)ensureStarted", source)
        self.assertEqual(1, source.count("sharedInstance] initializeWithUrlScheme:"))
        self.assertNotIn("[instance start]", source)
        # 3: device-count events for the Araçlar tile.
        self.assertIn('kDevicesChannelName = @"sniper_turk/garmin/devices"', source)
        self.assertIn("FlutterEventChannel eventChannelWithName:kDevicesChannelName", source)
        dart = (ROOT / "lib/services/watch/watch_bridge.dart").read_text(encoding="utf-8")
        self.assertIn("devicesChannelName = 'sniper_turk/garmin/devices'", dart)
        # 6: latest state only, no mailbox backlog.
        self.assertIn("isTransient:YES", source)
        self.assertNotIn("progress:nil", source)

    def test_cold_launch_url_is_claimed_so_flutter_does_not_deep_link_it(self):
        # Flutter 3.47 sends unclaimed connection-option URLs to the router
        # (deep linking is on unless Info.plist turns it off); the app has no
        # route for sniperturk-ciq://, so the bridge must claim its own URL.
        source = (ROOT / "garmin/ios_runner/SniperTurkGarminBridge.m").read_text(encoding="utf-8")
        start = source.index("willConnectToSession:(UISceneSession *)session")
        body = source[start:source.index("\n}\n", start)]
        self.assertIn("handled = [self handleURL:context.URL] || handled;", body)
        self.assertIn("return handled;", body)
        self.assertNotIn("return NO;", body)
        # handleURL claims every URL of our scheme and nothing else.
        handle = source[source.index("- (BOOL)handleURL:(NSURL *)url {"):]
        handle = handle[: handle.index("\n}\n")]
        self.assertIn("isEqualToString:kURLScheme]) {\n    return NO;", handle)
        self.assertIn("if (selected == nil) {\n    return YES;", handle)

    def test_ok_goes_to_the_watch_as_1_or_0_and_the_watch_accepts_both(self):
        source = (ROOT / "garmin/ios_runner/SniperTurkGarminBridge.m").read_text(encoding="utf-8")
        # Phone: a CFBoolean `ok` becomes NSNumber 1/0; other values pass.
        self.assertIn("CFBooleanGetTypeID()", source)
        self.assertIn('copy[@"ok"] = [ok boolValue] ? @1 : @0;', source)
        self.assertIn("NSDictionary *safe = [self watchSafe:message];", source)
        # Watch: Boolean, Number/Long (0 = false) and Char are read; anything
        # else (missing, String) rejects the message.
        mc = (ROOT / "garmin/source/Solution.mc").read_text(encoding="utf-8")
        self.assertIn('var ok = Solution.toBool(m.get("ok"));', mc)
        self.assertIn("if (ok == null || !(profile instanceof String)) {", mc)
        to_bool = mc[mc.index("static function toBool(v) {"):]
        to_bool = to_bool[: to_bool.index("\n    }\n")]
        self.assertIn("if (v instanceof Boolean) {\n            return v;", to_bool)
        self.assertIn(
            "if (v instanceof Number || v instanceof Long) {\n            return v != 0;", to_bool
        )
        self.assertIn("if (v instanceof Char) {\n            return v.toNumber() != 0;", to_bool)
        self.assertTrue(to_bool.rstrip().endswith("return null;"))
        self.assertNotIn("instanceof String", to_bool)

    def test_cli_wires_a_scaffold(self):
        with tempfile.TemporaryDirectory() as tmp:
            runner = Path(tmp) / "Runner"
            runner.mkdir()
            (runner / "AppDelegate.swift").write_text(IMPLICIT, encoding="utf-8")
            (runner / "Runner-Bridging-Header.h").write_text(HEADER, encoding="utf-8")
            (runner / "Info.plist").write_bytes(plistlib.dumps({"CFBundleName": "x"}))
            done = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "configure_ios_garmin_bridge.py"), str(runner)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(0, done.returncode, done.stderr)
            self.assertTrue((runner / "SniperTurkGarminBridge.m").is_file())
            self.assertTrue((runner / "SniperTurkGarminBridge.h").is_file())
            info = plistlib.loads((runner / "Info.plist").read_bytes())
            self.assertIn("gcm-ciq", info["LSApplicationQueriesSchemes"])

    def test_missing_scaffold_fails_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            done = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "configure_ios_garmin_bridge.py"), tmp],
                capture_output=True,
                text=True,
            )
            self.assertEqual(2, done.returncode)

    def test_shipped_builds_do_not_wire_the_bridge(self):
        # Opt-in: only the manual Garmin workflow wires it.
        self.assertNotIn("garmin_bridge", (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8"))
        for wf in ("ios-testflight.yml", "ios-ci.yml"):
            text = (ROOT / ".github" / "workflows" / wf).read_text(encoding="utf-8")
            self.assertNotIn("garmin_bridge", text)
        sim = (ROOT / ".github/workflows/garmin-sim.yml").read_text(encoding="utf-8")
        self.assertIn("configure_ios_garmin_bridge.py", sim)
        self.assertIn("configure_ios_garmin_bridge.rb", sim)


if __name__ == "__main__":
    unittest.main()
