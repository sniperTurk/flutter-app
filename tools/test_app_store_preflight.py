import hashlib, plistlib, tempfile, unittest
from unittest.mock import patch
from pathlib import Path
from app_store_preflight import check

class AppStorePreflightTest(unittest.TestCase):
    def make_root(self, with_ios=True):
        td = tempfile.TemporaryDirectory(); self.addCleanup(td.cleanup)
        r = Path(td.name)
        (r/'tools').mkdir(); (r/'tools/bootstrap_ios_scaffold.sh').write_text('#!/bin/sh\n')
        (r/'pubspec.yaml').write_text('name: sniper_turk\nversion: 1.0.0+1\n')
        (r/'pubspec.lock').write_text('packages:\n  example:\n    version: 1.0.0\n')
        pub_hash = hashlib.sha256((r/'pubspec.yaml').read_bytes()).hexdigest()
        lock_hash = hashlib.sha256((r/'pubspec.lock').read_bytes()).hexdigest()
        (r/'lockfile-provenance.txt').write_text(
            f'flutter=3.47.2\npubspec_sha256={pub_hash}\nlockfile_sha256={lock_hash}\n'
        )
        (r/'.fvmrc').write_text('{\n  \"flutter\": \"3.47.2\"\n}\n')
        privacy = r/'release/ios/PrivacyInfo.xcprivacy'
        privacy.parent.mkdir(parents=True, exist_ok=True)
        with privacy.open('wb') as f:
            plistlib.dump({
                'NSPrivacyAccessedAPITypes': [{
                    'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults',
                    'NSPrivacyAccessedAPITypeReasons': ['CA92.1'],
                }],
                'NSPrivacyCollectedDataTypes': [],
                'NSPrivacyTracking': False,
                'NSPrivacyTrackingDomains': [],
            }, f)
        if with_ios:
            for rel in [
                'ios/Runner.xcodeproj/project.pbxproj',
                'ios/Runner.xcworkspace/contents.xcworkspacedata',
                'ios/Runner/AppDelegate.swift',
                'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
                'ios/Flutter/Debug.xcconfig',
                'ios/Flutter/Release.xcconfig',
            ]:
                p=r/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text('PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;\nIPHONEOS_DEPLOYMENT_TARGET = 15.0;' if rel.endswith('project.pbxproj') else 'x')
            info = r/'ios/Runner/Info.plist'; info.parent.mkdir(parents=True, exist_ok=True)
            with info.open('wb') as f: plistlib.dump({'CFBundleDisplayName': 'SNIPER TÜRK', 'ITSAppUsesNonExemptEncryption': False}, f)
        return r
    def test_complete_source_contract_passes(self):
        self.assertEqual([], check(self.make_root(), 'https://openai.com/policies/privacy-policy/'))
    def test_v1_release_version_is_enforced(self):
        root = self.make_root()
        (root/'pubspec.yaml').write_text('name: sniper_turk\nversion: 0.1.0+1\n')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('V1 release version must be 1.0.0' in x for x in errors))

    def test_build_number_must_be_positive(self):
        root = self.make_root()
        (root/'pubspec.yaml').write_text('name: sniper_turk\nversion: 1.0.0+0\n')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('semver+positive-build' in x for x in errors))

    def test_missing_or_malformed_source_privacy_manifest_fails(self):
        root = self.make_root()
        manifest = root/'release/ios/PrivacyInfo.xcprivacy'
        manifest.unlink()
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('release/ios/PrivacyInfo.xcprivacy is missing' in x for x in errors))

        root = self.make_root()
        manifest = root/'release/ios/PrivacyInfo.xcprivacy'
        manifest.write_text('not a plist')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('source iOS privacy manifest is unreadable or invalid' in x for x in errors))

    def test_source_privacy_manifest_requires_recognized_reason(self):
        root = self.make_root()
        manifest = root/'release/ios/PrivacyInfo.xcprivacy'
        with manifest.open('wb') as f:
            plistlib.dump({'NSPrivacyAccessedAPITypes': []}, f)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('contains no recognized required-reason API declaration' in x for x in errors))

    def test_missing_privacy_url_fails(self):
        self.assertTrue(any('privacy policy URL' in x for x in check(self.make_root(), None)))
    def test_placeholder_or_non_https_privacy_url_fails(self):
        self.assertTrue(check(self.make_root(), 'http://example.com/privacy'))
        self.assertTrue(check(self.make_root(), 'https://example.com/privacy'))
    def test_reserved_or_local_privacy_hosts_fail(self):
        root = self.make_root()
        for url in ['https://sniperturk.test/privacy', 'https://localhost/privacy', 'https://127.0.0.1/privacy', 'https://10.0.0.5/privacy']:
            with self.subTest(url=url):
                self.assertTrue(any('public HTTPS host' in x for x in check(root, url)))
    def test_missing_or_empty_lockfile_fails(self):
        root = self.make_root()
        (root/'pubspec.lock').unlink()
        self.assertTrue(any('pubspec.lock is missing or empty' in x for x in check(root, 'https://openai.com/policies/privacy-policy/')))
        (root/'pubspec.lock').write_text('')
        self.assertTrue(any('pubspec.lock is missing or empty' in x for x in check(root, 'https://openai.com/policies/privacy-policy/')))
    def test_missing_or_tampered_lockfile_provenance_fails(self):
        root = self.make_root()
        (root/'lockfile-provenance.txt').unlink()
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('lockfile provenance is missing or empty' in x for x in errors))

        root = self.make_root()
        (root/'pubspec.lock').write_text('packages:\n  tampered: {}\n')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('pubspec.lock does not match lockfile provenance' in x for x in errors))


    def test_lockfile_digest_io_failure_fails_closed_without_traceback(self):
        root = self.make_root()
        original = Path.read_bytes

        def flaky_read_bytes(path):
            if path == root / 'pubspec.lock':
                raise OSError('simulated lockfile I/O race')
            return original(path)

        with patch.object(Path, 'read_bytes', flaky_read_bytes):
            errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('pubspec.lock does not match lockfile provenance' in x for x in errors), errors)

    def test_wrong_flutter_lockfile_provenance_fails(self):
        root = self.make_root()
        provenance = root/'lockfile-provenance.txt'
        provenance.write_text(provenance.read_text().replace('flutter=3.47.2', 'flutter=3.46.0'))
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('lockfile provenance must declare Flutter 3.47.2' in x for x in errors))

    def test_flutter_toolchain_must_be_pinned(self):
        root = self.make_root()
        (root/'.fvmrc').unlink()
        self.assertTrue(any('.fvmrc is missing or unreadable' in x for x in check(root, 'https://openai.com/policies/privacy-policy/')))
        (root/'.fvmrc').write_text('{"flutter":"3.46.0"}')
        self.assertTrue(any('.fvmrc must pin Flutter 3.47.2' in x for x in check(root, 'https://openai.com/policies/privacy-policy/')))

    def test_fvmrc_malformed_or_non_object_fails_closed(self):
        root = self.make_root()
        for payload in ['not-json', '[{"flutter":"3.47.2"}]', '{"note":"\\"flutter\\": \\"3.47.2\\""}']:
            with self.subTest(payload=payload):
                (root/'.fvmrc').write_text(payload)
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(any('.fvmrc must' in x for x in errors))
    def test_missing_ios_scaffold_fails(self):
        self.assertTrue(any('iOS scaffold is absent' in x for x in check(self.make_root(False), 'https://openai.com/policies/privacy-policy/')))
    def test_partial_ios_scaffold_fails_closed(self):
        root = self.make_root()
        for rel in [
            'ios/Runner.xcworkspace/contents.xcworkspacedata',
            'ios/Flutter/Debug.xcconfig',
            'ios/Flutter/Release.xcconfig',
        ]:
            with self.subTest(rel=rel):
                candidate = root/rel
                candidate.unlink()
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(any(f'required iOS release file missing: {rel}' in x for x in errors))
                candidate.parent.mkdir(parents=True, exist_ok=True)
                candidate.write_text('x')

    def test_wrong_ios_display_name_fails(self):
        root = self.make_root()
        info = root/'ios/Runner/Info.plist'
        with info.open('wb') as f: plistlib.dump({'CFBundleDisplayName': 'sniper_turk'}, f)
        self.assertTrue(any('CFBundleDisplayName must be SNIPER TÜRK' in x for x in check(root, 'https://openai.com/policies/privacy-policy/')))
    def test_wrong_ios_bundle_identifier_fails(self):
        root = self.make_root()
        pbx = root/'ios/Runner.xcodeproj/project.pbxproj'
        pbx.write_text('PRODUCT_BUNDLE_IDENTIFIER = com.example.sniperTurk;\nIPHONEOS_DEPLOYMENT_TARGET = 15.0;')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('iOS Runner bundle identifier must be com.sniperturk.sniperTurk' in x for x in errors))
        self.assertTrue(any('unexpected iOS bundle identifier(s): com.example.sniperTurk' in x for x in errors))

    def test_detected_camera_capability_requires_usage_description(self):
        root = self.make_root()
        source = root/'lib/features/camera_screen.dart'
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text('final camera = CameraController();')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('NSCameraUsageDescription is required' in x for x in errors))

        info = root/'ios/Runner/Info.plist'
        with info.open('rb') as f: data = plistlib.load(f)
        data['NSCameraUsageDescription'] = 'Fotoğraf çekmek için kamera erişimi gerekir.'
        with info.open('wb') as f: plistlib.dump(data, f)
        self.assertEqual([], check(root, 'https://openai.com/policies/privacy-policy/'))

    def test_detected_motion_capability_requires_usage_description(self):
        root = self.make_root()
        source = root/'lib/level_service.dart'
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text("import 'package:sensors_plus/sensors_plus.dart';")
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('NSMotionUsageDescription is required' in x for x in errors))

        info = root/'ios/Runner/Info.plist'
        with info.open('rb') as f: data = plistlib.load(f)
        data['NSMotionUsageDescription'] = 'Eğim göstermek için hareket sensörü kullanılır.'
        with info.open('wb') as f: plistlib.dump(data, f)
        self.assertEqual([], check(root, 'https://openai.com/policies/privacy-policy/'))

    def test_empty_usage_description_still_fails(self):
        root = self.make_root()
        source = root/'lib/location_service.dart'
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text('final position = Geolocator.getCurrentPosition();')
        info = root/'ios/Runner/Info.plist'
        with info.open('rb') as f: data = plistlib.load(f)
        data['NSLocationWhenInUseUsageDescription'] = '   '
        with info.open('wb') as f: plistlib.dump(data, f)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('NSLocationWhenInUseUsageDescription is required' in x for x in errors))

    def test_runner_tests_bundle_identifier_is_allowed(self):
        root = self.make_root()
        pbx = root/'ios/Runner.xcodeproj/project.pbxproj'
        pbx.write_text('\n'.join([
            'PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;',
            'PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk.RunnerTests;',
            'IPHONEOS_DEPLOYMENT_TARGET = 15.0;',
        ]))
        self.assertEqual([], check(root, 'https://openai.com/policies/privacy-policy/'))


    def test_missing_or_too_old_ios_deployment_target_fails(self):
        root = self.make_root()
        pbx = root/'ios/Runner.xcodeproj/project.pbxproj'
        pbx.write_text('PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('deployment target is missing' in x for x in errors))

        pbx.write_text('PRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;\nIPHONEOS_DEPLOYMENT_TARGET = 14.0;')
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('deployment target must be at least 15.0' in x for x in errors))

    def test_export_compliance_declaration_is_required(self):
        root = self.make_root()
        info = root/'ios/Runner/Info.plist'
        with info.open('rb') as f: data = plistlib.load(f)
        data.pop('ITSAppUsesNonExemptEncryption')
        with info.open('wb') as f: plistlib.dump(data, f)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('ITSAppUsesNonExemptEncryption must be explicitly false' in x for x in errors))

        data['ITSAppUsesNonExemptEncryption'] = True
        with info.open('wb') as f: plistlib.dump(data, f)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('ITSAppUsesNonExemptEncryption must be explicitly false' in x for x in errors))


    def test_release_lock_inputs_reject_symbolic_links(self):
        for rel, expected in [
            ('pubspec.yaml', 'pubspec.yaml must be a regular file'),
            ('pubspec.lock', 'pubspec.lock must be a regular file'),
            ('lockfile-provenance.txt', 'lockfile provenance must be a regular file'),
        ]:
            with self.subTest(rel=rel):
                root = self.make_root()
                target = root / (rel + '.real')
                original = root / rel
                target.write_bytes(original.read_bytes())
                original.unlink()
                original.symlink_to(target.name)
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(any(expected in x for x in errors), errors)


    def test_other_release_inputs_reject_symbolic_links(self):
        cases = [
            ('.fvmrc', '.fvmrc must be a regular file'),
            ('tools/bootstrap_ios_scaffold.sh', 'bootstrap_ios_scaffold.sh must be a regular file'),
            ('release/ios/PrivacyInfo.xcprivacy', 'PrivacyInfo.xcprivacy must be a regular file'),
            ('ios/Runner/Info.plist', 'required iOS release file must be a regular file'),
            ('ios/Runner.xcodeproj/project.pbxproj', 'required iOS release file must be a regular file'),
        ]
        for rel, expected in cases:
            with self.subTest(rel=rel):
                root = self.make_root()
                original = root / rel
                target = original.with_name(original.name + '.real')
                target.write_bytes(original.read_bytes())
                original.unlink()
                original.symlink_to(target.name)
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(any(expected in x for x in errors), errors)


    def test_ios_scaffold_directory_rejects_symbolic_link(self):
        root = self.make_root()
        ios = root/'ios'
        real = root/'ios.real'
        ios.rename(real)
        ios.symlink_to(real.name, target_is_directory=True)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('ios must be a real directory, not a symbolic link' in x for x in errors), errors)


    def test_release_support_directories_reject_symbolic_links(self):
        cases = [
            ('tools', 'tools must be a real directory, not a symbolic link'),
            ('release', 'release must be a real directory, not a symbolic link'),
            ('release/ios', 'release/ios must be a real directory, not a symbolic link'),
        ]
        for rel, expected in cases:
            with self.subTest(rel=rel):
                root = self.make_root()
                original = root / rel
                target = original.with_name(original.name + '.real')
                original.rename(target)
                original.symlink_to(target.name, target_is_directory=True)
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(any(expected in x for x in errors), errors)


    def test_dart_capability_scan_rejects_symbolic_link_source(self):
        root = self.make_root()
        lib = root / 'lib'
        lib.mkdir(parents=True, exist_ok=True)
        external = root / 'external_camera.dart'
        external.write_text('final camera = CameraController();')
        (lib / 'camera.dart').symlink_to(external)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(any('Dart capability scan source must be a regular file' in x for x in errors), errors)

    def test_dart_capability_scan_rejects_symbolic_link_directory(self):
        root = self.make_root()
        lib = root / 'lib'
        lib.mkdir(parents=True, exist_ok=True)
        external = root / 'external_lib'
        external.mkdir()
        (external / 'camera.dart').write_text('final camera = CameraController();')
        (lib / 'linked').symlink_to(external, target_is_directory=True)
        errors = check(root, 'https://openai.com/policies/privacy-policy/')
        self.assertTrue(
            any('Dart capability scan path must not contain symbolic links' in x for x in errors),
            errors,
        )

    def test_nested_ios_scaffold_directories_reject_symbolic_links(self):
        cases = [
            ('ios/Runner.xcodeproj', 'ios/Runner.xcodeproj/project.pbxproj'),
            ('ios/Runner.xcworkspace', 'ios/Runner.xcworkspace/contents.xcworkspacedata'),
            ('ios/Runner', 'ios/Runner/Info.plist'),
            ('ios/Flutter', 'ios/Flutter/Release.xcconfig'),
        ]
        for directory, affected in cases:
            with self.subTest(directory=directory):
                root = self.make_root()
                original = root / directory
                target = original.with_name(original.name + '.real')
                original.rename(target)
                original.symlink_to(target.name, target_is_directory=True)
                errors = check(root, 'https://openai.com/policies/privacy-policy/')
                self.assertTrue(
                    any(
                        'required iOS release path must not contain symbolic links' in x
                        and affected in x
                        for x in errors
                    ),
                    errors,
                )


if __name__ == '__main__': unittest.main()
