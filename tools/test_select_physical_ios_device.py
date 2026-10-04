import unittest
from select_physical_ios_device import physical_ios_devices, select


class PhysicalIosSelectionTests(unittest.TestCase):
    def setUp(self):
        self.phone = {"name": "Birol iPhone", "id": "00008110-REAL", "targetPlatform": "ios", "emulator": False}
        self.sim = {"name": "iPhone 17 Pro", "id": "SIM-1", "targetPlatform": "ios", "emulator": True}
        self.mac = {"name": "Mac", "id": "macos", "targetPlatform": "darwin", "emulator": False}

    def test_only_physical_ios_is_eligible(self):
        self.assertEqual([self.phone], physical_ios_devices([self.sim, self.mac, self.phone]))

    def test_single_physical_device_is_selected(self):
        self.assertEqual("00008110-REAL", select([self.sim, self.phone])["id"])

    def test_simulator_only_fails(self):
        with self.assertRaisesRegex(ValueError, "no connected physical iOS"):
            select([self.sim])

    def test_multiple_devices_require_explicit_id(self):
        second = dict(self.phone, id="00008110-SECOND", name="Second iPhone")
        with self.assertRaisesRegex(ValueError, "multiple physical iOS"):
            select([self.phone, second])
        self.assertEqual("00008110-SECOND", select([self.phone, second], "00008110-SECOND")["id"])

    def test_requested_simulator_or_unknown_id_fails(self):
        with self.assertRaisesRegex(ValueError, "not connected"):
            select([self.phone, self.sim], "SIM-1")

    def test_malformed_top_level_payload_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "JSON array"):
            physical_ios_devices({"devices": [self.phone]})


if __name__ == "__main__":
    unittest.main()
