"""Regression guard: macOS runner budget (2026-10-11).

GitHub-hosted macos-15 runners are limited to 5 concurrent jobs for this
account. On 2026-10-11 every iOS CI run took 3 of them (verify, ios-simulator,
wind-acceptance), the simulator smoke test ran twice per run, and TestFlight
waited behind dozens of queued PR runs for hours. These checks keep:

* only one automatic macOS job per iOS CI run (`verify`), gated by a Linux job
  that runs format/analyze/tests and detects docs/data-only changes;
* realistic timeouts on every macOS job and a bounded simulator retry loop;
* TestFlight in its own concurrency group, ahead of PR CI.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WF = ROOT / '.github' / 'workflows'

try:
    import yaml
except ImportError:  # pragma: no cover - CI installs PyYAML with setup-python
    yaml = None


def load(name):
    data = yaml.safe_load((WF / name).read_text(encoding='utf-8'))
    # PyYAML (YAML 1.1) parses the bare key `on` as boolean True.
    if True in data:
        data['on'] = data.pop(True)
    return data


def is_mac(job):
    return 'macos' in str(job.get('runs-on', ''))


@unittest.skipIf(yaml is None, 'PyYAML not installed')
class MacBudgetTest(unittest.TestCase):
    def test_every_macos_job_has_a_realistic_timeout(self):
        for wf in sorted(WF.glob('*.yml')):
            data = load(wf.name)
            for name, job in data.get('jobs', {}).items():
                if is_mac(job):
                    with self.subTest(workflow=wf.name, job=name):
                        self.assertIn('timeout-minutes', job)
                        self.assertLessEqual(int(job['timeout-minutes']), 45)

    def test_ios_ci_runs_one_automatic_macos_job_after_linux_checks(self):
        jobs = load('ios-ci.yml')['jobs']
        self.assertIn('verify', jobs)
        self.assertEqual(jobs['verify']['runs-on'], 'macos-15')
        self.assertEqual(jobs['dart-checks']['runs-on'], 'ubuntu-latest')
        self.assertIn('dart-checks', jobs['verify']['needs'])
        self.assertIn("needs.dart-checks.outputs.ios == 'true'", jobs['verify']['if'])
        self.assertFalse(is_mac(jobs['wind-acceptance']))
        # The extra simulator job is manual-only; verify already runs the smoke test.
        self.assertIn("github.event_name == 'workflow_dispatch'", jobs['ios-simulator']['if'])
        auto_mac = [n for n, j in jobs.items()
                    if is_mac(j) and "workflow_dispatch'" not in str(j.get('if', ''))]
        self.assertEqual(auto_mac, ['verify'])

    def test_dart_only_gates_run_on_linux_not_macos(self):
        jobs = load('ios-ci.yml')['jobs']
        linux = '\n'.join(str(s.get('run', '')) for s in jobs['dart-checks']['steps'])
        mac = '\n'.join(str(s.get('run', '')) for n, j in jobs.items() if is_mac(j) for s in j['steps'])
        for cmd in ('dart format --output=none --set-exit-if-changed lib test integration_test tools',
                    'flutter analyze --fatal-infos --fatal-warnings',
                    'flutter test --coverage --reporter=expanded',
                    "python3 -m unittest discover -s tools -p 'test_*.py' -v",
                    'python3 tools/verify_production_gate.py'):
            with self.subTest(cmd=cmd):
                self.assertIn(cmd, linux)
        for cmd in ('dart format', 'flutter analyze', 'flutter test --coverage'):
            with self.subTest(not_on_mac=cmd):
                self.assertNotIn(cmd, mac)

    def test_docs_and_data_only_changes_skip_macos(self):
        steps = load('ios-ci.yml')['jobs']['dart-checks']['steps']
        detect = next(s for s in steps if s.get('id') == 'changes')
        script = detect['run']
        for pattern in ('docs/', 'data/', r'\.md$'):
            with self.subTest(pattern=pattern):
                self.assertIn(pattern, script)
        # Fail safe: unknown base or a manual run always builds on macOS.
        self.assertIn('workflow_dispatch', script)
        self.assertIn('ios=true', script)

    def test_simulator_retry_loop_is_bounded(self):
        text = (WF / 'ios-ci.yml').read_text(encoding='utf-8')
        self.assertNotIn('for attempt in 1 2 3; do', text)
        self.assertIn('for attempt in 1 2; do', text)
        for name, job in load('ios-ci.yml')['jobs'].items():
            for step in job.get('steps', []):
                if 'integration_test/app_launch_test.dart' in str(step.get('run', '')):
                    with self.subTest(job=name):
                        self.assertLessEqual(int(step.get('timeout-minutes', 999)), 25)

    def test_ios_ci_cancels_superseded_runs(self):
        conc = load('ios-ci.yml')['concurrency']
        self.assertTrue(conc['cancel-in-progress'])
        self.assertIn('ios-ci-', conc['group'])

    def test_testflight_has_own_group_and_goes_first(self):
        data = load('ios-testflight.yml')
        conc = data['concurrency']
        self.assertTrue(conc['group'].startswith('ios-testflight'))
        self.assertFalse(conc['cancel-in-progress'])
        free = data['jobs']['free-mac-runners']
        self.assertEqual(free['runs-on'], 'ubuntu-latest')
        self.assertEqual(free['permissions'], {'actions': 'write'})
        script = '\n'.join(s.get('run', '') for s in free['steps'])
        for wf in ('ios-ci.yml', 'sim-screens.yml', 'appetize-upload.yml'):
            self.assertIn(wf, script)
        # Only PR-triggered iOS CI is cancelled; main pushes keep their evidence.
        self.assertIn('event=pull_request', script)
        # The upload job never depends on the cancel helper.
        self.assertNotIn('needs', data['jobs']['testflight'])

    def test_sim_screens_is_manual_only(self):
        self.assertEqual(set(load('sim-screens.yml')['on']), {'workflow_dispatch'})

    def test_appetize_skips_docs_and_data_pushes(self):
        ignore = load('appetize-upload.yml')['on']['push']['paths-ignore']
        self.assertIn('docs/**', ignore)
        self.assertIn('data/**', ignore)


if __name__ == '__main__':
    unittest.main()
