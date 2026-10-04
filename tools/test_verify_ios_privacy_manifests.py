import plistlib, tempfile, unittest
from pathlib import Path
from verify_ios_privacy_manifests import verify, warnings

class IOSPrivacyManifestGateTest(unittest.TestCase):
    def make_archive(self):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        root = Path(tmp.name) / "Runner.xcarchive"; root.mkdir()
        (root / "Products/Applications/Runner.app").mkdir(parents=True)
        return root
    def write(self, root, payload):
        path = root / "Products/Applications/Runner.app/Frameworks/shared_preferences.framework/PrivacyInfo.xcprivacy"
        path.parent.mkdir(parents=True)
        with path.open("wb") as fh: plistlib.dump(payload, fh)
    def test_missing_manifest_fails(self):
        self.assertTrue(any("no PrivacyInfo" in e for e in verify(self.make_archive())))
    def test_empty_required_reason_fails(self):
        root=self.make_archive(); self.write(root, {"NSPrivacyAccessedAPITypes": []})
        self.assertTrue(any("no recognized" in e for e in verify(root)))
    def test_valid_required_reason_passes(self):
        root=self.make_archive(); self.write(root, {"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["CA92.1"]}]})
        self.assertEqual([], verify(root))

    def test_manifest_outside_runner_app_does_not_satisfy_gate(self):
        root=self.make_archive()
        path=root/"dSYMs/Unrelated.framework.dSYM/PrivacyInfo.xcprivacy"
        path.parent.mkdir(parents=True)
        with path.open("wb") as fh:
            plistlib.dump({"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["CA92.1"]}]}, fh)
        self.assertTrue(any("Runner.app" in e for e in verify(root)))

    def test_unknown_reason_code_fails_closed(self):
        root=self.make_archive()
        self.write(root, {"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["NOT-A-REAL-REASON"]}]})
        self.assertTrue(any("no recognized" in e for e in verify(root)))

    def test_malformed_manifest_fails_closed(self):
        root=self.make_archive(); p=root/"Products/Applications/Runner.app/PrivacyInfo.xcprivacy"; p.write_text("not a plist")
        errors=verify(root); self.assertTrue(any("invalid privacy" in e for e in errors))

    GOOD = {"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["CA92.1"]}]}

    def raw(self, root, rel, data):
        p = root/"Products/Applications/Runner.app"/rel
        p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)

    def test_truncated_xml_plist_is_reported_cleanly_not_as_traceback(self):
        root=self.make_archive()
        self.raw(root, "PrivacyInfo.xcprivacy", b'<?xml version="1.0"?><plist><dict><key>a</key>')
        errors=verify(root)  # must return errors, not raise ExpatError
        self.assertTrue(any("invalid privacy manifest" in e and "ExpatError" in e for e in errors), errors)

    def test_junk_reason_next_to_valid_reason_fails_closed(self):
        root=self.make_archive()
        self.write(root, {"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["CA92.1","JUNK"]}]})
        self.assertTrue(any("malformed required-reason code" in e for e in verify(root)))

    def test_other_well_formed_apple_reason_codes_are_not_rejected(self):
        root=self.make_archive()
        self.write(root, {"NSPrivacyAccessedAPITypes":[
            {"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryUserDefaults","NSPrivacyAccessedAPITypeReasons":["CA92.1","1C8F.1"]},
            {"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryFileTimestamp","NSPrivacyAccessedAPITypeReasons":["C617.1"]}]})
        self.assertEqual([], verify(root))

    def test_structurally_malformed_entries_fail_closed(self):
        for payload in ({"NSPrivacyAccessedAPITypes": "x"},
                        {"NSPrivacyAccessedAPITypes": ["x"]},
                        {"NSPrivacyAccessedAPITypes": [{"NSPrivacyAccessedAPITypeReasons": ["CA92.1"]}]},
                        {"NSPrivacyAccessedAPITypes": [{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults", "NSPrivacyAccessedAPITypeReasons": "CA92.1"}]}):
            with self.subTest(payload=payload):
                root=self.make_archive(); self.write(root, payload)
                self.assertTrue(any("invalid privacy manifest" in e for e in verify(root)))

    def test_wrong_category_with_valid_reason_fails(self):
        root=self.make_archive()
        self.write(root, {"NSPrivacyAccessedAPITypes":[{"NSPrivacyAccessedAPIType":"NSPrivacyAccessedAPICategoryFileTimestamp","NSPrivacyAccessedAPITypeReasons":["CA92.1"]}]})
        self.assertTrue(any("no recognized" in e for e in verify(root)))

    def test_valid_manifest_plus_corrupt_second_manifest_fails(self):
        root=self.make_archive(); self.write(root, self.GOOD)
        self.raw(root, "Frameworks/y.framework/PrivacyInfo.xcprivacy", b"junk")
        self.assertTrue(any("invalid privacy manifest" in e for e in verify(root)))

    def test_runner_own_manifest_is_warning_by_default_and_error_when_required(self):
        root=self.make_archive(); self.write(root, self.GOOD)  # plugin-only manifest
        self.assertEqual([], verify(root))
        self.assertTrue(warnings(root))
        self.assertTrue(any("own manifest" in e for e in verify(root, require_runner_manifest=True)))
        self.raw(root, "PrivacyInfo.xcprivacy", plistlib.dumps({"NSPrivacyTracking": False}))
        self.assertEqual([], verify(root, require_runner_manifest=True))
        self.assertEqual([], warnings(root))

    def test_cli_exit_codes_and_no_traceback(self):
        import subprocess, sys
        script = Path(__file__).with_name("verify_ios_privacy_manifests.py")
        root=self.make_archive()
        self.raw(root, "PrivacyInfo.xcprivacy", b'<?xml version="1.0"?><plist><dict>')
        r=subprocess.run([sys.executable, str(script), "--archive", str(root)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 1); self.assertNotIn("Traceback", r.stderr); self.assertIn("BLOCKED", r.stdout)
        good=self.make_archive(); self.write(good, self.GOOD)
        r=subprocess.run([sys.executable, str(script), "--archive", str(good)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0); self.assertIn("PASS", r.stdout); self.assertIn("WARNING", r.stdout)


if __name__ == '__main__':
    unittest.main()
