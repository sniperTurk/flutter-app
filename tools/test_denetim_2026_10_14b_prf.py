"""Pre-TestFlight audit 2026-10-14b, area PROFILES / CATALOG RE-MATCHING /
PROFILE FLAGS (#308, commit 7eb1416).

Stdlib-only reference for test/audit_2026_10_14b/profile_match_audit_test.dart:

* a line-by-line Python port of ProfileCatalogMatch.rifle / brandMatches
  (lib/features/profiles/profile_catalog_match.dart) run on the real
  RifleLibrary (lib/data/rifle_library.dart), to show PRF-4 (HATSAN /
  Hercules Bully .25 renamed "Hercules") and PRF-5 (SARSILMAZ not matched)
  and that ambiguous names give no match;
* hand calculations: Barut katsayısı (%/15 °C) ⓘ example, fps round trip of
  the editor, MOA <-> mrad turret travel;
* repository greps: the hidden flags are read with bool.fromEnvironment and
  default off; _scopeEntry writes no windageRangeMrad (PRF-1); Kopyala and
  the editor reuse the same record ids (PRF-2); the editor rewrites the
  scope with the profile unit (PRF-3).

Run: python3 -m unittest tools/test_denetim_2026_10_14b_prf.py
"""
from __future__ import annotations

import math
import re
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from dart_library_source import library_text  # noqa: E402

from dart_library_source import library_text

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/profiles/profiles_screen.dart"
MATCH = ROOT / "lib/features/profiles/profile_catalog_match.dart"
RIFLES = ROOT / "lib/data/rifle_library.dart"
BALLISTICS = ROOT / "lib/features/ballistics/ballistics_screen.dart"

_RIFLE_RE = re.compile(
    r"LibraryRifle\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)', "
    r"WeaponPlatform\.(\w+), '((?:[^'\\]|\\.)*)', ([\d.]+)"
)


def _library():
    src = RIFLES.read_text(encoding="utf-8")
    return [
        {
            "brand": m.group(1).replace("\\'", "'"),
            "model": m.group(2).replace("\\'", "'"),
            "platform": m.group(3),
            "cartridge": m.group(4),
            "d": float(m.group(5)),
        }
        for m in _RIFLE_RE.finditer(src)
    ]


# ---- Port of ProfileCatalogMatch (Dart String.toLowerCase == Unicode
# default lower casing, as Python str.lower; Dart RegExp \w is ASCII). ----

def words(text):
    out = []
    for w in re.split(r"[^a-z0-9çğıöşü.]+", text.lower().replace(",", ".")):
        if w.replace(".", ""):
            out.append(re.sub(r"^\.+|\.+$", "", w))
    return out


def squash(text):
    return "".join(words(text)).replace(".", "")


_DESIGNATION = re.compile(
    r"\d+(?:[.,]\d+)?\s*(?:[–-]\s*\d+(?:[.,]\d+)?\s*)?[×xX]\s*\d+(?:[.,]\d+)?\w*",
    re.ASCII,
)


def brand_matches(saved, brand):
    s, b = squash(saved), squash(brand)
    if not s or len(b) < 3:
        return False
    if s == b or s.startswith(b):
        return True
    sw, bw = words(saved), words(brand)
    return bool(sw) and bool(bw) and len(sw[0]) >= 3 and sw[0] == bw[0]


def _covered(saved, cand):
    joined = "".join(cand).replace(".", "")
    return sum(1 for w in saved if w in cand or w.replace(".", "") in joined)


def _name_words(text, brand):
    drop = set(words(brand)) | {"ffp", "sfp"}
    return [w for w in words(_DESIGNATION.sub(" ", text)) if w not in drop]


def match_rifle(brand, model, caliber_mm, lib):
    if not squash(model):
        return None
    hits, seen = [], set()
    for r in lib:
        if not brand_matches(brand, r["brand"]):
            continue
        key = r["brand"] + "|" + r["model"]
        if key in seen:
            continue
        seen.add(key)
        mine = _name_words(model, r["brand"])
        theirs = _name_words(r["model"], r["brand"])
        if not mine or not theirs:
            continue
        exact = squash(" ".join(mine)) == squash(" ".join(theirs))
        a, b = _covered(mine, theirs), _covered(theirs, mine)
        f1 = (a + b) / (len(mine) + len(theirs))
        if not exact and a < len(mine) and b < len(theirs) and f1 < 0.67:
            continue
        cal = caliber_mm is not None and any(
            v["brand"] == r["brand"]
            and v["model"] == r["model"]
            and abs(v["d"] - caliber_mm) < 0.005
            for v in lib
        )
        hits.append({"r": r, "exact": exact, "f1": f1, "cal": cal})
    if not hits:
        return None
    pool = [h for h in hits if h["cal"]] if any(h["cal"] for h in hits) else hits
    pool.sort(key=lambda h: (not h["exact"], -h["f1"]))
    best = pool[0]
    if len(pool) > 1 and pool[1]["exact"] == best["exact"] and pool[1]["f1"] == best["f1"]:
        return None
    return best["r"]


