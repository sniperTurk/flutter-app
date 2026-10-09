"""M1 (Menzil + Araçlar) architecture, privacy and safety contract.

Pure source checks; they say nothing about runtime behaviour on a device.
"""
from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib'
PLATFORM_PACKAGES = ('geolocator', 'sensors_plus', 'flutter_compass', 'camera', 'http')
ALLOWED_PACKAGE_FILES = {
    'lib/tools/adapters/met_no_weather_provider.dart',
    'lib/tools/adapters/nominatim_place_search.dart',
    'lib/tools/adapters/sensors_plus_tilt_provider.dart',
    'lib/tools/adapters/camera_plugin_service.dart',
    'lib/tools/adapters/geolocator_location_provider.dart',
    'lib/tools/adapters/flutter_compass_heading_provider.dart',
}
ACCEPTANCE_SHA256 = '1d861282a0ed6bca503ec8fa7c11eb423c2d5d9704b0d383c51cfd1b7c67927d'


def dart_files():
    return sorted(p for p in LIB.rglob('*.dart') if p.is_file())


def rel(p):
    return p.relative_to(ROOT).as_posix()


class M1ArchitectureTests(unittest.TestCase):
    def test_platform_packages_only_in_adapters(self):
        pattern = re.compile(r"package:(%s)/" % '|'.join(PLATFORM_PACKAGES))
        offenders = [rel(p) for p in dart_files()
                     if pattern.search(p.read_text(encoding='utf-8')) and rel(p) not in ALLOWED_PACKAGE_FILES]
        self.assertEqual([], offenders)
        for f in ALLOWED_PACKAGE_FILES:
            self.assertTrue((ROOT / f).is_file(), f)

    def test_ui_imports_only_ports_domain_state_and_services(self):
        for p in (LIB / 'features' / 'tools').glob('*.dart'):
            for m in re.finditer(r"import '([^']+)'", p.read_text(encoding='utf-8')):
                path = m.group(1)
                self.assertNotIn('tools/adapters/', path, f'{rel(p)} imports an adapter')
                self.assertNotIn('tools/config/', path, f'{rel(p)} imports config')

    def test_no_fake_demo_or_mock_in_production_lib(self):
        offenders = []
        for p in dart_files():
            text = p.read_text(encoding='utf-8')
            for m in re.finditer(r'\b\w*(Fake|Demo|Mock)\w*\b', text):
                offenders.append(f'{rel(p)}: {m.group(0)}')
        self.assertEqual([], offenders)

    def test_colors_come_from_the_central_theme(self):
        offenders = [rel(p) for p in dart_files()
                     if rel(p) != 'lib/ui/menzil_theme.dart' and re.search(r'Color\(0x', p.read_text(encoding='utf-8'))]
        self.assertEqual([], offenders)

    def test_level_liquid_green_is_a_single_token_used_only_by_the_level_screen(self):
        users = [rel(p) for p in dart_files() if 'levelLiquid' in p.read_text(encoding='utf-8')]
        self.assertEqual(['lib/features/tools/level_screen.dart', 'lib/ui/menzil_theme.dart'], users)

    def test_vision_is_not_a_tool_tile_and_is_not_connected(self):
        hub = (LIB / 'features/tools/tools_screen.dart').read_text(encoding='utf-8')
        for word in ('Qwen', 'Vision', 'Görsel yardım'):
            self.assertNotIn(word, hub)
        services = (LIB / 'tools/tools_services.dart').read_text(encoding='utf-8')
        self.assertIn('DisconnectedVisionAssist()', services)
        port = (LIB / 'tools/ports/vision_assist.dart').read_text(encoding='utf-8')
        self.assertIn('bool get isConnected => false;', port)
        # No networking in the vision path.
        self.assertNotIn('http', port.lower().replace('https://', ''))

    def test_location_and_photos_are_never_persisted(self):
        for p in dart_files():
            if not rel(p).startswith('lib/tools/') and not rel(p).startswith('lib/features/tools/'):
                continue
            text = p.read_text(encoding='utf-8')
            for forbidden in ('SharedPreferences', 'writeAsBytes', 'writeAsString', 'getApplicationDocumentsDirectory'):
                self.assertNotIn(forbidden, text, rel(p))

    def test_only_the_camera_adapter_touches_files_and_only_to_delete_the_temp_capture(self):
        users = [rel(p) for p in dart_files() if re.search(r'\bFile\(', p.read_text(encoding='utf-8'))]
        # M2: the gallery adapter reads the single chosen photo into memory and
        # deletes the plugin's temporary copy. It never writes or keeps a file.
        self.assertEqual(['lib/tools/adapters/camera_plugin_service.dart',
                          'lib/tools/adapters/image_picker_photo_picker.dart'], users)
        picker = (LIB / 'tools/adapters/image_picker_photo_picker.dart').read_text(encoding='utf-8')
        self.assertIn('.delete()', picker)
        text = (LIB / 'tools/adapters/camera_plugin_service.dart').read_text(encoding='utf-8')
        self.assertIn('.delete()', text)

    def test_weather_fails_closed_until_a_real_contact_is_configured(self):
        cfg = (LIB / 'tools/config/tools_config.dart').read_text(encoding='utf-8')
        self.assertIn('CONTACT_REQUIRED', cfg)
        adapter = (LIB / 'tools/adapters/met_no_weather_provider.dart').read_text(encoding='utf-8')
        self.assertIn('metNoPlaceholderMarker', adapter)

    def test_single_unit_system_used_by_tools(self):
        # Tool screens convert through UnitSystem and read the one metric flag.
        for name in ('weather_screen.dart', 'chronograph_screen.dart', 'tool_support.dart'):
            text = (LIB / 'features/tools' / name).read_text(encoding='utf-8')
            self.assertTrue('UnitSystem' in text or 'ToolFormat' in text, name)
        settings = (LIB / 'services/app_settings.dart').read_text(encoding='utf-8')
        self.assertNotIn('SharedPreferences', settings)

    def test_tool_screens_expose_no_click_or_hold_instruction(self):
        for p in (LIB / 'features/tools').glob('*.dart'):
            text = p.read_text(encoding='utf-8').lower()
            # The Hesaplayicilar screen has a user-requested scope click-value
            # CHECK (measures the real click size). It may name clicks, but it
            # must still never give a firing/hold instruction.
            forbidden_words = ('tambur', 'holdover') if p.name == 'calculators_screen.dart' else ('klik', 'click', 'tambur', 'holdover')
            for forbidden in forbidden_words:
                self.assertNotIn(forbidden, text, rel(p))
        calc = (LIB / 'features/tools/calculators_screen.dart').read_text(encoding='utf-8').lower()
        for forbidden in ('çevrilecek', 'dial ', 'hold '):
            self.assertNotIn(forbidden, calc)


