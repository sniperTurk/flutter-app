#!/usr/bin/env python3
"""Lock the iOS smoke test to a real profile persistence + DOPE route flow."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "integration_test" / "app_launch_test.dart"

class IosProfilePersistenceSmokeContractTest(unittest.TestCase):
    def test_smoke_creates_persists_and_uses_profile(self):
        text = SMOKE.read_text(encoding="utf-8")
        # Menzil shell: profiles are created from the Profil tab's
        # welcome page ("İlk profilimi oluştur") and DOPE is reached through the Atış/Tablo tabs.
        required = (
            "tester.tap(find.text('İlk profilimi oluştur'))",
            "find.text('Profil Oluştur')",
            "tester.tap(find.text('Kaydet'))",
            "find.text('Yeni Profil')",
            "find.text('Tahmin yok, hesap var.'), findsNothing",
            "tester.tap(find.text('Hedef').first)",
            "find.text('DOPE oluştur')",
        )
        for marker in required:
            with self.subTest(marker=marker):
                self.assertIn(marker, text)

    def test_smoke_enters_through_production_main(self):
        text = SMOKE.read_text(encoding="utf-8")
        self.assertIn("app.main();", text)
        self.assertIn("IntegrationTestWidgetsFlutterBinding.ensureInitialized()", text)

if __name__ == "__main__":
    unittest.main()
