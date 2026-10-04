import unittest
from pathlib import Path

class IOSCIPrivacyManifestWiringTest(unittest.TestCase):
    def test_archive_privacy_gate_runs_after_archive_and_before_upload(self):
        workflow=Path('.github/workflows/ios-ci.yml').read_text()
        build=workflow.index('flutter build ipa --release --no-codesign')
        gate=workflow.index('python3 tools/verify_ios_privacy_manifests.py --archive')
        upload=workflow.index('- name: Upload validated unsigned App Store archive')
        self.assertLess(build, gate); self.assertLess(gate, upload)
        self.assertIn('--require-runner-manifest', workflow[gate:upload])