class M1SafetyBoundaryTests(unittest.TestCase):
    def test_acceptance_contract_is_unchanged(self):
        digest = hashlib.sha256((ROOT / 'validation/acceptance.json').read_bytes()).hexdigest()
        self.assertEqual(ACCEPTANCE_SHA256, digest)

    def test_no_hand_made_lockfile_in_this_branch(self):
        # pubspec.lock / provenance are produced only by the pinned Actions
        # workflow (Job 1); this UI branch must not contain hand-made copies.
        # A lockfile may exist only together with provenance that ties it to
        # the pinned Flutter and the current pubspec.yaml (never hand-made).
        import subprocess, sys
        lock = (ROOT / 'pubspec.lock').exists()
        prov = (ROOT / 'lockfile-provenance.txt').exists()
        self.assertEqual(lock, prov, 'pubspec.lock and its provenance go together')
        if lock:
            r = subprocess.run([sys.executable, str(ROOT / 'tools/verify_lockfile_provenance.py')],
                               capture_output=True, text=True)
            self.assertEqual(0, r.returncode, r.stdout + r.stderr)

    def test_solver_core_is_not_imported_from_tool_code(self):
        for p in list((LIB / 'tools').rglob('*.dart')) + list((LIB / 'features/tools').glob('*.dart')):
            text = p.read_text(encoding='utf-8')
            self.assertNotIn('aerodynamic_trajectory_solver', text, rel(p))

    def test_ios_usage_strings_cover_every_new_capability(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location('cfg', ROOT / 'tools/configure_ios_info_plist.py')
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        keys = set(mod.USAGE_DESCRIPTIONS)
        self.assertEqual({'NSLocationWhenInUseUsageDescription',
                          'NSLocationAlwaysAndWhenInUseUsageDescription',
                          'NSCameraUsageDescription',
                          'NSMotionUsageDescription', 'NSMicrophoneUsageDescription',
                          'NSPhotoLibraryUsageDescription'}, keys)


if __name__ == '__main__':
    unittest.main()
