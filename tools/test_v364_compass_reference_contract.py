"""V364/V366: compass reference must never be overstated NOR contradicted.

flutter_compass 0.8.1: the changelog (0.4.0) says iOS uses magnetic heading,
but the 0.8.1 iOS source reads CLHeading.trueHeading. They disagree and nothing
was verified on a device, so the UI claims neither true nor magnetic north.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CompassReferenceContract(unittest.TestCase):
    def test_ui_claims_neither_true_nor_magnetic_north(self):
        text = (ROOT / "lib/features/tools/compass_screen.dart").read_text(encoding="utf-8")
        self.assertIn("doğrulanmamıştır", text)
        self.assertNotIn("yön gerçek kuzeye (true north) göredir", text)
        self.assertNotIn("manyetik kuzeyi kullanır", text)

    def test_adapter_documents_the_source_changelog_conflict(self):
        text = (ROOT / "lib/tools/adapters/flutter_compass_heading_provider.dart").read_text(encoding="utf-8")
        self.assertIn("CLHeading.trueHeading", text)
        self.assertIn("magnetic", text)
        port = (ROOT / "lib/tools/ports/heading_provider.dart").read_text(encoding="utf-8")
        self.assertIn("unverified on a device", port)

    def test_invalid_heading_message_keeps_location_hint(self):
        text = (ROOT / "lib/features/tools/compass_screen.dart").read_text(encoding="utf-8")
        self.assertIn("Konum ayarlarını kontrol edip", text)


if __name__ == "__main__":
    unittest.main()
