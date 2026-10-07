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
        # V354: elevation is now computed from the vacuum drop and shown as
        # an estimate; the footnote/danger-notice text was reworded to say so
        # explicitly instead of blanket-refusing any angular correction. The
        # drag/wind-not-modelled disclosure and the live-fire-confirmation
        # requirement must still both be present somewhere on the screen.
        text = SCREEN.read_text(encoding="utf-8")
        self.assertIn("hava direncini hesaplamaz", text)
        self.assertIn("canlı atışla teyit edilmelidir", text)
        self.assertIn("gerçek atış için kullanmayın", text)


if __name__ == "__main__":
    unittest.main()
