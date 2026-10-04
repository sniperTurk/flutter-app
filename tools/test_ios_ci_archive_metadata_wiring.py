#!/usr/bin/env python3
"""Regression contract for App Store archive metadata validation in iOS CI."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'ios-ci.yml'


class IosCiArchiveMetadataWiringTest(unittest.TestCase):
    def test_archive_metadata_is_fail_closed(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        archive = text.index('- name: Build unsigned App Store archive')
        diagnostics = text.index('- name: Upload build logs on failure')
        block = text[archive:diagnostics]
        required = [
            'APP_INFO="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Info.plist"',
            'CFBundleShortVersionString',
            'CFBundleVersion',
            'CFBundleDisplayName',
            'ITSAppUsesNonExemptEncryption',
            'MinimumOSVersion',
            'expected iOS 15.0 or newer',
            'PUBSPEC_VERSION="$(awk',
            'EXPECTED_MARKETING_VERSION="${PUBSPEC_VERSION%%+*}"',
            'EXPECTED_BUILD_NUMBER="${PUBSPEC_VERSION##*+}"',
            'EXPECTED_DISPLAY_NAME="SNIPER TÜRK"',
        ]
        for needle in required:
            with self.subTest(needle=needle):
                self.assertIn(needle, block)
        self.assertNotIn('EXPECTED_MARKETING_VERSION="1.0.0"', block)
        self.assertNotIn('EXPECTED_BUILD_NUMBER="1"', block)
        self.assertIn('Invalid pubspec release version', block)
        self.assertIn('[[ "$ARCHIVE_MARKETING_VERSION" == "$EXPECTED_MARKETING_VERSION" ]]', block)
        self.assertIn('[[ "$ARCHIVE_BUILD_NUMBER" == "$EXPECTED_BUILD_NUMBER" ]]', block)
        self.assertIn('[[ "$ARCHIVE_DISPLAY_NAME" == "$EXPECTED_DISPLAY_NAME" ]]', block)
        self.assertIn('[[ "$ARCHIVE_EXPORT_COMPLIANCE" == "false" ]]', block)


if __name__ == '__main__':
    unittest.main()
