"""Denetim 2026-10-15b — PRE-1 (düşük, #262'den kalma, kapsam dışı).

Grup merkezi "Sıfır ofsetine aktar" değeri her zaman cm yazar; Pro/Hedef
emperyal modda aynı metni inç olarak okur. SettingsStore.loadMetric() bu
derlemede hep true döndüğü için şu an ulaşılamaz.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent


def _read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class Pre1ZeroOffsetUnit(unittest.TestCase):
    def test_imperial_unreachable_in_this_build(self):
        src = _read('lib/services/settings_store.dart')
        self.assertRegex(src, r'bool\s+loadMetric\(\)\s*=>\s*true;')

    def test_zero_group_writes_cm(self):
        src = _read('lib/features/tools/zero_group_screen.dart')
        self.assertIn("unit: 'cm'", src)
        self.assertIn('centerUpCm', src)

    @unittest.skip('PRE-1 (düşük): grup merkezi cm yazar, emperyal Pro inç okur')
    def test_zero_offset_unit_follows_reader(self):
        pro = _read('lib/features/ballistics/pro_ayarlar_view.dart')
        zg = _read('lib/features/tools/zero_group_screen.dart')
        reads_inch = re.search(r"metric \? 'cm' : 'in'", pro) is not None
        writes_only_cm = re.search(r'\bmetric\b', zg) is None
        self.assertFalse(reads_inch and writes_only_cm)


if __name__ == '__main__':
    unittest.main()
