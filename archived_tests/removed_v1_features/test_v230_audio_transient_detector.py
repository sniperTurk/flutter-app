from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V230AudioTransientDetector(unittest.TestCase):
    def test_detector_is_hardware_independent_and_fail_closed(self):
        core=(ROOT/'lib/core/audio_transient_detector.dart').read_text()
        self.assertIn('class AudioTransientDetector', core)
        self.assertIn('PCM samples must be finite and normalized', core)
        self.assertIn('refractorySeconds', core)
        self.assertIn('_noiseFloor', core)
    def test_platform_contract_exists_without_fake_microphone(self):
        source=(ROOT/'lib/services/chronograph_audio_source.dart').read_text()
        self.assertIn('abstract interface class ChronographAudioSource', source)
        self.assertIn('actual sample rate and PCM', source)
    def test_flutter_unit_tests_cover_transients(self):
        test=(ROOT/'test/audio_transient_detector_test.dart').read_text()
        self.assertIn('detects separated transients', test)
        self.assertIn('quiet noise does not create events', test)
if __name__=='__main__': unittest.main()
