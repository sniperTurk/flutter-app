"""V368: source-text guards for the fail-closed profile editor. NOT a substitute for flutter test."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class V368ProfileIntegrity(unittest.TestCase):
    def test_editor_never_autofills_catalog_ids_when_editing(self):
        t = read('lib/features/profiles/profiles_screen.dart')
        # V375: no rifle is ever preselected; the user types the rifle in.
        self.assertNotIn('rifle ??=', t)
        # V376: the scope is typed in too; nothing is preselected.
        self.assertNotIn('scope ??=', t)
        # V378: ammunition is typed in; nothing is preselected.
        self.assertNotIn('ammo ??=', t)
        self.assertNotIn('ammos.first', t)
        self.assertNotIn('\n    rifle ??= rifles.first;', t)
        self.assertNotIn('\n    scope ??= CatalogRepository.scopes.first;', t)

    def test_save_requires_explicit_rifle_ammo_scope(self):
        t = read('lib/features/profiles/profiles_screen.dart')
        # V375: the typed rifle must be complete and valid (incl. twist).
        self.assertIn('!_saving && _rifleValid && _ammoValid && _scopeValid && _validSight', t)

    def test_no_fabricated_pressure_for_existing_profile(self):
        t = read('lib/features/profiles/profiles_screen.dart')
        self.assertIn("p == null ? '200' : (p.pressureBar?.toString() ?? '')", t)

    def test_home_resolves_active_instance_from_saved(self):
        t = read('lib/features/home/home_screen.dart')
        self.assertIn('saved.where((x) => x.id == profile.id).firstOrNull', t)

    def test_camera_preset_is_unproven_veryhigh_not_used(self):
        self.assertNotIn('veryHigh', read('lib/tools/adapters/camera_plugin_service.dart'))


if __name__ == '__main__':
    unittest.main()


class V368Quarantine(unittest.TestCase):
    def test_corrupt_primary_is_quarantined_before_repair_and_before_overwrite(self):
        t = read('lib/services/profile_store.dart')
        self.assertIn("_quarantineKey = 'sniper_turk.rifle_profiles.v1.corrupt'", t)
        self.assertLess(t.index('await _quarantine(prefs, primaryRaw);'), t.index('final repaired'))
        self.assertIn('await _quarantine(prefs, previous);', t)
        # first evidence wins
        self.assertIn('prefs.getString(_quarantineKey) != null) return;', t)

    def test_widget_and_store_tests_exist(self):
        self.assertTrue((ROOT / 'test/profile_editor_fail_closed_test.dart').is_file())
        self.assertIn('quarantines the corrupt primary', read('test/profile_store_test.dart'))
