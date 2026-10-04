from pathlib import Path
import unittest

class TestV235ChronographUiWiring(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = Path('lib/features/chronograph/chronograph_screen.dart').read_text()

    def test_real_capture_controller_is_wired(self):
        self.assertIn('ChronographCaptureController(MethodChannelChronographAudioSource())', self.source)
        self.assertIn('captureController.captureOne', self.source)
        self.assertIn('distanceMeters: d', self.source)
        self.assertIn('temperatureC: t', self.source)

    def test_microphone_result_is_explicitly_unvalidated(self):
        self.assertIn('Mikrofonla tahmini ölç', self.source)
        self.assertIn('namlu çıkış hızı değildir', self.source)
        self.assertIn('MeasurementStatus.estimated', self.source)

    def test_capture_is_guarded_and_disposed(self):
        self.assertIn('if (capturing) return;', self.source)
        self.assertIn('captureController.dispose();', self.source)
        self.assertIn('onPressed: capturing ? null', self.source)

if __name__ == '__main__': unittest.main()
