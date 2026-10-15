"""Pre-TestFlight audit 2026-10-14b: ATMOSPHERE / ALTITUDE / PRESSURE.

Independent hand references for test/audit_2026_10_14b/
atmosphere_altitude_audit_test.dart and static guards on the #295 (Denetim
F1) / #307 (İrtifa card) code paths. Stdlib only.

References (never another ballistic app):
  * ICAO / U.S. Standard Atmosphere 1976 troposphere from its base
    constants: T0 = 288.15 K, L = 0.0065 K/m, g0 = 9.80665 m/s²,
    M = 0.0289644 kg/mol, R* = 8.31432 J/(mol·K).
  * Dry-air ideal gas R = R*/M; CIPM-2007 moist-air density (Picard et al.,
    Metrologia 45 (2008) 149) as a cross-check of the app's humid model.
  * GRS80 normal gravity, series form, with the free-air gradient
    3.086e-6 s⁻² (Moritz, Geodetic Reference System 1980).

Run: python3 -m unittest tools/test_denetim_2026_10_14b_atm.py
"""
from __future__ import annotations

import math
import re
import unittest
from pathlib import Path

from dart_library_source import library_text

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"
FIELD_CALC = ROOT / "lib/tools/domain/field_calc.dart"
GRAVITY = ROOT / "lib/core/gravity.dart"
ATMOSPHERE = ROOT / "lib/core/atmosphere.dart"
INFO = ROOT / "lib/features/ballistics/environment_field_info.dart"
SETTINGS = ROOT / "lib/services/settings_store.dart"
DART_TEST = ROOT / "test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart"

# --- independent physics --------------------------------------------------
T0, L, G0, M, RSTAR = 288.15, 0.0065, 9.80665, 0.0289644, 8.31432
R_DRY = RSTAR / M  # 287.053 J/(kg·K)


def isa_pressure_hpa(h_m: float, p0: float = 1013.25) -> float:
    return p0 * (1 - L * h_m / T0) ** (G0 * M / (RSTAR * L))


def dry_density(p_hpa: float, t_c: float) -> float:
    return p_hpa * 100 / (R_DRY * (t_c + 273.15))


def cipm2007_density(p_hpa: float, t_c: float, rh: float) -> float:
    """CIPM-2007 moist air density (x_CO2 = 0.0004)."""
    p = p_hpa * 100
    t = t_c + 273.15
    psv = math.exp(1.2378847e-5 * t * t - 1.9121316e-2 * t
                   + 33.93711047 - 6.3431645e3 / t)
    f = 1.00062 + 3.14e-8 * p + 5.6e-7 * t_c * t_c
    xv = rh / 100 * f * psv / p
    a0, a1, a2 = 1.58123e-6, -2.9331e-8, 1.1043e-10
    b0, b1, c0, c1 = 5.707e-6, -2.051e-8, 1.9898e-4, -2.376e-6
    d, e = 1.83e-11, -0.765e-8
    z = (1 - p / t * (a0 + a1 * t_c + a2 * t_c * t_c + (b0 + b1 * t_c) * xv
                      + (c0 + c1 * t_c) * xv * xv)
         + p * p / (t * t) * (d + e * xv * xv))
    ma = 28.96546e-3
    mv = 18.01528e-3
    r = 8.314472
    return p * ma / (z * r * t) * (1 - xv * (1 - mv / ma))


def grs80_gravity(lat_deg: float, h_m: float) -> float:
    s = math.sin(math.radians(lat_deg))
    s2 = math.sin(math.radians(2 * lat_deg))
    g0 = 9.780327 * (1 + 0.0053024 * s * s - 0.0000058 * s2 * s2)
    return g0 - 3.086e-6 * h_m


# --- the app's formulas, constants read from lib/ --------------------------
def _num(pattern: str, text: str) -> float:
    m = re.search(pattern, text)
    assert m, pattern
    return float(m.group(1))


def app_station_pressure(h_m: float) -> float:
    src = FIELD_CALC.read_text(encoding="utf-8")
    k = _num(r"1 - ([\d.e-]+) \* altitudeM, ([\d.]+)\)", src)
    ex = _num(r"1 - [\d.e-]+ \* altitudeM, ([\d.]+)\)", src)
    return 1013.25 * (1 - k * h_m) ** ex


def app_density(p_hpa: float, t_c: float, rh: float) -> float:
    src = ATMOSPHERE.read_text(encoding="utf-8")
    rd = _num(r"_dryAirGasConstant = ([\d.]+)", src)
    rv = _num(r"_waterVaporGasConstant = ([\d.]+)", src)
    es = 6.112 * math.exp(17.62 * t_c / (243.12 + t_c))
    pv = es * 100 * rh / 100
    t = t_c + 273.15
    return (p_hpa * 100 - pv) / (rd * t) + pv / (rv * t)


