import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'tools' / 'export_signed_app_store_ipa.sh'

class SignedExportPathSafetyContract(unittest.TestCase):
    def test_export_cleanup_is_confined_to_build_ios(self):
        text = SCRIPT.read_text(encoding='utf-8')
        self.assertIn('SAFE_EXPORT_ROOT="$ROOT/build/ios"', text)
        self.assertIn('EXPORT_DIR_ABS=', text)
        self.assertIn('Unsafe export directory', text)
        self.assertIn('[[ "$EXPORT_DIR_ABS" == "$SAFE_EXPORT_ROOT"/* ]]', text)
        self.assertIn('[[ ! -L "$EXPORT_DIR_ABS" ]]', text)
        self.assertLess(text.index('Unsafe export directory'), text.index('rm -rf "$EXPORT_DIR_ABS"'))
        self.assertNotIn('rm -rf "$EXPORT_DIR"', text)

if __name__ == '__main__':
    unittest.main()
