"""Kullanım rehberi: the app text and docs/kullanim-rehberi/REHBER.md agree.

The guide exists twice (owner draft, 2026-10-11): as a Markdown draft for
review and as the Araçlar > Kullanım rehberi page. Every section title and
every paragraph of the app text must also be in the Markdown, in order.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / 'lib/features/guide/usage_guide_content.dart'
MD = ROOT / 'docs/kullanim-rehberi/REHBER.md'


def _dart_strings(source: str) -> list[str]:
    """Joins adjacent single-quoted literals into one string each."""
    out: list[str] = []
    current: list[str] | None = None
    for line in source.splitlines():
        stripped = line.strip()
        m = re.match(r"^'((?:[^'\\]|\\.)*)'([,;]?)$", stripped)
        if m:
            current = (current or []) + [m.group(1)]
            if m.group(2):
                out.append(''.join(current))
                current = None
            continue
        current = None
        t = re.match(r"^UsageGuideSection\('((?:[^'\\]|\\.)*)', \[$", stripped)
        if t:
            out.append('## ' + t.group(1))
    return [s.replace("\\'", "'").replace('\\$', '$') for s in out]


class UsageGuideSyncTest(unittest.TestCase):
    def test_app_text_matches_markdown(self):
        strings = _dart_strings(DART.read_text(encoding='utf-8'))
        self.assertGreater(len(strings), 20)
        md = [b.strip() for b in MD.read_text(encoding='utf-8').split('\n\n')]
        md = [b for b in md if b and not b.startswith('# ') and not b.startswith('<!--')]
        self.assertEqual(md, strings)

    def test_no_bold_markup(self):
        self.assertNotIn('**', MD.read_text(encoding='utf-8'))
        self.assertNotIn('FontWeight.w7', (ROOT / 'lib/features/guide/usage_guide_screen.dart').read_text(encoding='utf-8'))


if __name__ == '__main__':
    unittest.main()