def app_gravity(lat_deg: float, h_m: float) -> float:
    src = GRAVITY.read_text(encoding="utf-8")
    ge = _num(r"_ge = ([\d.]+)", src)
    k = _num(r"_k = ([\d.]+)", src)
    e2 = _num(r"_e2 = ([\d.]+)", src)
    s2 = math.sin(math.radians(lat_deg)) ** 2
    g0 = ge * (1 + k * s2) / math.sqrt(1 - e2 * s2)
    return g0 - (3.087691e-6 - 4.3977e-9 * s2) * h_m + 7.2125e-13 * h_m ** 2


def _dart_const(name: str) -> float:
    src = DART_TEST.read_text(encoding="utf-8")
    return _num(rf"const {name} = ([\d.]+);", src)


def _method(src: str, signature: str) -> str:
    """Body of a Dart method from its signature to the matching brace."""
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


class IsaReference(unittest.TestCase):
    def test_icao_table_points(self):
        # ICAO Doc 7488: 1500 m 845.56 hPa, 1000 m 898.76 hPa, -400 m 1062.2.
        self.assertAlmostEqual(isa_pressure_hpa(1500), 845.56, delta=0.02)
        self.assertAlmostEqual(isa_pressure_hpa(1000), 898.76, delta=0.02)
        self.assertAlmostEqual(isa_pressure_hpa(-400), 1062.23, delta=0.02)

    def test_app_formula_matches_isa(self):
        for h in (-400, 0, 300, 900, 1500, 3000, 5000):
            self.assertAlmostEqual(app_station_pressure(h),
                                   isa_pressure_hpa(h), delta=0.01, msg=h)

    def test_beyond_the_troposphere_formula_is_not_a_number(self):
        # The app relies on NaN (pow of a negative base) above ~44.3 km and
        # rejects it with `!pres.isFinite`; Python raises/complexes instead.
        self.assertLess(1 - 2.25577e-5 * 45000, 0)
        src = library_text(SCREEN)
        self.assertIn("!pres.isFinite", src)


class DensityReference(unittest.TestCase):
    def test_dart_test_constants_are_the_independent_values(self):
        cases = {
            "_rho0": dry_density(isa_pressure_hpa(0), 15),
            "_rho1500": dry_density(isa_pressure_hpa(1500), 15),
            "_rho300": dry_density(isa_pressure_hpa(300), 15),
            "_rho900hPa": dry_density(900, 15),
            "_rho998hPa": dry_density(998.4, 15),
        }
        for name, ref in cases.items():
            self.assertAlmostEqual(_dart_const(name), ref, delta=6e-5,
                                   msg=name)

    def test_app_dry_density_matches_ideal_gas(self):
        for p in (845.56, 900, 1013.25, 1062.2):
            self.assertAlmostEqual(app_density(p, 15, 0), dry_density(p, 15),
                                   delta=2e-5)

    def test_app_moist_density_within_cipm2007(self):
        # Humid states the app shows on Hedef; CIPM-2007 includes the
        # compressibility factor, so ~0.1 % agreement is the expectation.
        for p, t, rh in ((1013.25, 15, 50), (845.56, 25, 60),
                         (950, 35, 80), (1000, -5, 90)):
            ref = cipm2007_density(p, t, rh)
            self.assertLess(abs(app_density(p, t, rh) - ref) / ref, 2e-3,
                            msg=(p, t, rh))

    def test_restart_default_differs_clearly_from_1500_m(self):
        # ATM-1: what the first automatic solve shows (empty boxes = 15 °C,
        # 50 %, 1013.25 hPa) against the restored 1500 m state.
        stale = app_density(1013.25, 15, 50)
        self.assertAlmostEqual(stale, 1.2211, delta=1e-4)
        self.assertGreater(stale - dry_density(isa_pressure_hpa(1500), 15),
                           0.19)


class GravityReference(unittest.TestCase):
    def test_app_gravity_matches_grs80(self):
        for lat in (36, 39.9, 42):
            for h in (0, 300, 900, 1500, 3000):
                self.assertAlmostEqual(app_gravity(lat, h),
                                       grs80_gravity(lat, h), delta=2e-5,
                                       msg=(lat, h))

    def test_dart_test_constants(self):
        for name, h in (("_g1500", 1500), ("_g300", 300), ("_g900", 900)):
            self.assertAlmostEqual(_dart_const(name), grs80_gravity(39.9, h),
                                   delta=2e-5, msg=name)

    def test_cases_are_distinguishable_at_four_decimals(self):
        vals = [round(app_gravity(39.9, h), 4) for h in (1500, 300, 900)]
        self.assertEqual(len(set(vals)), 3)


