import importlib.util
import pathlib
import unittest

PATH = pathlib.Path(__file__).with_name('install_pinned_flutter.py')
spec = importlib.util.spec_from_file_location('install_pinned_flutter', PATH)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class InstallPinnedFlutterTests(unittest.TestCase):
    def test_selects_exact_stable_x64_release(self):
        payload = {'releases': [
            {'version': '3.47.2', 'channel': 'beta', 'dart_sdk_arch': 'x64', 'archive': 'beta'},
            {'version': '3.47.2', 'channel': 'stable', 'dart_sdk_arch': 'arm64', 'archive': 'arm'},
            {'version': '3.47.2', 'channel': 'stable', 'dart_sdk_arch': 'x64', 'archive': 'x64'},
        ]}
        self.assertEqual(mod.select_release(payload, '3.47.2', 'x86_64')['archive'], 'x64')

    def test_selects_exact_stable_arm64_release(self):
        payload = {'releases': [
            {'version': '3.47.2', 'channel': 'stable', 'dart_sdk_arch': 'x64', 'archive': 'x64'},
            {'version': '3.47.2', 'channel': 'stable', 'dart_sdk_arch': 'arm64', 'archive': 'arm'},
        ]}
        self.assertEqual(mod.select_release(payload, '3.47.2', 'arm64')['archive'], 'arm')

    def test_rejects_missing_version(self):
        with self.assertRaisesRegex(ValueError, 'not present'):
            mod.select_release({'releases': []}, '3.47.2', 'x86_64')

    def test_rejects_wrong_architecture(self):
        payload = {'releases': [
            {'version': '3.47.2', 'channel': 'stable', 'dart_sdk_arch': 'arm64', 'archive': 'arm'},
        ]}
        with self.assertRaisesRegex(ValueError, 'no archive'):
            mod.select_release(payload, '3.47.2', 'x86_64')

    def test_rejects_unsupported_host_architecture(self):
        with self.assertRaisesRegex(ValueError, 'unsupported host architecture'):
            mod._arch_candidates('sparc')

    def test_rejects_non_object_manifest_root(self):
        with self.assertRaisesRegex(ValueError, 'root must be an object'):
            mod.select_release([], '3.47.2', 'x86_64')

    def test_rejects_non_list_releases(self):
        with self.assertRaisesRegex(ValueError, 'releases must be a list'):
            mod.select_release({'releases': {}}, '3.47.2', 'x86_64')

    def test_rejects_non_object_release_entry(self):
        with self.assertRaisesRegex(ValueError, 'non-object release entry'):
            mod.select_release({'releases': ['broken']}, '3.47.2', 'x86_64')



    def test_tar_extraction_uses_explicit_filter_for_python_314_stability(self):
        import unittest.mock
        import tempfile
        import tarfile
        with tempfile.TemporaryDirectory() as tmp:
            out = pathlib.Path(tmp) / 'out'
            out.mkdir()
            member = tarfile.TarInfo('flutter/bin/flutter')
            member.size = 0
            fake = unittest.mock.Mock()
            fake.getmembers.return_value = [member]
            mod._safe_extract_tar(fake, out)
            fake.extractall.assert_called_once_with(out.resolve(), filter='fully_trusted')

if __name__ == '__main__':
    unittest.main()

class SafeTarExtractionTests(unittest.TestCase):
    def _archive(self, tmp, member):
        import io, tarfile
        archive = pathlib.Path(tmp) / 'x.tar.gz'
        with tarfile.open(archive, 'w:gz') as tf:
            if member.isfile():
                member.size = 1
                tf.addfile(member, io.BytesIO(b'x'))
            else:
                tf.addfile(member)
        return archive

    def test_rejects_parent_traversal_member(self):
        import tarfile, tempfile
        with tempfile.TemporaryDirectory() as d:
            member = tarfile.TarInfo('../escape')
            archive = self._archive(d, member)
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with tarfile.open(archive, 'r:*') as tf:
                with self.assertRaisesRegex(ValueError, 'path traversal'):
                    mod._safe_extract_tar(tf, out)
            self.assertFalse((pathlib.Path(d) / 'escape').exists())

    def test_rejects_escaping_symlink(self):
        import tarfile, tempfile
        with tempfile.TemporaryDirectory() as d:
            member = tarfile.TarInfo('flutter/link')
            member.type = tarfile.SYMTYPE
            member.linkname = '../../escape'
            archive = self._archive(d, member)
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with tarfile.open(archive, 'r:*') as tf:
                with self.assertRaisesRegex(ValueError, 'escaping link'):
                    mod._safe_extract_tar(tf, out)

    def test_allows_normal_member(self):
        import tarfile, tempfile
        with tempfile.TemporaryDirectory() as d:
            member = tarfile.TarInfo('flutter/bin/flutter')
            archive = self._archive(d, member)
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with tarfile.open(archive, 'r:*') as tf:
                mod._safe_extract_tar(tf, out)
            self.assertEqual((out / 'flutter/bin/flutter').read_bytes(), b'x')

