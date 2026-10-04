import subprocess, sys, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import validate_metno_contact as v


class MetNoContact(unittest.TestCase):
    def test_rejects_empty_and_placeholders(self):
        for bad in ('', ' ', 'CONTACT_REQUIRED', 'ornek@alanadi.com', 'a@example.com', 'x y@foo.com',
                    'foo', 'http://foo.com', 'https://localhost/x', 'ü@foo.com', 'a' * 130 + '@foo.com'):
            self.assertTrue(v.validate(bad), bad)

    def test_accepts_wellformed_email_and_https(self):
        self.assertEqual(v.validate('destek@firma.com.tr'), [])
        self.assertEqual(v.validate('https://firma.com.tr/iletisim'), [])

    def test_cli_exit_codes_and_value_not_echoed(self):
        ok = subprocess.run([sys.executable, str(ROOT / 'tools/validate_metno_contact.py'), 'destek@firma.com.tr'],
                            capture_output=True, text=True)
        self.assertEqual(ok.returncode, 0)
        self.assertNotIn('destek@firma.com.tr', ok.stdout + ok.stderr)
        bad = subprocess.run([sys.executable, str(ROOT / 'tools/validate_metno_contact.py'), ''],
                             capture_output=True, text=True)
        self.assertEqual(bad.returncode, 1)

    def test_release_builds_pass_dart_define_and_validate_first(self):
        wf = (ROOT / '.github/workflows/ios-ci.yml').read_text(encoding='utf-8')
        self.assertEqual(wf.count('--dart-define=METNO_CONTACT="$METNO_CONTACT"'), 2)
        self.assertLess(wf.index('validate_metno_contact.py'), wf.index('flutter build ios --release'))
        self.assertIn('vars.METNO_CONTACT', wf)

    def test_no_real_contact_is_hardcoded(self):
        cfg = (ROOT / 'lib/tools/config/tools_config.dart').read_text(encoding='utf-8')
        self.assertIn("String.fromEnvironment('METNO_CONTACT')", cfg)
        self.assertIn('CONTACT_REQUIRED', cfg)


if __name__ == '__main__':
    unittest.main()
