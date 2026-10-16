"""HDF-1 (audit 2026-10-15b): the removed "Rüzgâr tahmini nasıl yapılır?"
link was hidden behind WIND_GUIDE_LINK instead of deleted. Owner rule
(2026-10-15): removed features are deleted from the code, not hidden behind
flags. The guide text stays in the Rüzgâr ⓘ.
"""
from __future__ import annotations

from pathlib import Path
import re
import unittest

from dart_library_source import ROOT, library_text

LIB = ROOT / 'lib'


def _lib_files():
    return sorted(LIB.rglob('*.dart'))


class Hdf1WindGuideLinkDeleted(unittest.TestCase):
    def test_flag_absent_from_lib(self):
        hits = [str(p.relative_to(ROOT)) for p in _lib_files()
                if 'WIND_GUIDE_LINK' in p.read_text(encoding='utf-8')]
        self.assertEqual(hits, [])

    def test_link_widget_and_key_absent_from_lib(self):
        for p in _lib_files():
            src = p.read_text(encoding='utf-8')
            for needle in ('WindGuideLink', "'wind-guide-link'",
                           '_showWindGuideLink'):
                self.assertNotIn(needle, src, f'{needle} in {p}')

    def test_no_build_passes_the_flag(self):
        for d in ('.github', 'tools'):
            for p in (ROOT / d).rglob('*'):
                if p.is_file() and p.suffix in ('.yml', '.yaml', '.sh'):
                    self.assertNotIn('WIND_GUIDE_LINK',
                                     p.read_text(encoding='utf-8'), str(p))

    def test_wind_info_still_opens_the_guide(self):
        src = library_text('lib/features/ballistics/ballistics_screen.dart')
        m = re.search(
            r"MenzilInfoButton\(\s*key: const Key\('environment-wind-info'\),"
            r"\s*title: 'Rüzgâr',\s*tooltip: WindGuide\.linkLabel,"
            r"\s*onPressed: \(\) => WindGuide\.show\(context, metric: metric\),",
            src)
        self.assertIsNotNone(m)

    def test_guide_text_kept(self):
        src = (LIB / 'features/ballistics/wind_guide.dart').read_text(
            encoding='utf-8')
        self.assertIn("linkLabel = 'Rüzgâr tahmini nasıl yapılır?'", src)
        self.assertIn("title = 'Rüzgârı gözle tahmin et'", src)
        self.assertIn('class WindGuideLines', src)
        self.assertIn('static Future<void> show(', src)


if __name__ == '__main__':
    unittest.main()
