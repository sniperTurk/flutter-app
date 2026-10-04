from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V233IOSAudioBridge(unittest.TestCase):
  def test_dart_adapter_contract(self):
    s=(ROOT/'lib/services/method_channel_chronograph_audio_source.dart').read_text()
    self.assertIn("sniper_turk/chronograph_audio_control",s); self.assertIn("sniper_turk/chronograph_audio_events",s)
    self.assertIn("absoluteStartSample",s); self.assertIn("FormatException",s)
  def test_native_bridge_and_bootstrap(self):
    s=(ROOT/'native/ios/SniperChronographAudioPlugin.swift').read_text()
    self.assertIn('AVAudioEngine',s); self.assertIn('requestRecordPermission',s); self.assertIn('absoluteStartSample',s); self.assertIn('AVAudioSession.sharedInstance().requestRecordPermission',s)
    b=(ROOT/'tools/bootstrap_ios_scaffold.sh').read_text(); self.assertIn('install_ios_chronograph_audio_bridge.rb',b)
    installer=(ROOT/'tools/install_ios_chronograph_audio_bridge.rb').read_text(); self.assertIn('source_build_phase.add_file_reference',installer)
  def test_permission_is_configured(self):
    s=(ROOT/'tools/configure_ios_info_plist.py').read_text(); self.assertIn('NSMicrophoneUsageDescription',s)
if __name__=='__main__': unittest.main()
