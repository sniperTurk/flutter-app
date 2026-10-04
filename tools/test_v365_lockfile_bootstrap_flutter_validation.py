from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / '.github' / 'workflows' / 'bootstrap-lockfile.yml'


class V365LockfileBootstrapFlutterValidationTest(unittest.TestCase):
    def test_generated_lockfile_is_not_uploaded_before_flutter_validation(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        format_cmd = 'dart format --output=none --set-exit-if-changed lib test integration_test tools'
        analyze_cmd = 'flutter analyze --fatal-infos --fatal-warnings'
        test_cmd = 'flutter test --reporter=expanded'
        upload = 'uses: actions/upload-artifact@v7'
        for marker in (format_cmd, analyze_cmd, test_cmd, upload):
            self.assertIn(marker, text)
        self.assertLess(text.index(format_cmd), text.index(upload))
        self.assertLess(text.index(analyze_cmd), text.index(upload))
        self.assertLess(text.index(test_cmd), text.index(upload))

    def test_validation_uses_same_pinned_flutter_job(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        self.assertIn("flutter-version: '3.47.2'", text)
        self.assertEqual(text.count('jobs:'), 1)
        self.assertIn('Generate resolver lockfile', text)
        self.assertIn('Run Flutter tests with generated lockfile', text)

    def test_timeout_covers_analyze_and_full_test_run(self):
        # V366: 15 minutes was too tight for pub get + format + analyze + the
        # whole flutter test suite on a cold macOS runner; ios-ci.yml allows 30.
        text = WORKFLOW.read_text(encoding='utf-8')
        self.assertIn('timeout-minutes: 30', text)
        self.assertNotIn('timeout-minutes: 15', text)


if __name__ == '__main__':
    unittest.main()
