import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class IosIntegrationSmokeContractTest(unittest.TestCase):
    def test_clean_install_smoke_covers_core_safe_routes_and_dope_gate(self):
        source = (ROOT / 'integration_test' / 'app_launch_test.dart').read_text(encoding='utf-8')
        # Menzil shell: Hesaplayıcılar opens from the Araçlar tab (Katalog is
        # no longer listed there, 2026-10-08), profile management is the
        # Profil tab. V380: Ayarlar was removed (metric only).
        self.assertIn("expect(find.text('Ayarlar'), findsNothing)", source)
        for label in ('Araçlar', 'Hesaplayıcılar', 'Profil'):
            with self.subTest(label=label):
                self.assertIn(f"tester.tap(find.text('{label}').first)", source)
        self.assertIn("Tahmin yok, hesap var.", source)
        self.assertIn("tester.takeException()", source)

    def test_catalog_is_not_on_the_tool_hub_but_its_screen_is_kept(self):
        hub = (ROOT / 'lib' / 'features' / 'tools' / 'tools_screen.dart').read_text(encoding='utf-8')
        source = (ROOT / 'integration_test' / 'app_launch_test.dart').read_text(encoding='utf-8')
        self.assertNotIn('CatalogScreen', hub)
        self.assertTrue((ROOT / 'lib' / 'features' / 'catalog' / 'catalog_screen.dart').exists())
        self.assertIn("expect(find.text('Katalog'), findsNothing)", source)

if __name__ == '__main__':
    unittest.main()