def _platform(p):
    return [r for r in _library() if r["platform"] == p]


class PortFidelity(unittest.TestCase):
    """The port follows the Dart source it mirrors."""

    def test_dart_source_has_the_ported_rules(self):
        src = MATCH.read_text(encoding="utf-8")
        for needle in (
            "[^a-z0-9çğıöşü.]+",
            "sw.first.length >= 3",
            "f1 < 0.67",
            "hits.any((h) => h.caliber)",
            "next.exact == best.exact && next.f1 == best.f1",
        ):
            self.assertIn(needle, src)

    def test_library_parsed(self):
        lib = _library()
        self.assertGreater(len(lib), 4000)
        self.assertTrue(any(r["brand"] == "Sarsılmaz" for r in lib))

    def test_old_tikka_spelling_matches(self):
        r = match_rifle("TIKKA", "T3X Tact A1", 7.82, _platform("firearm"))
        self.assertEqual((r["brand"], r["model"]), ("Tikka", "T3x TACT A1"))

    def test_ambiguous_tikka_t3x_no_match(self):
        self.assertIsNone(match_rifle("Tikka", "T3x", 7.82, _platform("firearm")))


class Prf4CaliberBeatsExactName(unittest.TestCase):
    """PRF-4: documents today's behaviour (the Dart test expects the fix)."""

    def test_hercules_bully_has_no_635_variant(self):
        cal = {r["d"] for r in _platform("pcp")
               if r["brand"] == "Hatsan" and r["model"] == "Hercules Bully"}
        self.assertNotIn(6.35, cal)
        self.assertIn(6.35, {r["d"] for r in _platform("pcp")
                             if r["brand"] == "Hatsan" and r["model"] == "Hercules"})

    def test_hatsan_hercules_bully_renamed_hercules_today(self):
        r = match_rifle("HATSAN", "Hercules Bully", 6.35, _platform("pcp"))
        self.assertEqual(r["model"], "Hercules")  # finding: name replaced

    def test_editor_writes_the_list_name_into_the_saved_record(self):
        src = library_text("lib/features/profiles/profiles_screen.dart")
        self.assertIn("rifleBrand.text = match.brand;", src)
        self.assertIn("rifleModel.text = match.model;", src)
        self.assertIn("'model': rifleModel.text.trim(),", src)


class Prf5DotlessI(unittest.TestCase):
    def test_upper_case_dotless_i_brand_not_matched_today(self):
        self.assertEqual("SARSILMAZ".lower(), "sarsilmaz")
        self.assertNotEqual(squash("SARSILMAZ"), squash("Sarsılmaz"))
        self.assertFalse(brand_matches("SARSILMAZ", "Sarsılmaz"))
        self.assertIsNone(
            match_rifle("SARSILMAZ", "SAR 308 Versiyon 2", 7.82, _platform("firearm")))

    def test_dotted_capital_i_happens_to_work(self):
        # 'İ'.lower() is 'i' + U+0307; the split drops the combining dot.
        self.assertEqual(squash("İSTANBUL SİLAH"), squash("İstanbul Silah"))
        self.assertTrue(brand_matches("ISTANBUL SILAH", "İstanbul Silah"))


class PowderCoefficient(unittest.TestCase):
    """Barut katsayısı: % velocity change per 15 °C (unchanged by #308)."""

    @staticmethod
    def factor(k, t0, t):
        return 1 + k / 100 * (t - t0) / 15

    def test_info_example(self):
        # ⓘ: 10 °C 2600 fps, 25 °C 2639 fps -> 1,5.
        k = (2639 / 2600 - 1) * 100 * 15 / (25 - 10)
        self.assertAlmostEqual(k, 1.5, delta=0.01)
        self.assertAlmostEqual(2600 * self.factor(1.5, 10, 25), 2639, delta=0.5)

    def test_dart_formula_and_label(self):
        core = (ROOT / "lib/core/powder_temperature.dart").read_text(encoding="utf-8")
        self.assertIn("final f = 1 + k / 100 * (todayTempC - t0) / 15;", core)
        src = library_text("lib/features/profiles/profiles_screen.dart")
        i = src.index("label: 'Barut katsayısı',")
        block = src[i:i + 200]
        self.assertNotIn("unit:", block)  # no unit beside the label (#308)
        self.assertIn("p?.powderTempCoefPercentPer15C", src)
        info = (ROOT / "lib/features/profiles/profile_field_info.dart").read_text(encoding="utf-8")
        self.assertIn("hava 15 °C ısındığında namlu çıkış hızının", info)
        self.assertIn("yüzde kaç", info)


