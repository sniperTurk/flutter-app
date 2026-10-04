#!/usr/bin/env python3
import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class ValidatorReceiptTests(unittest.TestCase):
    def test_bootstrap_writes_hash_receipt(self):
        s=(ROOT/'tools/bootstrap_reference_validator.py').read_text()
        self.assertIn('sniper_turk_validator_receipt.json', s)
        self.assertIn('"wheel_sha256": expected_hash', s)
        self.assertIn('"wheel_sha256": dep_hash', s)
    def test_generator_requires_isolated_venv(self):
        s=(ROOT/'tools/generate_reference_vectors.py').read_text()
        self.assertIn('actual_prefix != expected_venv', s)
        self.assertIn('verify_bootstrap_receipt(acceptance)', s)
    def test_generator_requires_exact_receipt_policy_match(self):
        s=(ROOT/'tools/generate_reference_vectors.py').read_text()
        self.assertIn('if receipt != expected:', s)
        self.assertIn('bootstrap receipt does not exactly match acceptance policy', s)
if __name__=='__main__': unittest.main()
