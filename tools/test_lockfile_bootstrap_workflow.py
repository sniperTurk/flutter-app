#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'bootstrap-lockfile.yml'


class LockfileBootstrapWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = WORKFLOW.read_text(encoding='utf-8')

    def test_is_manual_read_only_workflow(self):
        self.assertIn('workflow_dispatch:', self.text)
        self.assertIn('contents: read', self.text)
        self.assertNotIn('contents: write', self.text)

    def test_uses_exact_release_flutter(self):
        self.assertIn("flutter-version: '3.47.2'", self.text)
        self.assertIn('python3 tools/verify_flutter_toolchain.py', self.text)

    def test_generates_and_rechecks_lockfile(self):
        self.assertIn('rm -f pubspec.lock', self.text)
        self.assertGreaterEqual(self.text.count('flutter pub get'), 2)
        self.assertIn('test -s pubspec.lock', self.text)
        self.assertIn('BEFORE=', self.text)
        self.assertIn('AFTER=', self.text)

    def test_does_not_mutate_pubspec(self):
        self.assertIn('git diff --exit-code -- pubspec.yaml', self.text)

    def test_exports_lockfile_as_artifact(self):
        self.assertIn('pubspec.lock', self.text)
        self.assertIn('path: |', self.text)
        self.assertIn('if-no-files-found: error', self.text)

    def test_exports_lockfile_provenance_with_canonical_writer(self):
        self.assertIn('lockfile-provenance.txt', self.text)
        self.assertIn('python3 tools/write_lockfile_provenance.py --flutter-version 3.47.2', self.text)
        self.assertNotIn('echo \"flutter=3.47.2\"', self.text)
        self.assertNotIn('pubspec_sha256=$(shasum', self.text)
        self.assertNotIn('lockfile_sha256=$(shasum', self.text)

    def test_writer_runs_after_resolver_stability_check(self):
        stability_at = self.text.index('[[ \"$BEFORE\" == \"$AFTER\" ]]')
        writer_at = self.text.index('python3 tools/write_lockfile_provenance.py')
        self.assertLess(stability_at, writer_at)

    def test_verifies_provenance_before_upload(self):
        verify_at = self.text.index('python3 tools/verify_lockfile_provenance.py')
        upload_at = self.text.index('- name: Upload generated lockfile')
        self.assertLess(verify_at, upload_at)

    def test_artifact_contains_lockfile_and_provenance(self):
        upload = self.text.split('- name: Upload generated lockfile', 1)[1]
        self.assertIn('pubspec.lock', upload)
        self.assertIn('lockfile-provenance.txt', upload)
        self.assertIn('if-no-files-found: error', upload)


if __name__ == '__main__':
    unittest.main()
