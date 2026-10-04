#!/usr/bin/env python3
"""Regression guard for the unsigned App Store archive stage in iOS CI."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'ios-ci.yml'


class IosCiArchiveWiringTest(unittest.TestCase):
    def test_unsigned_archive_is_built_after_device_build(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        device = text.index('- name: Build unsigned iOS device app')
        archive = text.index('- name: Build unsigned App Store archive')
        self.assertLess(device, archive)
        block = text[archive:]
        self.assertIn('flutter build ipa --release --no-codesign', block)
        self.assertIn('build/ios/archive/Runner.xcarchive/Info.plist', block)
        self.assertIn("ApplicationProperties:CFBundleIdentifier'", block)
        self.assertIn('com.sniperturk.sniperTurk', block)


if __name__ == '__main__':
    unittest.main()
