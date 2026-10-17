"""Pre-TestFlight audit 2026-10-14c: independent references and guards.

Stdlib only. No ballistic app is used: the atmosphere comes from the
US Standard Atmosphere 1976 constants (same as ICAO below 11 km) and the
ideal gas law.

Run: python3 -m unittest tools/test_denetim_2026_10_14c.py
"""
from __future__ import annotations

import re
import subprocess
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from dart_library_source import library_text  # noqa: E402

from dart_library_source import library_text

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"
PROFILES = ROOT / "lib/features/profiles/profiles_screen.dart"
ATM1_TEST = ROOT / "test/audit_2026_10_14b/atm1_restart_solve_test.dart"
PRF2_TEST = ROOT / "test/audit_2026_10_14b/prf2_kopyala_test.dart"

# US Standard Atmosphere 1976 / ICAO, troposphere.
P0_HPA = 1013.25
T0_K = 288.15
LAPSE = 0.0065  # K/m
G0 = 9.80665  # m/s²
M_AIR = 0.0289644  # kg/mol
R_STAR = 8.3144598  # J/(mol·K)
R_DRY = R_STAR / M_AIR  # ≈ 287.053 J/(kg·K)

FLAGS = (
    "WIND_OBSERVATION",
    "SCOPE_LISTEDE_YOK",
    "RIFLE_LISTEDE_YOK",
    "AMMO_BC_BANDS_TYPED",
    "AMMO_LISTEDE_YOK",
    "PROFILE_BACKUP_BUTTONS",
    "GOOGLE_MAPS_ENABLED",
)


def isa_pressure_hpa(h_m: float) -> float:
    return P0_HPA * (1 - LAPSE * h_m / T0_K) ** (G0 * M_AIR / (R_STAR * LAPSE))


def dry_density(p_hpa: float, t_c: float) -> float:
    return p_hpa * 100 / (R_DRY * (t_c + 273.15))


def _method(src: str, signature: str) -> str:
    i = src.index(signature)
    j = src.index("{", i)
    depth = 0
    for k in range(j, len(src)):
        if src[k] == "{":
            depth += 1
        elif src[k] == "}":
            depth -= 1
            if depth == 0:
                return src[i:k + 1]
    raise AssertionError(signature)


def _code(src: str) -> str:
    return "\n".join(l for l in src.splitlines() if not l.lstrip().startswith("//"))


class Atm1References(unittest.TestCase):
    """The numbers the ATM-1 tests expect, from first principles."""

    def test_isa_1500_m(self):
        self.assertAlmostEqual(isa_pressure_hpa(1500), 845.56, delta=0.01)

    def test_density_1500_m_15c_dry(self):
        rho = dry_density(isa_pressure_hpa(1500), 15)
        self.assertAlmostEqual(rho, 1.0223, delta=0.0001)

    def test_density_sea_level_and_900_hpa(self):
        self.assertAlmostEqual(dry_density(1013.25, 15), 1.2250, delta=0.0001)
        self.assertAlmostEqual(dry_density(900, 15), 1.0881, delta=0.0001)


class Atm1Fix(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.body = _method(
            library_text(SCREEN),
            "Future<void> _loadShotSettings() async {",
        )

    def test_one_quiet_solve_only_after_a_restore(self):
        self.assertEqual(_code(self.body).count("_quietSolve()"), 1)
        block = _method(self.body, "if (s != null) {")
        self.assertIn("_quietSolve()", block)

    def test_no_network_or_timer_in_the_restore(self):
        for call in ("_fillWeather", "_maybeAutoWeather", "_warmUpPhoneAltitude",
                     "_fillPressure", "Timer(", "http"):
            self.assertNotIn(call, _code(self.body), call)

    def test_own_save_does_not_trigger_a_reload(self):
        # A reload (and its solve) runs only on another page's write: the
        # store's save() must not bump the notifiers, or every edit would
        # re-solve in a loop.
        store = (ROOT / "lib/services/shot_settings_store.dart").read_text(
            encoding="utf-8")
        save = _method(store, "Future<void> save(String profileId, ShotSettings settings) async {")
        self.assertNotIn("changes.value", save)
        self.assertNotIn("externalWrites", save)

    def test_atm1_dart_tests_are_not_skipped(self):
        src = ATM1_TEST.read_text(encoding="utf-8")
        self.assertIsNone(re.search(r"\bskip\s*:", _code(src)))
        self.assertIn("Hava yoğunluğu after a restart matches the restored boxes", src)


class Prf2Fix(unittest.TestCase):
    def test_prf2_dart_tests_present_and_not_skipped(self):
        self.assertTrue(PRF2_TEST.exists(), "PRF-2 tests (#313) missing on main")
        src = PRF2_TEST.read_text(encoding="utf-8")
        self.assertIsNone(re.search(r"\bskip\s*:", _code(src)))
        self.assertIn("editing the copy's BC leaves the original profile alone",
                      src.replace("\\'", "'"))

    def test_editor_never_overwrites_a_shared_record(self):
        src = library_text("lib/features/profiles/profiles_screen.dart")
        for entry in ("Map<String, dynamic> _rifleEntry()",
                      "Map<String, dynamic> _ammoEntry()",
                      "Map<String, dynamic> _scopeEntry()"):
            self.assertIn("_ownsRecord(", _method(src, entry), entry)

    def test_kopyala_keeps_catalog_ids(self):
        src = library_text("lib/features/profiles/profiles_screen.dart")
        body = _method(src, "_copyPersonalRecords(RifleProfile p) async {")
        # Not in the personal store (catalog or missing): the id is kept.
        self.assertRegex(body, r"if \(found == null\) return id;")


class HiddenFlags(unittest.TestCase):
    def test_every_flag_defaults_off(self):
        lib = "\n".join(p.read_text(encoding="utf-8")
                        for p in (ROOT / "lib").rglob("*.dart"))
        for flag in FLAGS:
            m = re.search(r"bool\.fromEnvironment\(\s*'%s'\s*(,[^)]*)?\)" % flag, lib)
            self.assertIsNotNone(m, flag)
            self.assertNotIn("defaultValue: true", m.group(0), flag)


class NoApiKey(unittest.TestCase):
    def test_no_google_key_in_tracked_files(self):
        files = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True,
            check=True).stdout.split()
        hits = []
        for f in files:
            p = ROOT / f
            try:
                text = p.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            if re.search(r"AIza[0-9A-Za-z_\-]{30,}", text):
                hits.append(f)
        self.assertEqual(hits, [])


if __name__ == "__main__":
    unittest.main()
