import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"


class VacuumClickSuppressionContractTest(unittest.TestCase):
    """V354 superseded this gate for ELEVATION ONLY: elevation clicks are now
    valid vacuum trigonometry (atan2(drop, range)) and are shown with an
    explicit live-fire-confirmation disclaimer. WIND clicks remain fully
    suppressed, since a vacuum model has no aerodynamic coupling to produce
    a real wind value — that half of this contract must still hold.
    """

    def test_dope_table_does_not_add_a_per_row_click_column(self):
        text = SCREEN.read_text(encoding="utf-8")
        # Per-row click counts depend on the specific scope's click size, so
        # they stay out of the multi-range DOPE table; only the angular
        # MOA/mrad values are tabulated there (see test_v354_*).
        self.assertNotIn("DataColumn(label: Text('Klik'))", text)

    def test_elevation_clicks_are_now_computed_from_the_vacuum_model(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertIn("const BallisticEngine().clicks(", text)

    def test_wind_click_suppression_language_is_still_present(self):
        text = SCREEN.read_text(encoding="utf-8")
        self.assertIn("Rüzgâr düzeltmesi/kliki hiç üretilmez (KİLİTLİ)", text)
        self.assertIn("Rüzgâr düzeltmesi hiç modellenmez (KİLİTLİ)", text)


if __name__ == "__main__":
    unittest.main()
