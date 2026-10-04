from pathlib import Path
import unittest


class IosCiPythonCompileWiringTest(unittest.TestCase):
    def test_ci_compiles_complete_tools_tree(self):
        workflow = Path('.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
        self.assertIn('python3 -m compileall -q tools', workflow)
        self.assertNotIn('python3 -m py_compile tools/', workflow)


if __name__ == '__main__':
    unittest.main()
