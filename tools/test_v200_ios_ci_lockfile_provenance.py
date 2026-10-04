import unittest
from pathlib import Path


class IOSCILockfileProvenanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = Path('.github/workflows/ios-ci.yml').read_text()

    def test_release_ci_verifies_lockfile_provenance(self):
        self.assertIn('python3 tools/verify_lockfile_provenance.py', self.workflow)

    def test_provenance_is_checked_before_flutter_install_and_dependency_resolution(self):
        verify = self.workflow.index('python3 tools/verify_lockfile_provenance.py')
        setup = self.workflow.index('uses: subosito/flutter-action@v2')
        resolve = self.workflow.index('flutter pub get')
        self.assertLess(verify, setup)
        self.assertLess(verify, resolve)

    def test_lockfile_existence_gate_precedes_provenance(self):
        existence = self.workflow.index('test -s pubspec.lock')
        verify = self.workflow.index('python3 tools/verify_lockfile_provenance.py')
        self.assertLess(existence, verify)


if __name__ == '__main__':
    unittest.main()
