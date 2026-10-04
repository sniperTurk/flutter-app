import contextlib
import io
import tempfile
import unittest
from pathlib import Path

from tools import bootstrap_reference_validator as b


class BootstrapPolicyFailClosed(unittest.TestCase):
    def assertBlocked(self, payload: bytes):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "acceptance.json"
            p.write_bytes(payload)
            err = io.StringIO()
            with contextlib.redirect_stderr(err), self.assertRaises(SystemExit) as cm:
                b._read_policy(p)
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("validator bootstrap FAILED: could not read acceptance policy", err.getvalue())

    def test_non_utf8_policy_is_blocked(self):
        self.assertBlocked(b"\xff\xfe")

    def test_malformed_json_policy_is_blocked(self):
        self.assertBlocked(b'{"reference":')

    def test_missing_policy_is_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            err = io.StringIO()
            with contextlib.redirect_stderr(err), self.assertRaises(SystemExit) as cm:
                b._read_policy(Path(d) / "missing.json")
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("could not read acceptance policy", err.getvalue())

    def test_non_object_policy_is_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "acceptance.json"
            p.write_text("[]", encoding="utf-8")
            err = io.StringIO()
            with contextlib.redirect_stderr(err), self.assertRaises(SystemExit) as cm:
                b._read_policy(p)
            self.assertEqual(cm.exception.code, 2)
            self.assertIn("root must be a JSON object", err.getvalue())


if __name__ == "__main__":
    unittest.main()
