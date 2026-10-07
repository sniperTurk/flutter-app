#!/usr/bin/env python3
"""Lock the location-privacy decision: ~1 km coordinates + coarse-location manifest."""
from pathlib import Path
import plistlib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LocationPrivacyContractTest(unittest.TestCase):
    def test_weather_request_uses_two_decimal_coordinates(self):
        src = (ROOT / "lib/tools/adapters/met_no_weather_provider.dart").read_text(encoding="utf-8")
        self.assertIn("WeatherPolicy.roundCoordinate(latitude)", src)
        self.assertIn("lat.toStringAsFixed(2)", src)
        self.assertIn("lon.toStringAsFixed(2)", src)
        self.assertNotIn("toStringAsFixed(4)", src)
        self.assertNotIn("_round4", src)

    def test_manifest_declares_unlinked_untracked_coarse_location(self):
        data = plistlib.loads((ROOT / "release/ios/PrivacyInfo.xcprivacy").read_bytes())
        self.assertFalse(data["NSPrivacyTracking"])
        items = data["NSPrivacyCollectedDataTypes"]
        self.assertEqual(1, len(items))
        item = items[0]
        self.assertEqual("NSPrivacyCollectedDataTypeCoarseLocation", item["NSPrivacyCollectedDataType"])
        self.assertIs(item["NSPrivacyCollectedDataTypeLinked"], False)
        self.assertIs(item["NSPrivacyCollectedDataTypeTracking"], False)
        self.assertEqual(
            ["NSPrivacyCollectedDataTypePurposeAppFunctionality"],
            item["NSPrivacyCollectedDataTypePurposes"],
        )


if __name__ == "__main__":
    unittest.main()
