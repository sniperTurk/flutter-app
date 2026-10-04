import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tools/configure_ios_signing.py'
BOOTSTRAP = ROOT / 'tools/bootstrap_ios_scaffold.sh'

SAMPLE = '''buildSettings = {\n\tCODE_SIGN_STYLE = Automatic;\n};\nbuildSettings = {\n\tCODE_SIGN_STYLE = Automatic;\n};\n'''

class IosSigningConfigurationTest(unittest.TestCase):
    def run_config(self, text=SAMPLE, team='ABC123XYZ9'):
        with tempfile.TemporaryDirectory() as td:
            path = pathlib.Path(td) / 'project.pbxproj'
            path.write_text(text, encoding='utf-8')
            proc = subprocess.run(['python3', str(SCRIPT), str(path), '--team', team], text=True, capture_output=True)
            return proc, path.read_text(encoding='utf-8')

    def test_configures_every_automatic_signing_build_setting(self):
        proc, text = self.run_config()
        self.assertEqual(0, proc.returncode, proc.stderr)
        self.assertEqual(2, text.count('DEVELOPMENT_TEAM = ABC123XYZ9;'))

    def test_is_idempotent(self):
        first, text = self.run_config()
        self.assertEqual(0, first.returncode)
        second, text2 = self.run_config(text)
        self.assertEqual(0, second.returncode)
        self.assertEqual(text, text2)

    def test_rejects_invalid_team_without_modifying_project(self):
        proc, text = self.run_config(team='TEAM')
        self.assertNotEqual(0, proc.returncode)
        self.assertEqual(SAMPLE, text)

    def test_bootstrap_uses_explicit_environment_team_after_generation(self):
        text = BOOTSTRAP.read_text(encoding='utf-8')
        generation = text.index('flutter create --platforms=ios')
        signing = text.index('python3 tools/configure_ios_signing.py')
        self.assertGreater(signing, generation)
        self.assertIn('SNIPER_TURK_IOS_DEVELOPMENT_TEAM', text)

if __name__ == '__main__':
    unittest.main()
