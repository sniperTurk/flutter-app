import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"


class VacuumClickSuppressionContractTest(unittest.TestCase):
    def test_vacuum_table_does_not_expose_turret_click_instruction(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertNotIn("DataColumn(label: Text('Klik'))", text)
        self.assertNotIn("BallisticEngine().clicks", text)
        self.assertIn("Klik/tambur talimatı bu nedenle gösterilmez", text)


if __name__ == "__main__":
    unittest.main()
