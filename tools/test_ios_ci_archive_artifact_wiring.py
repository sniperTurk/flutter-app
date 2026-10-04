import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'ios-ci.yml'

class IosCiArchiveArtifactWiringTest(unittest.TestCase):
    def test_validated_archive_is_retained_fail_closed(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        build = text.index('- name: Build unsigned App Store archive')
        upload = text.index('- name: Upload validated unsigned App Store archive')
        failure_logs = text.index('- name: Upload build logs on failure')
        self.assertLess(build, upload)
        self.assertLess(upload, failure_logs)
        block = text[upload:failure_logs]
        self.assertIn('uses: actions/upload-artifact@v7', block)
        self.assertIn('path: build/ios/archive/Runner.xcarchive', block)
        self.assertIn('if-no-files-found: error', block)
        self.assertIn('retention-days: 7', block)

if __name__ == '__main__':
    unittest.main()
