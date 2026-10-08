"""V1 scope regression (rewritten for M1 "Menzil + Araçlar").

WHY THIS FILE CHANGED (documented per review requirement):
v271 enforced that Kronograf, Sight Height, Pusula and Su Terazisi did NOT
exist. The product owner has since put them back in V1 scope (Araçlar hub).
The "must not exist" assertions for exactly those four features are therefore
obsolete and were replaced by "exists, reachable only from the Araçlar hub".
Every other retired-surface assertion stays (and is stricter): no photo
library/image_picker, no audio recording bridge, no microphone use, no
path_provider, nothing retired reappears on the Home shell.

V1.1 (explicit, per product-owner request to close competitor feature gaps,
software/math-only — Bluetooth/hardware integrations stayed out of scope):
added 'Vuruş Olasılığı' (hit-probability / WEZ-style estimate), a standalone
statistics tool with no dependency on the still-gated drag solver and no
scope-adjustment ("klik"/"tambur") wording of its own. The hub count below
was bumped from 7 to 8 to match; everything else in this file is unchanged.
"""
from pathlib import Path
import importlib.util
import plistlib
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class V1ToolScopeTests(unittest.TestCase):
    def test_home_shell_reaches_tools_only_through_the_tools_hub(self):
        home = (ROOT / 'lib/features/home/home_screen.dart').read_text(encoding='utf-8')
        self.assertIn('ToolsScreen', home)
        # The four tool screens are opened from the hub, never straight from Home.
        for forbidden in ('ChronographScreen', 'SightHeightScreen', 'CompassScreen', 'LevelScreen', 'field_tools_screen.dart'):
            self.assertNotIn(forbidden, home)

    def test_tool_hub_lists_exactly_the_v1_1_tools(self):
        hub = (ROOT / 'lib/features/tools/tools_screen.dart').read_text(encoding='utf-8')
        for key in (
            'tool-chronograph', 'tool-sight-height', 'tool-compass', 'tool-level',
            'tool-weather', 'tool-hit-probability', 'tool-calculators',
            # 2026-10-08: Haritadan mesafe moved here from Hesaplayıcılar.
            'tool-map-distance',
        ):
            self.assertIn(f"Key('{key}')", hub)
        # V380: Ayarlar removed (the app is metric only).
        self.assertNotIn("Key('tool-settings')", hub)
        # 2026-10-08: Katalog is no longer on the hub; its data is kept.
        self.assertNotIn("Key('tool-catalog')", hub)
        self.assertEqual(8, hub.count('MenzilToolTile('))

    def test_still_retired_dependencies_and_ios_bridge_stay_absent(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for dependency in ('path_provider:', 'record:', 'flutter_sound:', 'permission_handler:'):
            self.assertNotIn(dependency, pubspec)
        bootstrap = (ROOT / 'tools/bootstrap_ios_scaffold.sh').read_text(encoding='utf-8')
        self.assertNotIn('install_ios_chronograph_audio_bridge', bootstrap)
        self.assertFalse((ROOT / 'native/ios/SniperChronographAudioPlugin.swift').exists())

    def test_generated_ios_plist_permissions_match_real_features(self):
        spec = importlib.util.spec_from_file_location('ios_plist_config', ROOT / 'tools/configure_ios_info_plist.py')
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Info.plist'
            path.write_bytes(plistlib.dumps({'NSPhotoLibraryUsageDescription': 'old'}))
            mod.configure(path)
            data = plistlib.loads(path.read_bytes())
        # M2: the Sight Height gallery choice needs the (Turkish) photo-library
        # usage text; write access (the "Add" key) stays retired.
        self.assertTrue(data['NSPhotoLibraryUsageDescription'].strip())
        self.assertNotIn('old', data['NSPhotoLibraryUsageDescription'])
        self.assertNotIn('NSPhotoLibraryAddUsageDescription', data)
        for key in ('NSLocationWhenInUseUsageDescription', 'NSCameraUsageDescription', 'NSMotionUsageDescription'):
            self.assertTrue(data[key].strip(), key)

    def test_ballistic_manual_sight_height_retained(self):
        profile = (ROOT / 'lib/data/profile_catalog_integrity.dart').read_text(encoding='utf-8')
        self.assertIn('sightHeightMm', profile)


if __name__ == '__main__':
    unittest.main()
