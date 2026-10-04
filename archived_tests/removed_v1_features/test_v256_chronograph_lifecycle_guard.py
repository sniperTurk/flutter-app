#!/usr/bin/env python3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = (ROOT/'lib/services/chronograph_capture_controller.dart').read_text()
SCREEN = (ROOT/'lib/features/chronograph/chronograph_screen.dart').read_text()

class ChronographLifecycleGuardTest(unittest.TestCase):
    def test_controller_cancellation_resolves_active_capture_as_rejected(self):
        self.assertIn('Completer<ChronographReading>? _activeCompleter;', CONTROLLER)
        self.assertIn("Future<void> cancelActiveCapture({String errorCode = 'AUDIO_CAPTURE_CANCELLED'})", CONTROLLER)
        self.assertIn('status: MeasurementStatus.rejected', CONTROLLER)
        self.assertIn("Future<void> dispose() => cancelActiveCapture(errorCode: 'AUDIO_CAPTURE_DISPOSED');", CONTROLLER)

    def test_screen_stops_microphone_when_leaving_foreground(self):
        self.assertIn('with WidgetsBindingObserver', SCREEN)
        self.assertIn('WidgetsBinding.instance.addObserver(this);', SCREEN)
        self.assertIn('WidgetsBinding.instance.removeObserver(this);', SCREEN)
        self.assertIn("captureController.cancelActiveCapture(errorCode: 'AUDIO_CAPTURE_BACKGROUND');", SCREEN)
        for state in ('inactive', 'paused', 'hidden', 'detached'):
            self.assertIn(f'AppLifecycleState.{state}', SCREEN)

    def test_background_cancellation_is_distinct_from_dispose(self):
        self.assertIn("'AUDIO_CAPTURE_BACKGROUND'", SCREEN)
        self.assertIn("'AUDIO_CAPTURE_DISPOSED'", CONTROLLER)

if __name__ == '__main__':
    unittest.main()
