from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class CustomAmmunitionTests(unittest.TestCase):
    def test_separate_section_and_edit_delete(self):
        source = (ROOT/'lib/features/catalog/catalog_screen.dart').read_text()
        for token in ['Özel Yapım Mermiler','custom-ammunition-add',"'custom_ammunition'",'diameterMm','lengthMm','bcModel','material','shape','lot','_manualStore.upsert(entry)','_manualStore.remove(']:
            self.assertIn(token,source)
    def test_personal_provenance(self):
        source = (ROOT/'lib/features/catalog/catalog_screen.dart').read_text()
        self.assertIn('Özel yapım mühimmat; doğrulanmamış kişisel kayıt',source)
        self.assertIn("e['platform'] == platform.name",source)
