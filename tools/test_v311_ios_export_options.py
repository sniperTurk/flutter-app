#!/usr/bin/env python3
from pathlib import Path
import plistlib, tempfile, unittest
from unittest import mock
import generate_ios_export_options as mod

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github/workflows/ios-ci.yml'

class ExportOptionsTest(unittest.TestCase):
    def test_payload_is_app_store_connect_and_team_bound(self):
        p = mod.build('A1B2C3D4E5')
        self.assertEqual(p['method'], 'app-store-connect')
        self.assertEqual(p['signingStyle'], 'automatic')
        self.assertEqual(p['teamID'], 'A1B2C3D4E5')
        self.assertFalse(p['manageAppVersionAndBuildNumber'])

    def test_invalid_team_fails_closed(self):
        for value in ('', 'ABCDE', 'abcdefghij', 'ABCDEFGHIJK', 'ABC-123456'):
            with self.assertRaises(ValueError): mod.build(value)

    def test_atomic_writer_leaves_parseable_plist(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / 'ExportOptions.plist'
            mod.write_atomic(out, mod.build('A1B2C3D4E5'))
            with out.open('rb') as fh: payload = plistlib.load(fh)
            self.assertEqual(payload['teamID'], 'A1B2C3D4E5')

    def test_ci_generates_options_only_when_owner_team_is_configured(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        marker = '- name: Generate App Store export options when signing is configured'
        self.assertIn(marker, text)
        block = text[text.index(marker):]
        self.assertIn("if: ${{ vars.IOS_DEVELOPMENT_TEAM != '' }}", block)
        self.assertIn('SNIPER_TURK_IOS_DEVELOPMENT_TEAM: ${{ vars.IOS_DEVELOPMENT_TEAM }}', block)
        self.assertIn('python3 tools/generate_ios_export_options.py', block)

if __name__ == '__main__': unittest.main()
