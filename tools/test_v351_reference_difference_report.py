import json, subprocess, sys, tempfile, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools/report_reference_vector_differences.py"
POLICY = json.loads((ROOT / "validation/acceptance.json").read_text(encoding="utf-8"))

class ReferenceDifferenceReportTest(unittest.TestCase):
    def test_tool_is_diagnostic_and_contract_first(self):
        text = TOOL.read_text(encoding="utf-8")
        self.assertIn("validate(fixture, POLICY)", text)
        self.assertIn("gate action: NONE", text)
        self.assertNotIn("write_text", text)
        self.assertNotIn("acceptance.json').write", text)

    def test_rejects_invalid_fixture_without_mutating_policy(self):
        before = (ROOT / "validation/acceptance.json").read_bytes()
        with tempfile.TemporaryDirectory() as td:
            bad = Path(td) / "bad.json"
            bad.write_text(json.dumps({"schema": 1}), encoding="utf-8")
            p = subprocess.run([sys.executable, str(TOOL), str(bad)], cwd=td, capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)
        self.assertIn("fixture contract rejected", p.stderr)
        self.assertEqual(before, (ROOT / "validation/acceptance.json").read_bytes())

if __name__ == "__main__": unittest.main()
