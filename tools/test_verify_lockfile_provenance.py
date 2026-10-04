#!/usr/bin/env python3
from pathlib import Path
import hashlib
import tempfile
import unittest

from verify_lockfile_provenance import verify


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class VerifyLockfileProvenanceTest(unittest.TestCase):
    def fixture(self):
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        pub = b"name: sniper_turk\n"
        lock = b"packages: {}\n"
        (root / "pubspec.yaml").write_bytes(pub)
        (root / "pubspec.lock").write_bytes(lock)
        (root / "lockfile-provenance.txt").write_text(
            f"flutter=3.47.2\npubspec_sha256={digest(pub)}\nlockfile_sha256={digest(lock)}\n",
            encoding="utf-8",
        )
        return temp, root

    def test_valid_provenance_passes(self):
        temp, root = self.fixture()
        with temp:
            self.assertEqual([], verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt'))

    def test_stale_pubspec_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            (root/'pubspec.yaml').write_text('name: changed\n', encoding='utf-8')
            self.assertTrue(any('pubspec.yaml SHA-256' in x for x in verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt')))

    def test_tampered_lockfile_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            (root/'pubspec.lock').write_text('tampered\n', encoding='utf-8')
            self.assertTrue(any('pubspec.lock SHA-256' in x for x in verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt')))

    def test_wrong_flutter_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            p = root/'lockfile-provenance.txt'
            p.write_text(p.read_text().replace('flutter=3.47.2', 'flutter=3.46.0'), encoding='utf-8')
            self.assertTrue(any('Flutter provenance' in x for x in verify(root/'pubspec.yaml', root/'pubspec.lock', p)))

    def test_unknown_or_duplicate_keys_are_rejected(self):
        temp, root = self.fixture()
        with temp:
            p = root/'lockfile-provenance.txt'
            p.write_text(p.read_text() + 'flutter=3.47.2\njunk=value\n', encoding='utf-8')
            errors = verify(root/'pubspec.yaml', root/'pubspec.lock', p)
            self.assertTrue(any('duplicate provenance key' in x for x in errors))
            self.assertTrue(any('unknown provenance key' in x for x in errors))

    def test_symlinked_pubspec_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            real = root / "real-pubspec.yaml"
            (root / "pubspec.yaml").replace(real)
            (root / "pubspec.yaml").symlink_to(real)
            errors = verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt')
            self.assertTrue(any('pubspec.yaml must not be a symbolic link' in x for x in errors))

    def test_symlinked_lockfile_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            real = root / "real-pubspec.lock"
            (root / "pubspec.lock").replace(real)
            (root / "pubspec.lock").symlink_to(real)
            errors = verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt')
            self.assertTrue(any('pubspec.lock must not be a symbolic link' in x for x in errors))

    def test_symlinked_provenance_is_rejected(self):
        temp, root = self.fixture()
        with temp:
            real = root / "real-provenance.txt"
            (root / "lockfile-provenance.txt").replace(real)
            (root / "lockfile-provenance.txt").symlink_to(real)
            errors = verify(root/'pubspec.yaml', root/'pubspec.lock', root/'lockfile-provenance.txt')
            self.assertTrue(any('lockfile provenance must not be a symbolic link' in x for x in errors))


if __name__ == '__main__':
    unittest.main()
