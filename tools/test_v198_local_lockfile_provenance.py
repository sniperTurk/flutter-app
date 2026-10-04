import sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from write_lockfile_provenance import write
from verify_lockfile_provenance import verify

class LocalLockfileProvenanceTests(unittest.TestCase):
    def test_writer_creates_verifiable_provenance(self):
        with tempfile.TemporaryDirectory() as d:
            r=Path(d); p=r/'pubspec.yaml'; l=r/'pubspec.lock'; o=r/'lockfile-provenance.txt'
            p.write_text('name: sniper_turk\n'); l.write_text('packages: {}\n')
            self.assertEqual([], write(p,l,o,'3.47.2'))
            self.assertEqual([], verify(p,l,o))
    def test_writer_rejects_wrong_flutter(self):
        with tempfile.TemporaryDirectory() as d:
            r=Path(d); p=r/'pubspec.yaml'; l=r/'pubspec.lock'; o=r/'lockfile-provenance.txt'
            p.write_text('x'); l.write_text('y')
            self.assertTrue(write(p,l,o,'3.47.1'))
            self.assertFalse(o.exists())
    def test_writer_rejects_symlinked_inputs_and_output(self):
        with tempfile.TemporaryDirectory() as d:
            r=Path(d); p=r/'pubspec.yaml'; l=r/'pubspec.lock'; o=r/'lockfile-provenance.txt'
            p.write_text('x'); l.write_text('y')
            real_p=r/'real-pubspec'; p.replace(real_p); p.symlink_to(real_p)
            self.assertTrue(any('symbolic link' in e for e in write(p,l,o,'3.47.2')))
            p.unlink(); p.write_text('x')
            real_o=r/'real-output'; real_o.write_text('sentinel'); o.symlink_to(real_o)
            self.assertTrue(any('output must not be a symbolic link' in e for e in write(p,l,o,'3.47.2')))
            self.assertEqual('sentinel', real_o.read_text())

    def test_writer_replaces_existing_regular_output(self):
        with tempfile.TemporaryDirectory() as d:
            r=Path(d); p=r/'pubspec.yaml'; l=r/'pubspec.lock'; o=r/'lockfile-provenance.txt'
            p.write_text('x'); l.write_text('y'); o.write_text('stale')
            self.assertEqual([], write(p,l,o,'3.47.2'))
            self.assertEqual([], verify(p,l,o))

    def test_local_bootstrap_verifies_provenance_before_format(self):
        s=Path('tools/claude_flutter_verify.sh').read_text()
        self.assertIn('write_lockfile_provenance.py', s)
        self.assertLess(s.index('verify_lockfile_provenance.py'), s.index('step "Formatting"'))
    def test_existing_lockfile_path_reverifies_provenance_after_resolution(self):
        s=Path('tools/claude_flutter_verify.sh').read_text()
        calls=[i for i in range(len(s)) if s.startswith('python3 tools/verify_lockfile_provenance.py', i)]
        self.assertEqual(2, len(calls), 'bootstrap and existing-lockfile paths must both verify provenance')
        else_pos=s.index('else\n  BEFORE=')
        format_pos=s.index('step "Formatting"')
        self.assertGreater(calls[1], else_pos)
        self.assertLess(calls[1], format_pos)
        existing_branch=s[else_pos:format_pos]
        self.assertLess(existing_branch.index('flutter pub get'), existing_branch.index('python3 tools/verify_lockfile_provenance.py'))
if __name__ == '__main__': unittest.main()
