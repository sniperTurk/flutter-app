import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = sorted((ROOT / '.github' / 'workflows').glob('*.yml'))


def block_scalar_indent_problems(text: str) -> list[str]:
    """Dependency-free check for the failure that broke v179's ios-ci.yml.

    Inside a ``run: |`` block every non-blank line must be indented at least as
    much as the first content line. A shell heredoc body written at column 0
    silently terminates the block scalar and makes the whole workflow invalid
    YAML, so GitHub would refuse to run any job.
    """
    problems: list[str] = []
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        m = re.match(r'^(\s*)(?:- )?[\w-]+:\s*[|>][+-]?\d*\s*$', lines[i])
        if not m:
            i += 1
            continue
        parent = len(m.group(1))
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        if j >= len(lines):
            break
        indent = len(lines[j]) - len(lines[j].lstrip())
        if indent <= parent:
            i += 1
            continue
        k = j
        while k < len(lines):
            line = lines[k]
            if line.strip():
                cur = len(line) - len(line.lstrip())
                if cur <= parent:
                    # The scalar ended here. What follows must be YAML structure
                    # (key, list item, comment, doc marker); shell/Python text
                    # at this depth means a heredoc body fell out of the block.
                    if not re.match(r'^\s*(#|- |---|["\']?[\w./-][^:]*:(\s|$))', line):
                        problems.append(f'line {k + 1}: non-YAML text left the block scalar: {line.strip()[:60]}')
                    break
                if cur < indent:
                    problems.append(f'line {k + 1}: indented {cur} < block indent {indent}: {line.strip()[:60]}')
            k += 1
        i = k
    return problems


class CiWorkflowYamlIntegrityTest(unittest.TestCase):
    def test_workflows_exist(self):
        self.assertTrue(WORKFLOWS)

    def test_block_scalars_keep_consistent_indentation(self):
        for wf in WORKFLOWS:
            with self.subTest(workflow=wf.name):
                self.assertEqual(block_scalar_indent_problems(wf.read_text(encoding='utf-8')), [])

    def test_checker_detects_the_v179_heredoc_regression(self):
        broken = (
            "steps:\n  - name: x\n    run: |\n      echo hi\n"
            "      python3 - <<'EOF'\nimport re\nEOF\n"
        )
        self.assertTrue(block_scalar_indent_problems(broken))
        fixed = broken.replace("import re", "      import re").replace("\nEOF\n", "\n      EOF\n")
        self.assertEqual(block_scalar_indent_problems(fixed), [])

    def test_workflows_parse_as_yaml_when_pyyaml_is_available(self):
        try:
            import yaml
        except ImportError:
            self.skipTest('PyYAML not installed; indentation checker above still runs')
        for wf in WORKFLOWS:
            with self.subTest(workflow=wf.name):
                self.assertIsInstance(yaml.safe_load(wf.read_text(encoding='utf-8')), dict)

    def test_minimum_os_step_script_runs_and_enforces_ios_15(self):
        import subprocess, sys
        text = (ROOT / '.github' / 'workflows' / 'ios-ci.yml').read_text(encoding='utf-8')
        m = re.search(r"<<'PYMINIOS'\n(.*?)\n\s*PYMINIOS", text, re.S)
        self.assertTrue(m)
        script = '\n'.join(l[10:] if l.startswith(' ' * 10) else l for l in m.group(1).split('\n'))
        for value, ok in (('15.0', True), ('15', True), ('17.2', True), ('14.0', False), ('13.0', False), ('bad', False)):
            with self.subTest(value=value):
                r = subprocess.run([sys.executable, '-c', script, value], capture_output=True, text=True)
                self.assertEqual(r.returncode == 0, ok, r.stderr)


if __name__ == '__main__':
    unittest.main()
