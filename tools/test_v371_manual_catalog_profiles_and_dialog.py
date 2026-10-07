"""Offline contracts for the personal catalog -> profile wiring and the manual
catalog dialog lifecycle. Behaviour itself is covered by Flutter tests in
test/user_catalog_test.dart and test/manual_catalog_dialog_test.dart."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIALOG = (ROOT / 'lib/features/catalog/manual_catalog_dialog.dart').read_text(encoding='utf-8')
SCREEN = (ROOT / 'lib/features/catalog/catalog_screen.dart').read_text(encoding='utf-8')
USER = (ROOT / 'lib/data/user_catalog.dart').read_text(encoding='utf-8')
LOADER = (ROOT / 'lib/services/user_catalog_loader.dart').read_text(encoding='utf-8')
REPO = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')
INTEGRITY = (ROOT / 'lib/data/profile_catalog_integrity.dart').read_text(encoding='utf-8')
PROFILES = (ROOT / 'lib/features/profiles/profiles_screen.dart').read_text(encoding='utf-8')


class ManualDialogLifecycleContract(unittest.TestCase):
    def test_controllers_are_owned_by_the_dialog_state(self):
        self.assertIn('class _ManualCatalogDialogState extends State<ManualCatalogDialog>', DIALOG)
        self.assertIn('void dispose() {', DIALOG)
        self.assertIn('c.dispose();', DIALOG)
        # The old pattern disposed controllers right after showDialog returned,
        # while the route was still animating out.
        start = SCREEN.index('Future<void> _editManual(')
        body = SCREEN[start:SCREEN.index('String? _profileBlockReason', start)]
        self.assertNotIn('TextEditingController(', body)
        self.assertNotIn('.dispose()', body)

    def test_save_is_reentrancy_guarded_and_id_is_stable(self):
        self.assertIn('if (saving) return;', DIALOG)
        self.assertIn('onPressed: saving ? null : _save', DIALOG)
        self.assertIn('late final String recordId', DIALOG)

    def test_failed_save_keeps_dialog_open(self):
        self.assertIn("saveError = 'Kayıt başarısız: $error';", DIALOG)
        self.assertIn('canPop: !saving', DIALOG)


class PersonalCatalogProfileContract(unittest.TestCase):
    def test_profiles_resolve_against_built_in_and_personal_records(self):
        for name in ('allRifles', 'allAmmunition', 'allScopes'):
            self.assertIn(f'CatalogRepository.{name}', INTEGRITY)
            self.assertIn(f'CatalogRepository.{name}', PROFILES)

    def test_catalog_browser_does_not_duplicate_personal_records(self):
        self.assertIn('.riflesFor(platform, includeUser: false)', SCREEN)
        self.assertIn('.ammunitionFor(platform, includeUser: false)', SCREEN)

    def test_personal_records_are_never_manufacturer_verified(self):
        self.assertIn("const userCatalogSourceName = 'Kullanıcı girdisi';", USER)
        self.assertEqual(USER.count('userEntered: true'), 3)
        # V378: the profile editor has no catalog dropdowns any more (rifle,
        # ammo and scope are typed in), so the "(kişisel kayıt)" option label
        # is gone; the summary still labels every personal record.
        self.assertIn('kişisel kayıt, üretici doğrulaması yok', PROFILES)

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
