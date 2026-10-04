from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class SignedIpaIdentityGateTest(unittest.TestCase):
    def test_verifier_binds_signature_profile_team_and_bundle(self):
        text=(ROOT/'tools/verify_signed_app_store_ipa.py').read_text()
        for token in ['application-identifier','com.apple.developer.team-identifier','TeamIdentifier','security", "cms','CFBundleIdentifier','codesign", "--verify']:
            self.assertIn(token,text)
    def test_export_gate_invokes_identity_verifier(self):
        text=(ROOT/'tools/export_signed_app_store_ipa.sh').read_text()
        self.assertIn('verify_signed_app_store_ipa.py',text)
        self.assertIn('--team-id "$TEAM_ID"',text)
        self.assertIn('--bundle-id com.sniperturk.sniperTurk',text)
if __name__=='__main__': unittest.main()
