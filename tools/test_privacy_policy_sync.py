"""Gizlilik politikası: the in-app text equals the Turkish policy in the doc.

docs/app-store/03-gizlilik-politikasi.md (between the uygulama-metni
markers) is the single source; tools/data_gen/generate_privacy_policy.py
writes lib/features/guide/privacy_policy_content.dart from it. The check
compares the string values, so `dart format` may re-lay the literals.
"""
import importlib.util
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / 'lib/features/guide/privacy_policy_content.dart'
SCREEN = ROOT / 'lib/features/guide/privacy_policy_screen.dart'
HUB = ROOT / 'lib/features/tools/tools_screen.dart'
DOC = ROOT / 'docs/app-store/03-gizlilik-politikasi.md'


def _generator():
    spec = importlib.util.spec_from_file_location(
        'generate_privacy_policy', ROOT / 'tools/data_gen/generate_privacy_policy.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _dart_strings(source: str) -> list[str]:
    """Every string value in source order; adjacent literals are joined."""
    body = source.split('abstract final class PrivacyPolicyContent', 1)[1]
    out: list[str] = []
    pending: list[str] = []
    pos = 0
    literal = re.compile(r"'((?:[^'\\]|\\.)*)'")
    while True:
        m = literal.search(body, pos)
        if not m:
            break
        gap = body[pos:m.start()]
        if pending and gap.strip():
            out.append(''.join(pending))
            pending = []
        pending.append(m.group(1))
        pos = m.end()
    if pending:
        out.append(''.join(pending))
    return [s.replace("\\'", "'").replace('\\$', '$').replace('\\\\', '\\') for s in out]


class PrivacyPolicySyncTest(unittest.TestCase):
    def test_app_text_matches_doc(self):
        heading, updated, sections = _generator().parse(DOC.read_text(encoding='utf-8'))
        expected = [heading, updated]
        for title, paras in sections:
            expected += [title, *paras]
        self.assertEqual(expected, _dart_strings(DART.read_text(encoding='utf-8')))
        self.assertGreaterEqual(len(sections), 10)

    def test_policy_names_every_data_flow(self):
        text = '\n'.join(_dart_strings(DART.read_text(encoding='utf-8')))
        for needle in ('api.met.no', 'Google Maps SDK', 'nominatim.openstreetmap.org',
                       'server.arcgisonline.com', 'Basıncı telefondan al',
                       'Kamerayla ölç', 'Yedekle', 'Sekerbirol76@gmail.com'):
            self.assertIn(needle, text)

    def test_no_markup_or_placeholders_in_app_text(self):
        policy = DOC.read_text(encoding='utf-8').split('<!-- uygulama-metni:başla -->', 1)[1]
        policy = policy.split('<!-- uygulama-metni:bitti -->', 1)[0]
        for bad in ('**', '[[', '](', '`', 'TODO'):
            self.assertNotIn(bad, policy)

    def test_url_constant_and_entry_point(self):
        screen = SCREEN.read_text(encoding='utf-8')
        self.assertIn("String.fromEnvironment('PRIVACY_POLICY_URL')", screen)
        hub = HUB.read_text(encoding='utf-8')
        self.assertIn("Key('tool-privacy-policy')", hub)
        self.assertIn('PrivacyPolicyScreen', hub)
        # No new url-launch package (owner, 2026-10-14).
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        self.assertNotIn('url_launcher', pubspec)


if __name__ == '__main__':
    unittest.main()