class CodePathGuards(unittest.TestCase):
    """Static guards: the effective İrtifa reaches every former user."""

    @classmethod
    def setUpClass(cls):
        cls.src = library_text(SCREEN)

    def test_effective_altitude_is_phone_else_map(self):
        self.assertRegex(
            self.src,
            r"TextEditingController get _altitudeCtl =>\s*"
            r"altitude\.text\.trim\(\)\.isNotEmpty \? altitude : mapAltitude;")

    def test_solve_uses_it_for_f1(self):
        body = _method(self.src, "void solve() {")
        self.assertIn("final altitudeBox = _altitudeCtl;", body)
        self.assertRegex(
            body,
            r"pressureFromAltitude =\s*pressure\.text\.trim\(\)\.isEmpty "
            r"&& altitudeBox\.text\.trim\(\)\.isNotEmpty;")
        self.assertIn("FieldCalc.stationPressureHpa(1013.25, alt)", body)
        self.assertIn("_pressureEstimated = pressureFromAltitude;", body)

    def test_pressure_warning_and_gravity_use_it(self):
        warn = _method(self.src, "String? get _pressureWarning {")
        self.assertIn("final alt = _altitudeCtl;", warn)
        grav = _method(self.src, "Future<void> _gravityFromLocation() async {")
        self.assertIn("_parsed(_altitudeCtl)", grav)

    def test_no_other_reader_of_the_raw_phone_box_in_the_calculation(self):
        # Only persistence/unit conversion/the card itself may read
        # `altitude` directly; the solver input comes from _altitudeCtl.
        body = _method(self.src, "void solve() {")
        self.assertNotRegex(body, r"number\(altitude\)|_parsed\(altitude\)")

    def test_resets_touch_only_their_own_card(self):
        p = _method(self.src, "void _resetPressure() {")
        self.assertNotIn("altitude", p.replace("İrtifa", ""))
        a = _method(self.src, "void _resetAltitude() {")
        self.assertIn("altitude.text = '';", a)
        self.assertIn("mapAltitude.text = '';", a)
        self.assertNotIn("pressure.text", a)

    def test_basinc_al_writes_no_altitude(self):
        body = _method(self.src, "Future<void> _readPhonePressure() async {")
        self.assertNotIn("altitude.text", body)

    def test_tube_pressure_flag_never_feeds_the_air_pressure(self):
        body = _method(self.src, "void solve() {")
        m = re.search(r"final pres = (.*?);", body, re.S)
        self.assertIsNotNone(m)
        self.assertNotIn("tube", m.group(1).lower())
        self.assertNotIn("_showProTubePressure", m.group(1))

    def test_both_boxes_persist_and_convert(self):
        si = _method(self.src, "Map<String, double> _weatherSi() {")
        self.assertIn("'mapAltitude'", si)
        self.assertIn("'altitude'", si)
        conv = _method(self.src, "void _convertControllersToImperial() {")
        self.assertIn("maybe(mapAltitude)", conv)

    def test_imperial_path_is_unreachable(self):
        # V380: metric only; the ft branches of both boxes cannot run.
        src = SETTINGS.read_text(encoding="utf-8")
        self.assertIn("bool loadMetric() => true;", src)

    def test_atm1_saved_weather_is_solved_after_it_is_restored(self):
        # ATM-1 (fixed in #312, decorator removed per CLAUDE.md): a solve
        # follows the restore of the saved Hava Durumu in _loadShotSettings.
        body = _method(self.src, "Future<void> _loadShotSettings() async {")
        self.assertRegex(body, r"_quietSolve\(\)|solve\(\)")


class InfoTexts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.info = INFO.read_text(encoding="utf-8")
        cls.screen = library_text(SCREEN)

    def _joined(self):
        return re.sub(r"'\s*\n\s*'", "", self.info)

    def test_atm2_f1_rule_is_in_the_irtifa_and_basinc_info(self):
        # ATM-2 fixed: the İrtifa card ⓘ and the Basınç Ölçer ⓘ state the F1
        # rule; the unused EnvironmentFieldInfo.altitude text is deleted.
        joined = self._joined()
        self.assertNotIn("static const altitude =", self.info)
        self.assertIn(
            "İrtifa yalnız İstasyon basıncı boşken basınç tahmini için "
            "kullanılır.",
            _const(joined, "altitudeCard"),
        )
        self.assertIn(
            "Boşsa basınç İrtifa kartından tahmin edilir.",
            _const(joined, "barometerCard"),
        )
        self.assertNotIn("EnvironmentFieldInfo.altitude,", self.screen)
        self.assertNotIn("EnvironmentFieldInfo.altitude)", self.screen)

    def test_atm3_pressure_text_names_no_old_button(self):
        # ATM-3 fixed: the Hava page button is "Basınç al" since #307 and
        # the Doğrulama page has no button; the old name is gone.
        self.assertIn("'Basınç al'", self.screen)
        self.assertNotIn("'Basıncı telefondan al'", self.screen)
        pressure = _const(self._joined(), "pressure")
        self.assertNotIn("Basıncı telefondan al", pressure)
        self.assertNotIn("düğme", pressure)
        self.assertIn("Araçlar > Hesaplayıcılar", pressure)


def _const(joined, name):
    m = re.search(r"static const " + name + r" =\s*'(.*?)';", joined, re.S)
    assert m, name
    return m.group(1)

if __name__ == "__main__":
    unittest.main()
