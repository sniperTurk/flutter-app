from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V232StreamingAudioDetector(unittest.TestCase):
    def test_streaming_adapter_preserves_tail_and_fails_closed(self):
        source=(ROOT/'lib/core/audio_transient_detector.dart').read_text()
        self.assertIn('class StreamingAudioTransientDetector', source)
        self.assertIn('_pending.removeRange(0, completeLength)', source)
        self.assertIn("PCM chunks are not contiguous", source)
        self.assertIn("Sample rate changed during an active audio stream", source)
    def test_dart_regression_tests_exist(self):
        source=(ROOT/'test/audio_transient_streaming_test.dart').read_text()
        self.assertIn('preserves a transient split across microphone chunks', source)
        self.assertIn('rejects gaps instead of silently corrupting timing', source)
        self.assertIn('rejects sample-rate changes within one stream', source)
if __name__=='__main__': unittest.main()
