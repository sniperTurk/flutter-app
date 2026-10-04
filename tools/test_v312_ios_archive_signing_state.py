import plistlib, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import verify_ios_archive_signing_state as mod

class Proc:
    def __init__(self, code): self.returncode=code; self.stdout=''; self.stderr=''

class TestSigningState(unittest.TestCase):
    def make_archive(self):
        td=tempfile.TemporaryDirectory(); root=Path(td.name)/'Runner.xcarchive'; app=root/'Products/Applications/Runner.app'; app.mkdir(parents=True)
        with (app/'Info.plist').open('wb') as f: plistlib.dump({'CFBundleIdentifier':'com.sniperturk.sniperTurk'}, f)
        return td, root, app
    @patch('verify_ios_archive_signing_state.subprocess.run', return_value=Proc(1))
    def test_accepts_truly_unsigned_archive(self, _):
        td, root, _app=self.make_archive(); self.addCleanup(td.cleanup)
        mod.verify_unsigned(root,'com.sniperturk.sniperTurk')
    @patch('verify_ios_archive_signing_state.subprocess.run', return_value=Proc(0))
    def test_rejects_signed_archive(self, _):
        td, root, _app=self.make_archive(); self.addCleanup(td.cleanup)
        with self.assertRaises(SystemExit): mod.verify_unsigned(root,'com.sniperturk.sniperTurk')
    @patch('verify_ios_archive_signing_state.subprocess.run', return_value=Proc(1))
    def test_rejects_embedded_profile(self, _):
        td, root, app=self.make_archive(); self.addCleanup(td.cleanup); (app/'embedded.mobileprovision').write_bytes(b'x')
        with self.assertRaises(SystemExit): mod.verify_unsigned(root,'com.sniperturk.sniperTurk')
