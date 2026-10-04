from pathlib import Path
import os, subprocess, tempfile, unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tools/export_signed_app_store_ipa.sh'

class SignedExportArchivePathSafetyTest(unittest.TestCase):
    def test_rejects_archive_symlink_before_verifier(self):
        with tempfile.TemporaryDirectory() as td:
            outside = Path(td) / 'outside.xcarchive'
            (outside / 'Products/Applications/Runner.app').mkdir(parents=True)
            link = ROOT / 'build/ios/archive/v323-unsafe.xcarchive'
            link.parent.mkdir(parents=True, exist_ok=True)
            try:
                if link.exists() or link.is_symlink(): link.unlink()
                link.symlink_to(outside, target_is_directory=True)
                env = os.environ.copy()
                env['SNIPER_TURK_IOS_DEVELOPMENT_TEAM'] = 'ABCDEFGHIJ'
                # Stub platform/tool checks so the archive safety gate is what decides.
                bindir = Path(td) / 'bin'; bindir.mkdir()
                for name, body in {
                    'uname': '#!/bin/sh\necho Darwin\n',
                    'xcodebuild': '#!/bin/sh\nexit 99\n',
                    'codesign': '#!/bin/sh\nexit 99\n',
                }.items():
                    p=bindir/name; p.write_text(body); p.chmod(0o755)
                env['PATH'] = str(bindir) + os.pathsep + env['PATH']
                cp = subprocess.run(['bash', str(SCRIPT), str(link), 'build/ios/v323-export'], cwd=ROOT, env=env, text=True, capture_output=True)
                self.assertNotEqual(cp.returncode, 0)
                self.assertIn('Unsafe archive path', cp.stderr + cp.stdout)
            finally:
                if link.is_symlink(): link.unlink()
                # Keep the source tree clean when this test created the archive
                # parent solely for its temporary symlink. Never remove non-empty
                # directories or user/build artifacts.
                try:
                    link.parent.rmdir()
                    link.parent.parent.rmdir()
                    link.parent.parent.parent.rmdir()
                except OSError:
                    pass

    def test_export_dir_may_not_overlap_the_archive(self):
        with tempfile.TemporaryDirectory() as td:
            archive = ROOT / 'build/ios/archive/v324-overlap.xcarchive'
            (archive / 'Products/Applications/Runner.app').mkdir(parents=True, exist_ok=True)
            try:
                env = os.environ.copy()
                env['SNIPER_TURK_IOS_DEVELOPMENT_TEAM'] = 'ABCDEFGHIJ'
                bindir = Path(td) / 'bin'; bindir.mkdir()
                for name, body in {
                    'uname': '#!/bin/sh\necho Darwin\n',
                    'xcodebuild': '#!/bin/sh\nexit 99\n',
                    'codesign': '#!/bin/sh\nexit 99\n',
                    'python3': '#!/bin/sh\nexec ' + __import__('sys').executable + ' "$@"\n',
                }.items():
                    p = bindir / name; p.write_text(body); p.chmod(0o755)
                env['PATH'] = str(bindir) + os.pathsep + env['PATH']
                cp = subprocess.run(['bash', str(SCRIPT), str(archive), 'build/ios/archive'], cwd=ROOT, env=env, text=True, capture_output=True)
                self.assertNotEqual(cp.returncode, 0)
                self.assertTrue(archive.is_dir(), 'archive must not be deleted')
            finally:
                import shutil
                shutil.rmtree(archive, ignore_errors=True)
                # The test may have created build/ios/archive and its empty
                # parents. Remove only empty directories; preserve anything else.
                for parent in (archive.parent, archive.parent.parent, archive.parent.parent.parent):
                    try:
                        parent.rmdir()
                    except OSError:
                        break

if __name__ == '__main__': unittest.main()
