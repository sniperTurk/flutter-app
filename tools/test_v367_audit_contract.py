"""V367 audit: source-text guards for defects only Flutter would reject.

Source-text checks; they do NOT replace flutter analyze / flutter test.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class V367AuditContract(unittest.TestCase):
    def test_semantics_is_never_inside_a_const_expression(self):
        # Semantics(...) has no const constructor.
        for p in sorted((ROOT / 'lib').rglob('*.dart')):
            text = p.read_text(encoding='utf-8')
            self.assertIsNone(re.search(r'const\s+\w+\(\s*child:\s*Semantics\(', text), p.name)
            self.assertIsNone(re.search(r'const\s+Semantics\(', text), p.name)

    def test_double_clamp_results_are_converted_to_double(self):
        for rel in ('lib/ui/sight_height_art.dart', 'lib/features/tools/sight_height_diagrams.dart',
                    'lib/features/tools/level_screen.dart', 'lib/features/tools/sight_height_screen.dart',
                    'lib/features/ballistics/ballistics_screen.dart'):
            for line in read(rel).splitlines():
                if '.clamp(' in line and 'asin' not in line:
                    self.assertIn('.toDouble()', line, (rel, line))

    def test_archived_tests_are_not_analysed(self):
        self.assertIn('archived_tests/**', read('analysis_options.yaml'))

    def test_fontfeature_is_imported_from_dart_ui(self):
        self.assertIn("import 'dart:ui' show FontFeature;", read('lib/ui/menzil_theme.dart'))

    def test_level_is_portrait_locked_and_restores_orientation(self):
        text = read('lib/features/tools/level_screen.dart')
        self.assertIn('DeviceOrientation.portraitUp', text)
        self.assertIn('SystemChrome.setPreferredOrientations(DeviceOrientation.values);', text)

    def test_compass_big_text_is_not_read_twice_by_voiceover(self):
        self.assertIn('ExcludeSemantics(\n                    child: Center(', read('lib/features/tools/compass_screen.dart'))

    def test_weather_wind_label_uses_spoken_name_and_clock_refresh(self):
        text = read('lib/features/tools/weather_screen.dart')
        self.assertIn('cardinal16Spoken(obs.windFromDeg)', text)
        self.assertIn('Timer.periodic', text)
        self.assertIn('_ageTimer?.cancel();', text)
        self.assertIn('_locationRefreshNote', text)

    def test_geometry_rejects_bore_point_inside_objective(self):
        self.assertIn('objectiveOuterDiameterMm / 2) return null', read('lib/tools/domain/sight_height_geometry.dart'))

    def test_camera_adapter_survives_failed_dispose_and_disables_flash(self):
        text = read('lib/tools/adapters/camera_plugin_service.dart')
        self.assertIn('_disposeQuietly', text)
        self.assertIn('FlashMode.off', text)

    def test_mark_page_has_a_landscape_layout(self):
        text = read('lib/features/tools/sight_height_screen.dart')
        self.assertIn('Orientation.landscape', text)
        self.assertIn('SafeArea(', text)

    def test_ios_orientations_are_declared(self):
        self.assertIn('UIInterfaceOrientationLandscapeLeft', read('tools/configure_ios_info_plist.py'))

    def test_bootstrap_diagnostics_never_precede_or_replace_the_lockfile_upload(self):
        wf = read('.github/workflows/bootstrap-lockfile.yml')
        lock_upload = wf.index('name: sniper-turk-pubspec-lock-flutter-3.47.2')
        for name in ('UNVERIFIED-dart-format-patch', 'UNVERIFIED-validation-logs'):
            self.assertGreater(wf.index(name), lock_upload)
        # Only diagnostics may run on failure; the lockfile upload must not.
        head = wf[:lock_upload]
        self.assertNotIn('if: always()', wf)
        self.assertNotIn('failure()', head)
        self.assertNotIn('continue-on-error', wf)

    def test_flutter_dart_sdk_floor_supports_radiogroup(self):
        self.assertIn("sdk: '>=3.8.0 <4.0.0'", read('pubspec.yaml'))


if __name__ == '__main__':
    unittest.main()
