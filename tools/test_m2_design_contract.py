"""M2 design pass: contracts for the Menzil design pages (Sight Height, Su Terazisi).

Source-text contracts only; they do not replace flutter test / device checks.
"""
from pathlib import Path
import plistlib
import tempfile
import importlib.util
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib'


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class SightHeightDesignContract(unittest.TestCase):
    def setUp(self):
        self.text = read('lib/features/tools/sight_height_screen.dart')

    def test_two_independent_methods_exist(self):
        for key in ('sight-parts', 'sight-bore', 'sight-wall', 'sight-gap', 'sight-objective',
                    'sight-total', 'sight-photo-section', 'sight-capture-side', 'sight-gallery'):
            self.assertIn(f"Key('{key}')", self.text)
        self.assertIn("label: 'Fotoğraf çek'", self.text)
        self.assertIn("label: 'Galeriden seç'", self.text)

    def test_physical_method_does_not_depend_on_photo_or_camera(self):
        body = read('lib/tools/domain/sight_height_physical.dart')
        for token in ('camera', 'photo', 'Photo', 'image_picker', 'Vision'):
            self.assertNotIn(token, body)
        self.assertIn('boreDiameterMm / 2', body)
        self.assertIn('objectiveOuterDiameterMm / 2', body)

    def test_objective_is_outer_housing_diameter_not_glass_size(self):
        self.assertIn('OUTER', self.text)
        self.assertIn('model adındaki cam çapı', self.text)

    def test_muzzle_warning_and_fine_adjust_and_semantics_kept(self):
        for token in ('sight-muzzle-warning', 'sight-inclined-mount', '_nudgeSelected', 'minWidth: 44',
                      'Seçili işaret', 'sight-not-landscape', 'sight-apply-preview', 'Semantics('):
            self.assertIn(token, self.text)

    def test_vision_stays_optional_and_disconnected(self):
        self.assertIn("Key('sight-vision-off')", self.text)
        port = read('lib/tools/ports/vision_assist.dart')
        self.assertIn('bool get isConnected => false;', port)

    def test_profile_is_never_written_without_confirmation(self):
        self.assertIn('_ApplyDialog', self.text)
        self.assertIn('Uygula', self.text)


class ToolsHubSightHeightContract(unittest.TestCase):
    def test_hub_does_not_claim_removed_front_photo(self):
        text = read('lib/features/tools/tools_screen.dart')
        self.assertIn('fiziksel ölçüm veya yan fotoğraf', text)
        self.assertNotIn('yan ve ön fotoğraf', text)


class GalleryContract(unittest.TestCase):
    def test_image_picker_is_pick_only_and_confined(self):
        pub = read('pubspec.yaml')
        self.assertIn('image_picker:', pub)
        users = [p.relative_to(ROOT).as_posix() for p in LIB.rglob('*.dart')
                 if "package:image_picker" in p.read_text(encoding='utf-8')]
        self.assertEqual(['lib/tools/adapters/image_picker_photo_picker.dart'], users)
        adapter = read('lib/tools/adapters/image_picker_photo_picker.dart')
        self.assertIn('ImageSource.gallery', adapter)
        self.assertIn('requestFullMetadata: false', adapter)
        self.assertNotIn('ImageSource.camera', adapter)

    def test_photos_are_not_persisted(self):
        for rel in ('lib/features/tools/sight_height_screen.dart',
                    'lib/tools/adapters/image_picker_photo_picker.dart'):
            text = read(rel)
            for forbidden in ('writeAsBytes', 'SharedPreferences', 'saveImage', 'GallerySaver'):
                self.assertNotIn(forbidden, text, rel)

    def test_plist_declares_photo_library_text_and_never_add_permission(self):
        spec = importlib.util.spec_from_file_location('cfg', ROOT / 'tools/configure_ios_info_plist.py')
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'Info.plist'
            path.write_bytes(plistlib.dumps({'NSPhotoLibraryAddUsageDescription': 'old'}))
            mod.configure(path)
            data = plistlib.loads(path.read_bytes())
        self.assertIn('Sight Height', data['NSPhotoLibraryUsageDescription'])
        self.assertNotIn('NSPhotoLibraryAddUsageDescription', data)


class LevelDesignContract(unittest.TestCase):
    def test_circle_and_both_tubes_use_one_green_liquid_token(self):
        text = read('lib/features/tools/level_screen.dart')
        for key in ('level-circle', 'level-tube-x', 'level-tube-y', 'level-set-reference', 'level-clear-reference'):
            self.assertIn(f"Key('{key}')", text)
        self.assertIn('levelLiquid', text)
        self.assertIn("'Referansı bu konuma ayarla'", text)
        self.assertIn("'Temizle'", text)
        self.assertNotIn('Color(0x', text)

    def test_level_math_is_orientation_independent(self):
        math = read('lib/tools/domain/tilt_math.dart')
        self.assertIn('asin', math)


class ProductionBoundaryUntouched(unittest.TestCase):
    def test_acceptance_hash_unchanged(self):
        import hashlib
        h = hashlib.sha256((ROOT / 'validation/acceptance.json').read_bytes()).hexdigest()
        self.assertEqual('1d861282a0ed6bca503ec8fa7c11eb423c2d5d9704b0d383c51cfd1b7c67927d', h)


if __name__ == '__main__':
    unittest.main()
