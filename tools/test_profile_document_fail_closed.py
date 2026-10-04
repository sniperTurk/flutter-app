#!/usr/bin/env python3
"""Static regression guard for profile collection fail-closed recovery."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class ProfileDocumentFailClosedTest(unittest.TestCase):
    def test_codec_does_not_swallow_malformed_profile_records(self):
        source = (ROOT / "lib/services/profile_document_codec.dart").read_text(encoding="utf-8")
        self.assertIn("throw FormatException('Invalid profile record at index $index')", source)
        self.assertIn("on FormatException catch (error)", source)
        self.assertNotIn("One malformed record must not make unrelated valid profiles unreadable", source)

    def test_flutter_regression_expects_fail_closed_semantics(self):
        source = (ROOT / "test/profile_document_codec_test.dart").read_text(encoding="utf-8")
        self.assertIn("malformed record fails closed instead of returning a partial collection", source)
        self.assertIn("non-map profile record also fails closed", source)
        self.assertGreaterEqual(source.count("throwsFormatException"), 3)

if __name__ == "__main__":
    unittest.main()
