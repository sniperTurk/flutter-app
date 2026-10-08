#!/usr/bin/env python3
"""Lock iOS smoke coverage to platform-backed profile + active-id persistence."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "integration_test" / "app_launch_test.dart"

class IosProfilePersistencePlatformContractTest(unittest.TestCase):
    def test_smoke_reads_platform_backed_shared_preferences_after_save(self):
        text = SMOKE.read_text(encoding="utf-8")
        required = (
            "package:shared_preferences/shared_preferences.dart",
            "SharedPreferences.getInstance()",
            "sniper_turk.rifle_profiles.v1",
            "sniper_turk.active_profile_id.v1",
            "expect(persistedProfiles, contains('Yeni Profil'))",
            "expect(persistedActiveId, isNotEmpty)",
        )
        for marker in required:
            with self.subTest(marker=marker):
                self.assertIn(marker, text)

    def test_persistence_assertions_follow_profile_save_and_home_reload(self):
        text = SMOKE.read_text(encoding="utf-8")
        save = text.index("tester.tap(find.text('Kaydet'))")
        # The shell reloads profiles after the save; the new profile is then
        # visible in the list and the top-bar selector.
        home = text.index("expect(find.text('Yeni Profil'), findsWidgets);", save)
        prefs = text.index("SharedPreferences.getInstance()", home)
        dope = text.index("tester.tap(find.text('Hedef').first)", prefs)
        self.assertLess(save, home)
        self.assertLess(home, prefs)
        self.assertLess(prefs, dope)

if __name__ == "__main__":
    unittest.main()
