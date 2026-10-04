import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
GEN = ROOT / "tools" / "generate_reference_vectors.py"


class AtomicReferenceFixturePublicationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = GEN.read_text(encoding="utf-8")

    def test_fixture_is_validated_before_atomic_replace(self):
        validate_at = self.source.index("errors = validate(temp_path)")
        replace_at = self.source.index("os.replace(temp_path, OUT)")
        self.assertLess(validate_at, replace_at)
        self.assertIn("from validate_py_ballisticcalc_fixture import FROZEN_ATMOSPHERES, FROZEN_CASES, validate", self.source)

    def test_non_finite_json_and_partial_files_fail_closed(self):
        self.assertIn("allow_nan=False", self.source)
        self.assertIn("os.fsync(temp.fileno())", self.source)
        self.assertIn("temp_path.unlink(missing_ok=True)", self.source)
        self.assertNotIn("OUT.write_text(json.dumps(output", self.source)


if __name__ == "__main__":
    unittest.main()
