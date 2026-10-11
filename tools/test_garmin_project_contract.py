"""Static contract for the Garmin Connect IQ prototype (garmin/).

The Connect IQ SDK requires accepting Garmin's license, so the project is not
compiled here. These checks only pin what can be read without the SDK.
"""
from __future__ import annotations

import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GARMIN = ROOT / "garmin"
NS = {"iq": "http://www.garmin.com/xml/connectiq"}

# Message schema v1 (phone: lib/services/watch/watch_solution.dart).
V1_KEYS = (
    "v", "ok", "profile", "at", "range", "rangeUnit", "rangeStep", "up",
    "right", "upAngle", "rightAngle", "unit", "click", "windSpeed",
    "windUnit", "windClock",
)


class GarminProjectContract(unittest.TestCase):
    def setUp(self):
        self.manifest = ET.parse(GARMIN / "manifest.xml").getroot()
        self.app = self.manifest.find("iq:application", NS)
        self.sources = {p.name: p.read_text(encoding="utf-8") for p in (GARMIN / "source").glob("*.mc")}

    def test_manifest_is_a_watch_app_with_phone_messaging(self):
        self.assertEqual(self.app.get("type"), "watch-app")
        self.assertRegex(self.app.get("id"), r"^[0-9a-f]{32}$")
        perms = [p.get("id") for p in self.app.find("iq:permissions", NS)]
        self.assertEqual(perms, ["Communications"])
        self.assertTrue(self.app.find("iq:products", NS))
        self.assertEqual([l.text for l in self.app.find("iq:languages", NS)], ["tur"])

    def test_entry_class_and_resources_exist(self):
        entry = self.app.get("entry")
        self.assertTrue(any(f"class {entry} extends Application.AppBase" in t for t in self.sources.values()))
        self.assertTrue((GARMIN / "resources/drawables/launcher_icon.png").is_file())
        self.assertIn('id="AppName"', (GARMIN / "resources/strings/strings.xml").read_text(encoding="utf-8"))

    def test_reads_every_v1_field_and_checks_the_version(self):
        solution = self.sources["Solution.mc"]
        for key in V1_KEYS:
            self.assertIn(f'm.get("{key}")', solution, key)
        self.assertIn('toNum(m.get("v")) != 1', solution)

    def test_receives_and_requests_through_the_phone_link(self):
        app = self.sources["SniperTurkApp.mc"]
        self.assertIn("registerForPhoneAppMessages", app)
        rng = self.sources["RangeView.mc"]
        self.assertIn('{"type" => "setRange", "value" => view.value}', rng)

    def test_no_ballistics_and_no_bold_text(self):
        joined = "\n".join(self.sources.values())
        self.assertNotRegex(joined, r"FONT_[A-Z_]*BOLD")
        # The watch never solves: no drag/trajectory math on the watch side.
        self.assertNotRegex(joined.lower(), r"\b(drag|trajectory|ballisticcoefficient)\b")

    def test_no_keys_or_secrets_committed(self):
        for p in GARMIN.rglob("*"):
            self.assertNotRegex(p.name, r"\.(der|pem|p12|key)$")


if __name__ == "__main__":
    unittest.main()
