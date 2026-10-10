"""Offline contracts for the personal catalog -> profile wiring. Behaviour
itself is covered by Flutter tests in test/user_catalog_test.dart. (The manual
catalog dialog and catalog screen were removed as unreachable code.)"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
USER = (ROOT / 'lib/data/user_catalog.dart').read_text(encoding='utf-8')
LOADER = (ROOT / 'lib/services/user_catalog_loader.dart').read_text(encoding='utf-8')
REPO = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')
INTEGRITY = (ROOT / 'lib/data/profile_catalog_integrity.dart').read_text(encoding='utf-8')
PROFILES = (ROOT / 'lib/features/profiles/profiles_screen.dart').read_text(encoding='utf-8')


class PersonalCatalogProfileContract(unittest.TestCase):
    def test_profiles_resolve_against_built_in_and_personal_records(self):
        for name in ('allRifles', 'allAmmunition', 'allScopes'):
            self.assertIn(f'CatalogRepository.{name}', INTEGRITY)
            self.assertIn(f'CatalogRepository.{name}', PROFILES)

    def test_personal_records_are_never_manufacturer_verified(self):
        self.assertIn("const userCatalogSourceName = 'Kullanıcı girdisi';", USER)
        self.assertEqual(USER.count('userEntered: true'), 3)
        # V378: the profile editor has no catalog dropdowns any more, and the
        # Profil name card with "kişisel kayıt" labels was removed by the
        # owner (2026-10-09). Personal records stay marked in the data
        # (userEntered, source 'Kullanıcı girdisi') and on Katalog.
        self.assertNotIn('kişisel kayıt, üretici doğrulaması yok', PROFILES)

    def test_incomplete_records_are_blocked_with_reason(self):
        self.assertIn('ağırlık (grain)', USER)
        self.assertIn('klik birimi (MRAD/MOA)', USER)
        # V378: blocked personal records are reported on the Katalog screen;
        # the editor no longer lists catalog records to choose from.

    def test_legacy_migration_copies_and_never_deletes(self):
        self.assertIn('migratedIdsKey', LOADER)
        self.assertNotIn('legacy.remove(', LOADER)
        self.assertNotIn('.remove(UserCatalogStore.key', LOADER)


if __name__ == '__main__':
    unittest.main()