class EditorRounding(unittest.TestCase):
    def test_fps_one_decimal_round_trip_below_0_02_mps(self):
        worst = 0.0
        for i in range(1000, 15000):
            mps = i / 10
            fps = round(mps / 0.3048, 1)
            worst = max(worst, abs(fps * 0.3048 - mps))
        self.assertLess(worst, 0.016)

    def test_moa_travel_round_trip(self):
        mrad_per_moa = math.pi / (180 * 60) * 1000
        travel = 100 * mrad_per_moa
        clicks = round(travel / mrad_per_moa / 0.25)
        self.assertEqual(clicks, 400)
        self.assertAlmostEqual(clicks * 0.25 * mrad_per_moa, 29.08882086657216, places=9)


class RepositoryFacts(unittest.TestCase):
    def test_flags_read_from_environment_default_off(self):
        flags = {
            "SCOPE_LISTEDE_YOK": SCREEN,
            "RIFLE_LISTEDE_YOK": SCREEN,
            "AMMO_LISTEDE_YOK": SCREEN,
            "PROFILE_AMMO_LENGTH": SCREEN,
            "AMMO_BC_BANDS_TYPED": SCREEN,
            "PRO_TUBE_PRESSURE": BALLISTICS,
        }
        for flag, path in flags.items():
            # profiles_screen.dart is one library in several part files.
            src = (
                library_text("lib/features/profiles/profiles_screen.dart")
                if path == SCREEN
                else path.read_text(encoding="utf-8")
            )
            m = re.search(r"bool\.fromEnvironment\(\s*'%s'\s*(,[^)]*)?\)" % flag, src)
            self.assertIsNotNone(m, flag)
            self.assertNotIn("defaultValue: true", m.group(0), flag)

    def _scope_entry(self):
        src = library_text("lib/features/profiles/profiles_screen.dart")
        i = src.index("Map<String, dynamic> _scopeEntry()")
        return src[i:src.index("Future<void> _save()", i)]

    def test_prf1_scope_entry_writes_no_windage_travel(self):
        block = self._scope_entry()
        self.assertIn("'elevationRangeMrad'", block)
        self.assertNotIn("windageRangeMrad", block)  # finding PRF-1
        balli = library_text(BALLISTICS)
        self.assertIn("_halfTravelClicks(click, s.windageRangeMrad) ?? _unknownTravelClicks", balli)

    def test_prf2_copy_and_editor_reuse_record_ids(self):
        # PRF-2 fixed in #313: this test documented the bug (the copy reused
        # the original's record ids; the editor overwrote a shared personal
        # record). Flipped to the fixed state (CLAUDE.md: a fixed finding's
        # test must pass); the Dart PRF-2 tests are the behaviour guards.
        src = library_text("lib/features/profiles/profiles_screen.dart")
        i = src.index("Future<void> _duplicate(RifleProfile p)")
        dup = src[i:i + 1500]
        for f in ("rifleId: p.rifleId", "ammunitionId: p.ammunitionId", "scopeId: p.scopeId"):
            self.assertNotIn(f, dup)
        for f in ("rifleId: ids.rifleId", "ammunitionId: ids.ammunitionId", "scopeId: ids.scopeId"):
            self.assertIn(f, dup)
        self.assertEqual(src.count("existing != null && existing.userEntered"), 0)

    def test_prf3_scope_saved_with_profile_unit(self):
        block = self._scope_entry()
        self.assertIn("'clickUnit': angularUnit.name", block)
        src = library_text("lib/features/profiles/profiles_screen.dart")
        self.assertIn("angularUnit = p?.angularUnit ?? s0?.clickUnit ?? AngularUnit.mrad;", src)
        self.assertIn(": num(_defaultClick(angularUnit)),", src)
        match = MATCH.read_text(encoding="utf-8")
        self.assertIn("if (saved.clickUnit != r.clickUnit) continue;", match)

    def test_ammo_length_hidden_and_not_in_calculation(self):
        balli = library_text(BALLISTICS)
        self.assertIn("double? get _bulletLengthMm {", balli)
        i = balli.index("double? get _bulletLengthMm {")
        self.assertIn("bulletLengthCtl", balli[i:i + 300])
        src = library_text("lib/features/profiles/profiles_screen.dart")
        self.assertIn("_showProfileAmmoLength ? _parse(ammoLength) : ammo?.lengthMm", src)

    def test_pro_tube_pressure_off_uses_profile_value(self):
        balli = library_text(BALLISTICS)
        self.assertRegex(
            balli,
            r"final tube = _showProTubePressure\s*\?\s*_parsed\(tubePressureCtl\)\s*:\s*p\?\.tubePressureBar;",
        )


if __name__ == "__main__":
    unittest.main()