class SafeZipExtractionTests(unittest.TestCase):
    def test_rejects_parent_traversal_member(self):
        import tempfile, zipfile
        with tempfile.TemporaryDirectory() as d:
            archive = pathlib.Path(d) / 'x.zip'
            with zipfile.ZipFile(archive, 'w') as zf:
                zf.writestr('../escape', b'x')
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with zipfile.ZipFile(archive) as zf:
                with self.assertRaisesRegex(ValueError, 'path traversal'):
                    mod._safe_extract_zip(zf, out)
            self.assertFalse((pathlib.Path(d) / 'escape').exists())

    def test_rejects_absolute_member(self):
        import tempfile, zipfile
        with tempfile.TemporaryDirectory() as d:
            archive = pathlib.Path(d) / 'x.zip'
            with zipfile.ZipFile(archive, 'w') as zf:
                zf.writestr('/escape', b'x')
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with zipfile.ZipFile(archive) as zf:
                with self.assertRaisesRegex(ValueError, 'absolute'):
                    mod._safe_extract_zip(zf, out)

    def test_rejects_unix_symlink_member(self):
        import tempfile, zipfile
        with tempfile.TemporaryDirectory() as d:
            archive = pathlib.Path(d) / 'x.zip'
            info = zipfile.ZipInfo('flutter/link')
            info.create_system = 3
            info.external_attr = (0o120777 << 16)
            with zipfile.ZipFile(archive, 'w') as zf:
                zf.writestr(info, '../../escape')
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with zipfile.ZipFile(archive) as zf:
                with self.assertRaisesRegex(ValueError, 'symbolic link'):
                    mod._safe_extract_zip(zf, out)

    def test_allows_normal_member(self):
        import tempfile, zipfile
        with tempfile.TemporaryDirectory() as d:
            archive = pathlib.Path(d) / 'x.zip'
            with zipfile.ZipFile(archive, 'w') as zf:
                zf.writestr('flutter/bin/flutter', b'x')
            out = pathlib.Path(d) / 'out'; out.mkdir()
            with zipfile.ZipFile(archive) as zf:
                mod._safe_extract_zip(zf, out)
            self.assertEqual((out / 'flutter/bin/flutter').read_bytes(), b'x')


class InstallDestinationSafetyTests(unittest.TestCase):
    def test_rejects_final_component_symlink_before_destructive_replace(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            outside = root / 'outside-sdk'
            outside.mkdir()
            sentinel = outside / 'KEEP_ME'
            sentinel.write_text('do not delete')
            link = root / 'flutter-sdk'
            link.symlink_to(outside, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'must not be a symbolic link'):
                mod._resolve_install_destination(link)
            self.assertEqual(sentinel.read_text(), 'do not delete')

    def test_allows_symlinked_parent_but_not_symlinked_destination(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            real_parent = root / 'real-workspace'
            real_parent.mkdir()
            parent_link = root / 'workspace'
            parent_link.symlink_to(real_parent, target_is_directory=True)
            destination = parent_link / 'flutter-sdk'
            self.assertEqual(
                mod._resolve_install_destination(destination),
                (real_parent / 'flutter-sdk').resolve(),
            )


class TransactionalInstallReplacementTests(unittest.TestCase):
    def test_failed_final_move_restores_existing_sdk_and_removes_partial_install(self):
        import tempfile
        from unittest import mock
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            source = root / 'verified-new-sdk'
            (source / 'bin').mkdir(parents=True)
            (source / 'bin/flutter').write_text('new')
            destination = root / 'flutter-sdk'
            destination.mkdir()
            sentinel = destination / 'KEEP_ME'
            sentinel.write_text('old-sdk')

            def fail_after_partial_move(src, dst):
                partial = pathlib.Path(dst)
                partial.mkdir()
                (partial / 'PARTIAL').write_text('incomplete')
                raise OSError('simulated final move failure')

            with mock.patch.object(mod.shutil, 'move', side_effect=fail_after_partial_move):
                with self.assertRaisesRegex(OSError, 'simulated final move failure'):
                    mod._replace_install_transactionally(source, destination)

            self.assertEqual(sentinel.read_text(), 'old-sdk')
            self.assertFalse((destination / 'PARTIAL').exists())
            self.assertEqual(list(root.glob('.flutter-sdk.backup-*')), [])

    def test_successful_replace_removes_backup(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            source = root / 'verified-new-sdk'
            source.mkdir()
            (source / 'NEW').write_text('new-sdk')
            destination = root / 'flutter-sdk'
            destination.mkdir()
            (destination / 'OLD').write_text('old-sdk')
            mod._replace_install_transactionally(source, destination)
            self.assertEqual((destination / 'NEW').read_text(), 'new-sdk')
            self.assertFalse((destination / 'OLD').exists())
            self.assertEqual(list(root.glob('.flutter-sdk.backup-*')), [])

class TransactionalReplacementFilesystemTypeTests(unittest.TestCase):
    def test_successful_replace_cleans_backup_when_preexisting_destination_is_file(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            source = root / 'verified-new-sdk'
            source.mkdir()
            (source / 'NEW').write_text('new-sdk')
            destination = root / 'flutter-sdk'
            destination.write_text('unexpected-old-file')

            mod._replace_install_transactionally(source, destination)

            self.assertTrue(destination.is_dir())
            self.assertEqual((destination / 'NEW').read_text(), 'new-sdk')
            self.assertEqual(list(root.glob('.flutter-sdk.backup-*')), [])

    def test_remove_path_unlinks_symlink_without_deleting_target(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            outside = root / 'outside'
            outside.mkdir()
            sentinel = outside / 'KEEP_ME'
            sentinel.write_text('safe')
            link = root / 'link'
            link.symlink_to(outside, target_is_directory=True)

            mod._remove_path(link)

            self.assertFalse(link.exists())
            self.assertEqual(sentinel.read_text(), 'safe')
