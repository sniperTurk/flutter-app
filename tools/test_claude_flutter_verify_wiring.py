import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class ClaudeFlutterVerifyWiringTest(unittest.TestCase):
    def test_entrypoint_is_fail_closed_and_runs_required_flutter_gates(self):
        text = (ROOT / 'tools' / 'claude_flutter_verify.sh').read_text()
        for required in [
            'python3 tools/offline_dart_lint.py',
            'flutter analyze --fatal-infos --fatal-warnings',
            'flutter test --coverage --reporter=expanded',
            "python3 -m unittest discover -s tools -p 'test_*.py' -v",
            'python3 tools/verify_production_gate.py',
            'flutter build ios --simulator --debug',
            'SNIPER_TURK_BOOTSTRAP_LOCKFILE',
            'Expected Flutter ${EXPECTED_FLUTTER}',
        ]:
            self.assertIn(required, text)

    def test_claude_instructions_point_to_entrypoint_and_forbid_false_ci_claims(self):
        text = (ROOT / 'CLAUDE.md').read_text()
        self.assertIn('tools/claude_flutter_verify.sh', text)
        self.assertIn('Never report CI, Simulator, device, signing, TestFlight, or App Store upload as passed', text)


    def test_offline_gates_run_before_flutter_is_required(self):
        text = (ROOT / 'tools' / 'claude_flutter_verify.sh').read_text()
        flutter_required = text.index('command -v flutter')
        for gate in [
            'python3 -m compileall -q tools',
            'python3 tools/offline_dart_lint.py',
            "python3 -m unittest discover -s tools -p 'test_*.py' -v",
            'python3 tools/verify_production_gate.py',
        ]:
            self.assertLess(text.index(gate), flutter_required)

    def test_ios_ci_runs_offline_release_gates_before_flutter_setup(self):
        text = (ROOT / '.github' / 'workflows' / 'ios-ci.yml').read_text()
        offline_compile = text.index('name: Validate complete Python tools tree')
        offline_lint = text.index('name: Run dependency-free Dart source hygiene')
        offline_tests = text.index('name: Run complete offline Python regression suite')
        production_gate = text.index('name: Enforce G1/G7 production gate (open only with CI reference comparison)')
        flutter_setup = text.index('name: Set up Flutter')
        self.assertLess(offline_compile, flutter_setup)
        self.assertLess(offline_lint, flutter_setup)
        self.assertLess(offline_tests, flutter_setup)
        self.assertLess(production_gate, flutter_setup)

if __name__ == '__main__':
    unittest.main()
