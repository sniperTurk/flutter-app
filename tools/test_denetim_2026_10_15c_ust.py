"""Audit 2026-10-15c, app shell / navigation (#331, #328, #343): static
checks over lib/. Known findings are skipped with their ID; they turn into
regression guards once fixed."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15c_ust as d  # noqa: E402


class Clean(unittest.TestCase):
    def test_no_theme_switch_code_left(self):
        self.assertEqual([], d.theme_leftovers())

    def test_no_old_button_or_top_bar_labels(self):
        self.assertEqual([], d.old_labels())

    def test_guide_step_names_a_button(self):
        label, _ = d.guide_profile_button()
        self.assertTrue(label, "guide step 1 no longer names a button")

    def test_checks_find_what_they_look_for(self):
        # The scanners are not blind: a known present word is found.
        self.assertTrue(d._hits(("class MenzilTopBar",)))


class Findings(unittest.TestCase):
    @unittest.skip("UST-3: CatalogStartupErrorApp still uses MenzilTheme.light()")
    def test_ust3_no_light_theme_in_app(self):
        self.assertEqual([], d.light_theme_in_app())

    @unittest.skip("DGM-1: guide says 'Profil oluştur', welcome page has another label")
    def test_dgm1_guide_button_on_profil_page(self):
        label, ok = d.guide_profile_button()
        self.assertTrue(ok, label)

    @unittest.skip("DGM-2: unused oneLine + icon layout (iconLead) kept")
    def test_dgm2_no_icon_lead_layout(self):
        self.assertEqual([], d.icon_lead_layout())


if __name__ == "__main__":
    unittest.main()
