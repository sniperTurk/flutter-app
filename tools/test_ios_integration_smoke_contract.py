import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class IosIntegrationSmokeContractTest(unittest.TestCase):
    def test_clean_install_smoke_covers_core_safe_routes_and_dope_gate(self):
        source = (ROOT / 'integration_test' / 'app_launch_test.dart').read_text(encoding='utf-8')
        # Menzil shell: Katalog and Ayarlar open from the Araçlar tab, profile
        # management is the Profil tab.
        for label in ('Araçlar', 'Katalog', 'Profil', 'Ayarlar'):
            with self.subTest(label=label):
                self.assertIn(f"tester.tap(find.text('{label}').first)", source)
        self.assertIn("DOPE için önce aktif profil oluşturun", source)
        self.assertIn("tester.takeException()", source)

    def test_count_suffixed_catalog_headers_use_containing_matchers(self):
        """Catalog section headers render "<title> (N)"; exact find.text() on
        the bare title can never match them and would fail the iOS smoke run."""
        screen = (ROOT / 'lib' / 'features' / 'catalog' / 'catalog_screen.dart').read_text(encoding='utf-8')
        source = (ROOT / 'integration_test' / 'app_launch_test.dart').read_text(encoding='utf-8')
        self.assertIn("Mühimmat (${ammunition.length})", screen)
        self.assertIn("'Dürbünler (${scopes.length})'", screen)
        for title in ('PCP Mühimmat', 'Dürbünler'):
            with self.subTest(title=title):
                self.assertNotIn(f"find.text('{title}')", source)
                self.assertIn(f"find.textContaining('{title}')", source)


if __name__ == '__main__':
    unittest.main()
