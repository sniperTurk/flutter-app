import unittest
from pathlib import Path

SCREEN = Path(__file__).resolve().parents[1] / "lib/features/ballistics/ballistics_screen.dart"


class VacuumTableLabelsTest(unittest.TestCase):
    """The vacuum baseline returns muzzle velocity/energy at every range."""

    def test_energy_column_is_labelled_as_muzzle_energy(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertNotIn("'Enerji J'", text)
        self.assertNotIn("'Enerji ft-lb'", text)
        self.assertIn("Namlu enerjisi J*", text)
        self.assertIn("Namlu enerjisi ft-lb*", text)

    def test_footnote_states_drag_is_not_modelled(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertIn("hava direncini hesaplamaz", text)
        self.assertIn("Gerçek atış için kullanmayın", text)


if __name__ == "__main__":
    unittest.main()
