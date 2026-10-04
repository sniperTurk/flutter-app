#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
ADOPT = (ROOT / "tools" / "adopt_verified_lockfile.py").read_text(encoding="utf-8")

class V201LockfileAdoptionPairContract(unittest.TestCase):
    def test_adoption_installs_provenance_beside_lockfile(self):
        self.assertIn('provenance_destination = project_root / "lockfile-provenance.txt"', ADOPT)
        self.assertIn('(provenance, provenance_destination', ADOPT)

    def test_installed_pair_is_reverified_fail_closed(self):
        self.assertIn('verify(pubspec, destination, provenance_destination)', ADOPT)
        self.assertIn('installed pair failed verification', ADOPT)

if __name__ == "__main__":
    unittest.main()
