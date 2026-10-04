import os, pathlib, subprocess, tempfile, unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class FlutterBootstrapPathSafetyTest(unittest.TestCase):
    def test_existing_non_flutter_custom_sdk_directory_is_never_deleted(self):
        with tempfile.TemporaryDirectory() as td:
            base = pathlib.Path(td)
            fakebin = base/'bin'; fakebin.mkdir()
            sdk = base/'important-existing-directory'; sdk.mkdir()
            sentinel = sdk/'DO_NOT_DELETE.txt'; sentinel.write_text('keep', encoding='utf-8')
            (fakebin/'git').write_text('#!/bin/sh\nexit 1\n')
            (fakebin/'curl').write_text('#!/bin/sh\nexit 0\n')
            (fakebin/'python3').write_text('''#!/bin/sh\nif [ "${1:-}" = "-" ]; then echo 3.47.2; exit 0; fi\nexit 1\n''')
            for p in fakebin.iterdir(): p.chmod(0o755)
            env = os.environ.copy()
            env['PATH'] = f"{fakebin}:/bin:/usr/bin"
            env['SNIPER_TURK_FLUTTER_HOME'] = str(sdk)
            proc = subprocess.run(['bash','tools/claude_bootstrap_and_verify.sh'], cwd=ROOT, env=env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            self.assertNotEqual(proc.returncode, 0)
            self.assertTrue(sentinel.exists(), proc.stdout + proc.stderr)

if __name__ == '__main__': unittest.main()
