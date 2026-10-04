import os, pathlib, subprocess, tempfile, unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class FlutterBootstrapUpdateRollbackTest(unittest.TestCase):
    def test_failed_archive_fallback_preserves_existing_official_checkout(self):
        with tempfile.TemporaryDirectory() as td:
            base = pathlib.Path(td)
            fakebin = base/'bin'; fakebin.mkdir()
            sdk = base/'flutter'; (sdk/'.git').mkdir(parents=True)
            sentinel = sdk/'DO_NOT_DELETE.txt'; sentinel.write_text('keep', encoding='utf-8')
            (fakebin/'git').write_text('''#!/bin/sh
case "$*" in
  *"remote get-url origin"*) echo https://github.com/flutter/flutter.git; exit 0;;
  *"fetch --tags origin"*) exit 1;;
esac
exit 1
''')
            (fakebin/'curl').write_text('#!/bin/sh\nexit 0\n')
            (fakebin/'python3').write_text('''#!/bin/sh
if [ "${1:-}" = "-" ]; then echo 3.47.2; exit 0; fi
# Simulate the official archive installer failing after the git update failed.
exit 1
''')
            for p in fakebin.iterdir(): p.chmod(0o755)
            env = os.environ.copy()
            env['PATH'] = f"{fakebin}:/bin:/usr/bin"
            env['SNIPER_TURK_FLUTTER_HOME'] = str(sdk)
            proc = subprocess.run(['bash','tools/claude_bootstrap_and_verify.sh'], cwd=ROOT, env=env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            self.assertNotEqual(proc.returncode, 0)
            self.assertTrue(sentinel.exists(), proc.stdout + proc.stderr)

if __name__ == '__main__': unittest.main()
