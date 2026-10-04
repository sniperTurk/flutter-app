from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CHECK = ROOT / "tools" / "check_ios_manual_customizations.py"
BOOTSTRAP = ROOT / "tools" / "bootstrap_ios_scaffold.sh"


class IosManualCustomizationGuardTests(unittest.TestCase):
    def _run(self, pbx: str, entitlements: bool = False, env=None):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            runner = root / "Runner"
            runner.mkdir()
            project = root / "project.pbxproj"
            project.write_text(pbx, encoding="utf-8")
            if entitlements:
                (runner / "Runner.entitlements").write_text("<plist/>", encoding="utf-8")
            return subprocess.run(
                ["python3", str(CHECK), str(project), str(runner)],
                text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
            )

    def test_plain_flutter_project_is_allowed(self):
        proc = self._run("CODE_SIGN_STYLE = Automatic;\nPRODUCT_BUNDLE_IDENTIFIER = com.sniperturk.sniperTurk;\n")
        self.assertEqual(0, proc.returncode, proc.stderr)

    def test_development_team_is_rejected(self):
        proc = self._run("DEVELOPMENT_TEAM = ABC123XYZ;\n")
        self.assertEqual(1, proc.returncode)
        self.assertIn("development team", proc.stderr)

    def test_team_written_by_our_own_configurator_is_allowed(self):
        import os
        env = {**os.environ, "SNIPER_TURK_IOS_DEVELOPMENT_TEAM": "ABCDE12345"}
        proc = self._run("DEVELOPMENT_TEAM = ABCDE12345;\nDEVELOPMENT_TEAM = ABCDE12345;\n", env=env)
        self.assertEqual(0, proc.returncode, proc.stderr)

    def test_different_team_is_still_rejected_when_env_team_is_set(self):
        import os
        env = {**os.environ, "SNIPER_TURK_IOS_DEVELOPMENT_TEAM": "ABCDE12345"}
        proc = self._run("DEVELOPMENT_TEAM = ZZZZZ99999;\n", env=env)
        self.assertEqual(1, proc.returncode)

    def test_capability_is_rejected(self):
        proc = self._run("SystemCapabilities = { com.apple.Push = { enabled = 1; }; };\n")
        self.assertEqual(1, proc.returncode)
        self.assertIn("target capabilities", proc.stderr)

    def test_entitlements_file_is_rejected(self):
        proc = self._run("CODE_SIGN_STYLE = Automatic;\n", entitlements=True)
        self.assertEqual(1, proc.returncode)
        self.assertIn("entitlements", proc.stderr)

    def test_bootstrap_checks_before_ios_is_moved(self):
        text = BOOTSTRAP.read_text(encoding="utf-8")
        guard = text.index("tools/check_ios_manual_customizations.py")
        move = text.index('mv -- ios "$IOS_BACKUP"')
        self.assertLess(guard, move)
        self.assertIn("exit 10", text[guard:move])


if __name__ == "__main__":
    unittest.main()
