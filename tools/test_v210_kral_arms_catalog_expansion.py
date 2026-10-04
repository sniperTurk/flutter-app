import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "lib" / "data" / "catalog_repository.dart"

EXPECTED = {
    "kral-nish-s-635": ("NISH S", 530, 280, 1000, 3.30),
    "kral-nish-w-635": ("NISH W", 530, 280, 1000, 3.65),
    "kral-empire-635": ("Empire", 480, 330, 760, 3.90),
    "kral-empire-x-635": ("Empire X", 480, 600, 760, 3.60),
    "kral-knight-635": ("Knight", 580, 500, 875, 4.0),
    "kral-mortal-x-635": ("Mortal X", 580, 330, 1010, 4.05),
    "kral-bighorn-635": ("Bighorn", 580, 500, 1050, 3.70),
    "kral-rambo-635": ("Rambo Pump Action", 530, 280, 915, 3.40),
    "kral-pro-500-635": ("PRO 500", 530, 500, 1050, 3.80),
    "kral-shadow-635": ("Shadow", 530, 500, 1050, 3.50),
    "kral-np03-635": ("Puncher NP-03", 407, 180, 572, 3.00),
    "kral-np02-635": ("Puncher NP-02", 330, 530, 770, 3.10),
    "kral-np500-635": ("NP 500", 407, 500, 770, 3.70),
    "kral-auto-635": ("Auto", 480, 425, 730, 3.65),
    "kral-mortal-635": ("Mortal", 407, 200, 840, 3.51),
    "kral-unica-635": ("Unica", 580, 330, 1050, 4.20),
}


def record_for(text: str, record_id: str) -> str:
    match = re.search(r"Rifle\(id:'" + re.escape(record_id) + r"'[^\n]+", text)
    if not match:
        raise AssertionError(f"missing catalog record {record_id}")
    return match.group(0)


class KralArmsCatalogExpansionTest(unittest.TestCase):
    def test_current_635_records_are_manufacturer_sourced_with_exact_published_core_specs(self):
        text = CATALOG.read_text(encoding="utf-8")
        for record_id, (model, barrel, air, length, weight) in EXPECTED.items():
            with self.subTest(record_id=record_id):
                record = record_for(text, record_id)
                self.assertIn("brand:'Kral Arms'", record)
                self.assertIn(f"model:'{model}'", record)
                self.assertIn("platform:WeaponPlatform.pcp", record)
                self.assertIn("caliberMm:6.35", record)
                self.assertIn("magazineCapacity:10", record)
                self.assertIn(f"barrelLengthMm:{barrel}", record)
                self.assertIn(f"airCapacityCc:{air}", record)
                self.assertIn(f"overallLengthMm:{length}", record)
                self.assertRegex(record, rf"weightKg:{re.escape(str(weight))}(?:0)?(?:,|\))")
                self.assertIn("sourceName:'Kral Arms'", record)
                self.assertIn("official product page, verified 2026-09-29", record)

    def test_kral_records_do_not_invent_unpublished_optional_hardware_specs(self):
        text = CATALOG.read_text(encoding="utf-8")
        for record_id in EXPECTED:
            record = record_for(text, record_id)
            self.assertNotIn("plenumCc:", record)
            self.assertNotIn("moderatorThread:", record)
            self.assertNotIn("rail:", record)
            self.assertNotIn("barrelType:", record)


if __name__ == "__main__":
    unittest.main()
