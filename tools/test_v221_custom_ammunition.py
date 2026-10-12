from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class CustomAmmunitionTests(unittest.TestCase):
    def test_personal_provenance(self):
        source = (ROOT/'lib/data/user_catalog.dart').read_text()
        self.assertIn("case 'custom_ammunition':",source)
        self.assertIn("'Özel yapım mühimmat; doğrulanmamış kişisel kayıt'",source)
