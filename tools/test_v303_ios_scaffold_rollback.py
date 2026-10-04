from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools" / "bootstrap_ios_scaffold.sh"


class IosScaffoldRollbackTests(unittest.TestCase):
    def test_bootstrap_has_transactional_backup_and_exit_trap(self):
        text = SCRIPT.read_text(encoding="utf-8")
        required = [
            'IOS_BACKUP=""',
            'mv -- ios "$IOS_BACKUP"',
            'rollback_ios() {',
            'trap rollback_ios EXIT',
            'rm -rf -- ios',
            'mv -- "$IOS_BACKUP" ios',
        ]
        for needle in required:
            with self.subTest(needle=needle):
                self.assertIn(needle, text)

    def test_failed_flutter_create_restores_existing_ios_tree(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "tools").mkdir()
            shutil.copy2(SCRIPT, root / "tools" / SCRIPT.name)
            # The bootstrap calls this before touching ios/. Keep it successful.
            (root / "tools" / "verify_flutter_toolchain.py").write_text("raise SystemExit(0)\n")
            old = root / "ios" / "sentinel.txt"
            old.parent.mkdir()
            old.write_text("original-ios-tree", encoding="utf-8")
            bindir = root / "bin"
            bindir.mkdir()
            flutter = bindir / "flutter"
            flutter.write_text(textwrap.dedent("""\
                #!/bin/sh
                if [ "$1" = "create" ]; then
                  mkdir -p ios/Runner
                  printf partial > ios/Runner/partial.txt
                  exit 42
                fi
                exit 0
            """), encoding="utf-8")
            flutter.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{bindir}:{env['PATH']}"
            proc = subprocess.run(
                ["bash", str(root / "tools" / SCRIPT.name)],
                cwd=root,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            self.assertEqual(42, proc.returncode, proc.stderr)
            self.assertEqual("original-ios-tree", old.read_text(encoding="utf-8"))
            self.assertFalse((root / "ios" / "Runner" / "partial.txt").exists())


if __name__ == "__main__":
    unittest.main()
