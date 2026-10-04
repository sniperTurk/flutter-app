import unittest
from select_ios_simulator import select_available_ios_udid


class SelectIosSimulatorTests(unittest.TestCase):
    def test_selects_first_available_ios_device(self):
        data = {"devices": {
            "com.apple.CoreSimulator.SimRuntime.watchOS-12-0": [{"udid": "WATCH", "isAvailable": True}],
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
                {"udid": "OFFLINE", "isAvailable": False},
                {"udid": "IOS-OK", "isAvailable": True},
                {"udid": "IOS-LATER", "isAvailable": True},
            ],
        }}
        self.assertEqual("IOS-OK", select_available_ios_udid(data))

    def test_returns_none_when_no_available_ios_device_exists(self):
        self.assertIsNone(select_available_ios_udid({"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [{"udid": "NO", "isAvailable": False}],
        }}))

    def test_ignores_malformed_device_entries(self):
        self.assertIsNone(select_available_ios_udid({"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [None, "bad", {}],
        }}))


if __name__ == '__main__':
    unittest.main()
