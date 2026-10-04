#!/usr/bin/env python3
from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/'lib/features/field_tools/field_tools_screen.dart').read_text()
class LevelLifecycleTests(unittest.TestCase):
 def test_observer_registered_and_removed(self):
  self.assertIn('with WidgetsBindingObserver',S); self.assertIn('WidgetsBinding.instance.addObserver(this);',S); self.assertIn('WidgetsBinding.instance.removeObserver(this);',S)
 def test_sensor_stops_offscreen_and_resumes(self):
  self.assertIn('void didChangeAppLifecycleState(AppLifecycleState state)',S); self.assertIn('state == AppLifecycleState.resumed',S); self.assertIn('_stopSensor();',S); self.assertIn('_startSensor();',S)
 def test_subscription_restart_is_idempotent(self):
  self.assertIn('if (_subscription != null) return;',S); self.assertIn('_subscription = null;',S)
if __name__=='__main__': unittest.main()
