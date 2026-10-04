import unittest
from pathlib import Path

class ValidatorIsolationContractTest(unittest.TestCase):
    def test_bootstrap_uses_isolated_venv(self):
        s=Path('tools/bootstrap_reference_validator.py').read_text(encoding='utf-8')
        self.assertIn('venv.EnvBuilder(with_pip=True, clear=True)', s)
        self.assertIn('ROOT / ".validator_venv"', s)
        self.assertNotIn('[sys.executable, "-m", "pip", "install"', s)

    def test_versions_verified_inside_venv(self):
        s=Path('tools/bootstrap_reference_validator.py').read_text(encoding='utf-8')
        self.assertIn('[str(venv_python), "-c", verify_code]', s)
        self.assertIn('actual_versions.get(name)', s)

if __name__=='__main__': unittest.main()
