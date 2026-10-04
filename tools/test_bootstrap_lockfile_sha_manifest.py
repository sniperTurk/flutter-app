from pathlib import Path
import unittest


class BootstrapLockfileShaManifestTest(unittest.TestCase):
    def test_workflow_emits_and_uploads_two_file_sha256_manifest(self):
        text = Path('.github/workflows/bootstrap-lockfile.yml').read_text(encoding='utf-8')
        self.assertIn('shasum -a 256 pubspec.lock lockfile-provenance.txt > lockfile-sha256.txt', text)
        self.assertIn('test "$(wc -l < lockfile-sha256.txt | tr -d \' \')" = "2"', text)
        self.assertIn('lockfile-sha256.txt', text)


if __name__ == '__main__':
    unittest.main()
