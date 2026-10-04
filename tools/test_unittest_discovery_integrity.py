from pathlib import Path
import importlib.util
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / 'tools'
SELF = Path(__file__).name


class UnittestDiscoveryIntegrityTest(unittest.TestCase):
    def test_every_test_module_exposes_at_least_one_unittest(self):
        empty = []
        loader = unittest.TestLoader()
        for path in sorted(TOOLS.glob('test_*.py')):
            if path.name == SELF:
                continue
            spec = importlib.util.spec_from_file_location(f'_discovery_check_{path.stem}', path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            suite = loader.loadTestsFromModule(module)
            if suite.countTestCases() == 0:
                empty.append(path.name)
        self.assertEqual(empty, [], 'test modules invisible to unittest discovery: ' + ', '.join(empty))


if __name__ == '__main__':
    unittest.main()
