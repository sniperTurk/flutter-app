import plistlib, tempfile, unittest
from pathlib import Path
from configure_ios_info_plist import DISPLAY_NAME, USAGE_DESCRIPTIONS, USES_NON_EXEMPT_ENCRYPTION, configure

class ConfigureIosInfoPlistTests(unittest.TestCase):
    def test_sets_display_name_and_preserves_existing_keys(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Info.plist"
            with p.open("wb") as f:
                plistlib.dump({"CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)", "KeepMe": True}, f)
            configure(p)
            with p.open("rb") as f:
                data = plistlib.load(f)
            self.assertEqual(DISPLAY_NAME, data["CFBundleDisplayName"])
            self.assertIs(False, data["ITSAppUsesNonExemptEncryption"])
            self.assertIs(False, USES_NON_EXEMPT_ENCRYPTION)
            self.assertTrue(data["KeepMe"])
            self.assertEqual("$(PRODUCT_BUNDLE_IDENTIFIER)", data["CFBundleIdentifier"])

    def test_sets_m1_usage_descriptions_and_drops_photo_library_write_access(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Info.plist"
            with p.open("wb") as f:
                plistlib.dump({"NSPhotoLibraryAddUsageDescription": "old", "NSCameraUsageDescription": "old"}, f)
            configure(p)
            with p.open("rb") as f:
                data = plistlib.load(f)
            self.assertNotIn("NSPhotoLibraryAddUsageDescription", data)
            for key in ("NSLocationWhenInUseUsageDescription", "NSLocationAlwaysAndWhenInUseUsageDescription", "NSCameraUsageDescription", "NSMotionUsageDescription", "NSMicrophoneUsageDescription", "NSPhotoLibraryUsageDescription"):
                self.assertTrue(data[key].strip())
                self.assertEqual(USAGE_DESCRIPTIONS[key], data[key])
            # The Always-and-WhenInUse text exists only for ITMS-90683 (plugin
            # binary reference) and must say no background location is used.
            self.assertIn("arka planda konum kullanmaz", data["NSLocationAlwaysAndWhenInUseUsageDescription"])
            # No legacy always-only location key and no photo-library write access.
            for key in ("NSLocationAlwaysUsageDescription", "NSPhotoLibraryAddUsageDescription"):
                self.assertNotIn(key, data)

    def test_declares_landscape_for_the_sight_height_capture_page(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "Info.plist"
            with p.open("wb") as f:
                plistlib.dump({"UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                               "UISupportedInterfaceOrientations~ipad": []}, f)
            configure(p)
            with p.open("rb") as f:
                data = plistlib.load(f)
            self.assertIn("UIInterfaceOrientationLandscapeLeft", data["UISupportedInterfaceOrientations"])
            self.assertIn("UIInterfaceOrientationLandscapeRight", data["UISupportedInterfaceOrientations"])
            self.assertIn("UIInterfaceOrientationPortrait", data["UISupportedInterfaceOrientations"])
            self.assertEqual(4, len(data["UISupportedInterfaceOrientations~ipad"]))

    def test_missing_file_fails(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(FileNotFoundError):
                configure(Path(d) / "missing.plist")

if __name__ == "__main__":
    unittest.main()
