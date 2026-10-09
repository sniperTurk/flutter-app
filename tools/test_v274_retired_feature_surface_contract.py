"""V1 regression: what stays retired after M1 (rewritten).

WHY THIS FILE CHANGED: v274 forbade any source file or dependency named
chronograph / sight_height / compass / pusula / level / camera / sensors_plus /
flutter_compass. Those four tools are back in V1 scope, so those tokens and
the camera/sensor packages are now allowed -- but only in the places listed
here. The audio-recording and photo-library surfaces stay forbidden.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

# Only these feature files may carry tool names.
ALLOWED_TOOL_FILES = {
    'lib/features/tools/sight_height_screen.dart',
    'lib/features/tools/compass_screen.dart',
    'lib/features/tools/level_screen.dart',
    'lib/tools/domain/chronograph_stats.dart',
    'lib/tools/domain/sight_height_geometry.dart',
    'lib/tools/domain/compass_math.dart',
    'lib/tools/adapters/flutter_compass_heading_provider.dart',
    'lib/tools/state/compass_controller.dart',
    # M2 design pass (Sight Height page art, physical method, diagrams).
    'lib/ui/sight_height_art.dart',
    'lib/tools/domain/sight_height_physical.dart',
    'lib/features/tools/sight_height_diagrams.dart',
}


class RetiredFeatureSurfaceContractTests(unittest.TestCase):
    def test_tool_named_files_exist_only_in_the_tools_tree(self):
        tokens = ('chronograph', 'chronograf', 'sight_height', 'sightheight', 'compass', 'pusula',
                  'bubble_level', 'spirit_level', 'field_tools')
        offenders = []
        for base in (ROOT / 'lib', ROOT / 'native'):
            if not base.exists():
                continue
            for path in base.rglob('*'):
                if path.is_file():
                    rel = path.relative_to(ROOT).as_posix()
                    if any(t in rel.lower() for t in tokens) and rel not in ALLOWED_TOOL_FILES:
                        offenders.append(rel)
        self.assertEqual([], offenders)
        for rel in ALLOWED_TOOL_FILES:
            self.assertTrue((ROOT / rel).is_file(), rel)

    def test_home_has_no_direct_tool_routes(self):
        home = (ROOT / 'lib/features/home/home_screen.dart').read_text(encoding='utf-8').lower()
        for forbidden in ('chronographscreen', 'sightheightscreen', 'compassscreen', 'levelscreen', 'fieldtoolsscreen'):
            self.assertNotIn(forbidden, home)

    def test_audio_and_photo_library_dependencies_stay_absent(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8').lower()
        for dependency in ('record:', 'flutter_sound:', 'path_provider:', 'permission_handler:'):
            self.assertNotIn(dependency, pubspec)

    def test_no_microphone_or_photo_library_use_in_code(self):
        # Camera is opened with audio disabled and photos stay in memory.
        for path in (ROOT / 'lib').rglob('*.dart'):
            text = path.read_text(encoding='utf-8')
            self.assertNotIn('enableAudio: true', text, path)
            for forbidden in ('saveImage', 'GallerySaver', 'AudioRecorder'):
                self.assertNotIn(forbidden, text, path)
            # M2: ImagePicker (pick-only) is confined to the gallery adapter
            # and its wiring; it may never save or request full metadata.
            rel = path.relative_to(ROOT).as_posix()
            if 'ImagePicker' in text:
                self.assertIn(rel, {'lib/tools/adapters/image_picker_photo_picker.dart',
                                    'lib/tools/tools_services.dart'}, rel)
                self.assertNotIn('requestFullMetadata: true', text, rel)
        adapter = (ROOT / 'lib/tools/adapters/camera_plugin_service.dart').read_text(encoding='utf-8')
        self.assertIn('enableAudio: false', adapter)

    def test_manual_ballistic_sight_height_is_still_a_core_input(self):
        ballistic_input = (ROOT / 'lib/core/ballistic_input.dart').read_text(encoding='utf-8')
        self.assertIn('sightHeightMm', ballistic_input)


if __name__ == '__main__':
    unittest.main()
