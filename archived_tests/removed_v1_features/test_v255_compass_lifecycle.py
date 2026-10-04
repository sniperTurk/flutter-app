#!/usr/bin/env python3
from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/'lib/features/field_tools/field_tools_screen.dart').read_text()
C=S[S.index('class _CompassScreenState'):S.index('class SpiritLevelScreen')]
class CompassLifecycleTests(unittest.TestCase):
 def test_compass_observer_registered_and_removed(self):
  self.assertIn('with WidgetsBindingObserver',C); self.assertIn('WidgetsBinding.instance.addObserver(this);',C); self.assertIn('WidgetsBinding.instance.removeObserver(this);',C)
 def test_compass_stops_in_background_and_resumes_idempotently(self):
  self.assertIn('void _startCompass()',C); self.assertIn('if (_subscription != null) return;',C); self.assertIn('Future<void> _stopCompass()',C); self.assertIn('state == AppLifecycleState.resumed',C); self.assertIn('_stopCompass();',C)
 def test_invalid_heading_does_not_destroy_last_valid_bearing(self):
  invalid=C[C.index('if (heading == null || !heading.isFinite)'):C.index("setState(() {\n        _heading", C.index('if (heading == null || !heading.isFinite)'))]
  self.assertNotIn('_heading =', invalid); self.assertIn('return;', invalid)
if __name__=='__main__': unittest.main()
