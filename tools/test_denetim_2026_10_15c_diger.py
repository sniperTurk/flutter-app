"""Audit 2026-10-15c ("diğer"): the non-design PRs merged after 4c51b77.

Offline (git + working tree only, no network, no Flutter):

* SEC: no secret in tracked files or in the commits 4c51b77..HEAD; no
  signing / service-config file tracked; the maps-check workflow (#334)
  takes the key only from secrets and sends the app's own request shape
  (RUZ-3 closed by its run, docs/reports/maps_billing_check.md).
* FLG: the complete compile-time environment-read inventory of lib/ with
  defaults (16 reads at 4c51b77; WIND_GUIDE_LINK gone with #357; the second
  PRO_TUBE_PRESSURE read is #338's truing switch).
* Hand calculations behind test/audit_2026_10_15c/diger_audit_test.dart
  (tools/denetim_2026_10_15c_diger.py).
* Findings: KUL-10 (BC / drag truing ignores the PCP table velocity Hedef
  uses) and RUZ-4 (hidden WIND_OBSERVATION writes Rüzgâr hızı without
  emptying a "Düzeltme al" value). Their expected-behaviour tests are
  skipped while open.

Run: python3 -m unittest tools/test_denetim_2026_10_15c_diger.py
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import unittest
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELF = Path(__file__).resolve()
sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15c_diger as d  # noqa: E402

BASE = '4c51b77'

# Assembled from pieces so this file never matches itself.
_SECRET_PATTERNS = {
    'Google API key': re.compile('AI' + r'za[0-9A-Za-z_\-]{35}'),
    'Anthropic key': re.compile('sk-' + r'ant-[A-Za-z0-9_\-]{10,}'),
    'OpenAI key': re.compile(r'\bsk-' + r'(?:proj-)?[A-Za-z0-9]{20,}'),
    'GitHub token': re.compile('gh' + r'[pousr]_[A-Za-z0-9]{30,}'),
    'GitHub fine-grained token': re.compile('github' + r'_pat_[A-Za-z0-9_]{20,}'),
    'PEM private key': re.compile('-----BEGIN ' + r'[A-Z ]*PRIVATE KEY-----'),
    'AWS access key': re.compile('AK' + r'IA[0-9A-Z]{16}'),
}
_FORBIDDEN_SUFFIXES = (
    '.p8', '.p12', '.pfx', '.mobileprovision', '.provisionprofile',
    '.pem', '.key', '.jks', '.keystore', '.cer', '.certSigningRequest',
)
_FORBIDDEN_NAMES = ('GoogleService-Info.plist', 'google-services.json', '.env')


def _git(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True)


def _have_git() -> bool:
    return shutil.which('git') is not None and _git('rev-parse', '--git-dir').returncode == 0


def _have_base() -> bool:
    return _have_git() and _git('cat-file', '-e', BASE + '^{commit}').returncode == 0


def _read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def _lib_dart() -> dict[str, str]:
    return {p.relative_to(ROOT).as_posix(): p.read_text(encoding='utf-8')
            for p in sorted((ROOT / 'lib').rglob('*.dart'))}


# ------------------------------------------------------------------- SEC
@unittest.skipUnless(_have_git(), 'git not available')
class SecNoSecret(unittest.TestCase):
    def test_tracked_text_files_hold_no_secret(self):
        out = _git('ls-files', '-z').stdout.decode('utf-8')
        hits = []
        for rel in filter(None, out.split('\0')):
            p = ROOT / rel
            if p.resolve() == SELF or not p.is_file():
                continue
            data = p.read_bytes()
            if b'\0' in data[:8192]:
                continue
            text = data.decode('utf-8', errors='replace')
            for name, pat in _SECRET_PATTERNS.items():
                if pat.search(text):
                    hits.append(f'{rel}: {name}')
        self.assertEqual(hits, [])

    @unittest.skipUnless(_have_base(), f'{BASE} not in this (shallow) clone')
    def test_commits_since_base_add_no_secret(self):
        log = _git('log', '-p', '--no-color', f'{BASE}..HEAD').stdout.decode(
            'utf-8', errors='replace')
        self.assertTrue(log)
        hits = []
        for line in log.splitlines():
            if not line.startswith('+') or line.startswith('+++'):
                continue
            # This audit's own pattern table is not a secret.
            if "re.compile(" in line:
                continue
            for name, pat in _SECRET_PATTERNS.items():
                if pat.search(line):
                    hits.append(f'{name}: {line[:60]}')
        self.assertEqual(hits, [])

    @unittest.skipUnless(_have_base(), f'{BASE} not in this (shallow) clone')
    def test_commits_since_base_add_no_signing_file(self):
        names = _git('log', '--name-only', '--format=', f'{BASE}..HEAD').stdout.decode()
        bad = sorted({n for n in names.split('\n') if n and (
            n.endswith(_FORBIDDEN_SUFFIXES) or Path(n).name in _FORBIDDEN_NAMES)})
        self.assertEqual(bad, [])

    def test_no_signing_or_service_config_tracked(self):
        out = _git('ls-files', '-z').stdout.decode('utf-8')
        bad = [p for p in filter(None, out.split('\0'))
               if p.endswith(_FORBIDDEN_SUFFIXES) or Path(p).name in _FORBIDDEN_NAMES]
        self.assertEqual(bad, [])


class MapsCheckWorkflow(unittest.TestCase):
    """#334 / #340: manual billing check of the Elevation request."""

    WF = '.github/workflows/maps-check.yml'
    ADAPTER = 'lib/tools/adapters/google_elevation_provider.dart'

    def test_manual_only_read_only(self):
        src = _read(self.WF)
        self.assertRegex(src, r'(?m)^on:\s*\n\s+workflow_dispatch:\s*$')
        self.assertIn('contents: read', src)
        self.assertNotIn('pull_request', src)

    def test_key_from_secrets_and_never_printed(self):
        src = _read(self.WF)
        assigns = re.findall(r'(?m)^\s*GOOGLE_MAPS_IOS_API_KEY:\s*(.+)$', src)
        self.assertEqual(assigns, ['${{ secrets.GOOGLE_MAPS_IOS_API_KEY }}'])
        for line in src.splitlines():
            s = line.strip()
            if s.startswith('echo') or s.startswith('printf'):
                self.assertNotIn('GOOGLE_MAPS_IOS_API_KEY}', s.replace(':-}', ''))
        self.assertIn('set +x', src)

    def test_same_request_shape_as_the_app(self):
        # RUZ-3 (suspected iOS-key rejection) was answered by this request:
        # same host/path and the app's X-Ios-Bundle-Identifier.
        wf, ad = _read(self.WF), _read(self.ADAPTER)
        bundle = re.search(r"static const bundleId = '([^']+)';", ad).group(1)
        self.assertIn(f"X-Ios-Bundle-Identifier: {bundle}", wf)
        self.assertIn('maps.googleapis.com/maps/api/elevation/json', wf)
        self.assertIn("'maps.googleapis.com', '/maps/api/elevation/json'", ad)

    def test_report_records_status_ok(self):
        rep = _read('docs/reports/maps_billing_check.md')
        self.assertIn('status: OK', rep)
        self.assertIn('actions/runs/38785522797', rep)
        self.assertNotRegex(rep, 'AI' + r'za[0-9A-Za-z_\-]{20,}')


# ------------------------------------------------------------------- FLG
_ENV_READ = re.compile(
    r'(bool|String|int)\.fromEnvironment\(\s*[\'"]([A-Z0-9_]+)[\'"]\s*'
    r'(?:,\s*defaultValue\s*:\s*([^,)]+?)\s*)?,?\s*\)', re.S)

# Inventory on main e7b29bf: name -> (type, number of reads). Defaults: no
# defaultValue anywhere (bool false, String '').
EXPECTED_ENV = {
    'PROFILE_BACKUP_BUTTONS': ('bool', 1),
    'SCOPE_LISTEDE_YOK': ('bool', 1),
    'RIFLE_LISTEDE_YOK': ('bool', 1),
    'AMMO_BC_BANDS_TYPED': ('bool', 1),
    'AMMO_LISTEDE_YOK': ('bool', 1),
    'PCP_AMMO_BRAND': ('bool', 1),
    'PROFILE_AMMO_LENGTH': ('bool', 1),
    'WELCOME_RESTORE': ('bool', 1),
    'SHOT_SAMPLE_PREVIEW': ('bool', 1),
    'SHOT_TABLE_SWITCH': ('bool', 1),
    'GOOGLE_MAPS_ENABLED': ('bool', 1),
    'WIND_OBSERVATION': ('bool', 1),
    # ballistics_screen.dart (Hedef) and, since #338, truing_screen.dart.
    'PRO_TUBE_PRESSURE': ('bool', 2),
    'METNO_CONTACT': ('String', 1),
    'GOOGLE_MAPS_IOS_API_KEY': ('String', 1),
}


class FlagInventory(unittest.TestCase):
    def _reads(self):
        reads = []
        for path, src in _lib_dart().items():
            total = src.count('.fromEnvironment(')
            found = list(_ENV_READ.finditer(src))
            self.assertEqual(len(found), total, f'{path}: unparsed fromEnvironment')
            for m in found:
                reads.append((path, m.group(1), m.group(2), m.group(3)))
        return reads

    def test_inventory_is_exactly_the_expected_one(self):
        reads = self._reads()
        self.assertEqual(len(reads), 16)
        got = Counter((name, typ) for _, typ, name, _ in reads)
        want = Counter({(n, t): c for n, (t, c) in EXPECTED_ENV.items()})
        self.assertEqual(got, want)

    def test_no_default_value_anywhere(self):
        for path, typ, name, default in self._reads():
            with self.subTest(path=path, flag=name):
                self.assertIsNone(default)

    def test_wind_guide_link_is_gone(self):
        for path, src in _lib_dart().items():
            with self.subTest(path=path):
                self.assertNotIn('WIND_GUIDE_LINK', src)
                self.assertNotIn('WindGuideLink', src)

    def test_truing_switch_mirrors_hedef(self):
        truing = _read('lib/features/tools/truing_screen.dart')
        self.assertRegex(truing, r"_proTubePressure = bool\.fromEnvironment\(\s*'PRO_TUBE_PRESSURE',\s*\)")
        self.assertIn('if (_proTubePressure || p == null || res == null) return false;', truing)

    def test_release_builds_turn_on_no_ui_flag(self):
        allowed = {'METNO_CONTACT', 'GOOGLE_MAPS_ENABLED', 'GOOGLE_MAPS_IOS_API_KEY'}
        for wf in sorted((ROOT / '.github' / 'workflows').glob('*.yml')):
            names = set(re.findall(r'--dart-define=([A-Z0-9_]+)=', wf.read_text(encoding='utf-8')))
            with self.subTest(workflow=wf.name):
                self.assertLessEqual(names, allowed)

    def test_garmin_bridge_not_in_release_workflows(self):
        # #228: the Garmin iOS bridge is opt-in (garmin-sim.yml only).
        for name in ('ios-testflight.yml', 'ios-ci.yml'):
            src = _read(f'.github/workflows/{name}')
            with self.subTest(workflow=name):
                self.assertNotIn('configure_ios_garmin_bridge', src)


# -------------------------------------------------------------- RUZ (#335)
class RuzWindMax(unittest.TestCase):
    def test_button_value(self):
        self.assertEqual(d.dart_fixed1(5.0 * d.GUST), '7.5')
        self.assertEqual(d.dart_fixed1(4.0 * d.GUST), '6.0')

    def test_numeric_compare(self):
        self.assertFalse(d.wind_text_changed('5', '5.0'))
        self.assertFalse(d.wind_text_changed('5.25', '5.3'))
        self.assertFalse(d.wind_text_changed('5,0', '5.0'))
        self.assertTrue(d.wind_text_changed('5.0', '0.0'))
        self.assertTrue(d.wind_text_changed('5.0', '8.0'))
        self.assertTrue(d.wind_text_changed('5.0', ''))
        self.assertFalse(d.wind_text_changed('', ''))

    def test_every_visible_wind_writer_empties_the_button_value(self):
        src = _read('lib/features/ballistics/ballistics_screen.dart')
        view = _read('lib/features/ballistics/hava_durumu_view.dart')
        # weather fill, Sıfırla, typed box
        self.assertIn('_windTextChanged(windBefore, wind.text)', src)
        self.assertIn('if (windBefore.isNotEmpty) _windMaxFollowsWind();', src)
        self.assertRegex(view, r'_userEdited\.add\(wind\);\s*_windMaxFollowsWind\(\);')

    def test_ruz_tests_are_unskipped(self):
        dart = _read('test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart')
        self.assertNotRegex(dart, r'skip:\s*(true|\')')
        py = _read('tools/test_denetim_2026_10_14b_ruz.py')
        self.assertNotIn('unittest.skip(', py)
        self.assertNotIn('expectedFailure', py)

    @unittest.skip('RUZ-4 (düşük, gizli WIND_OBSERVATION): Rüzgâr gözlemi '
                   'Rüzgâr hızını yazar, "Düzeltme al" değerini boşaltmaz')
    def test_ruz4_wind_observation_empties_button_value(self):
        src = _read('lib/features/ballistics/ballistics_screen.dart')
        start = src.index('void _pickWindObservation(')
        body = src[start:src.index('\n  }\n', start)]
        self.assertIn('_windMaxFollowsWind', body)


# -------------------------------------------------------- KUL-10 (#338)
class Kul10TruingPcpTable(unittest.TestCase):
    def test_hand_calc(self):
        observed, bc, rows = d.kul10_example()
        self.assertAlmostEqual(observed, 6.8947, places=3)
        # BC solved with the profile 270 m/s: about 18.6 % low.
        self.assertAlmostEqual(bc, 0.02523, places=4)
        r100 = rows[-1]
        self.assertEqual(r100[0], 100.0)
        # Hedef (255 m/s) with that BC misses its own truing range.
        self.assertGreater(r100[2] - r100[1], 0.8)
        # A 2 % velocity gap (260 vs 255) already gives 0.28 mrad at 100 m,
        # with a BC change under the page's 10 % warning.
        obs = d.correction(255.0, 0.031, 100.0)
        bc260 = d.trued_bc(obs, 260.0, 100.0)
        self.assertLess(abs(bc260 / 0.031 - 1), 0.10)
        self.assertGreater(d.correction(255.0, bc260, 100.0) - obs, 0.25)

    def test_where_it_comes_from(self):
        src = _read('lib/features/tools/truing_screen.dart')
        # The truing base (velocity, BC and drag modes) always uses the
        # profile velocity; only the velocity "apply" knows the table.
        self.assertIn('muzzleVelocityMps: p.muzzleVelocityMps * f,', src)
        self.assertIn('if (p == null || _velocityFromPcpTable) return;', src)

    @unittest.skip('KUL-10 (yüksek): BC/sürüklenme doğrulaması regülatörsüz '
                   "PCP'de Hedef'in tablo hızını değil profil hızını kullanır")
    def test_kul10_bc_truing_uses_the_hedef_velocity(self):
        src = _read('lib/features/tools/truing_screen.dart')
        base = src[src.index('base = BallisticInput('):]
        base = base[:base.index(');')]
        # The real check is the Dart test (trued BC reproduces the
        # observation in Hedef); here only: not the bare profile velocity.
        self.assertNotIn('muzzleVelocityMps: p.muzzleVelocityMps * f', base)


# ------------------------------------------------------------ MUH (#345)
class MuhFactoryData(unittest.TestCase):
    LIB = 'lib/data/factory_ammo_library.dart'

    def _row(self, brand, name):
        src = _read(self.LIB)
        m = re.search(r"FactoryAmmo\('%s', '%s', [^\n]*" % (re.escape(brand), re.escape(name)), src)
        self.assertIsNotNone(m, name)
        return m.group(0)

    def test_fa007_velocity_is_the_maker_page(self):
        row = d.mapping_row('FA007')
        self.assertIn('1130', row['table'])
        self.assertTrue(row['url'].startswith('https://www.aguilaammo.com/'))
        lib = self._row('Aguila', '22 Long Rifle Standard Velocity Lead Solid Point')
        self.assertRegex(lib, r"'\.22 LR', 5\.69, 40\.0, null, null, 1130\.0,")

    def test_x651_has_no_g7_so_g7_empties_the_box(self):
        lib = self._row('Winchester', 'Super-X Power-Point 129 gr Power-Point')
        self.assertIn('0.324, BallisticModel.g1, 2820.0', lib)
        self.assertNotIn('bcG7', lib)

    def test_lapua_scenar_both_maker_values(self):
        lib = self._row('Lapua', 'Lapua 4.5 g (69 gr) Scenar')
        self.assertIn('0.341, BallisticModel.g1', lib)
        self.assertIn('bcG7: 0.171', lib)

    def test_unknown_model_loads_as_g1_only_when_non_empty(self):
        src = _read('lib/data/user_catalog.dart')
        self.assertIn("rawModel is String && rawModel.trim().isNotEmpty", src)
        self.assertIn('? BallisticModel.g1', src)


# ----------------------------------------------- powder temperature (#355)
class AmmoTemperature(unittest.TestCase):
    def test_empty_uses_air_then_icao(self):
        self.assertEqual(d.effective_temp(5.0, None), 5.0)
        self.assertEqual(d.effective_temp(5.0, 70.0), 5.0)  # outside -50..60
        self.assertAlmostEqual(d.hedef_fps(2650, 1.5, 21, 5), 2607.6, places=6)
        self.assertAlmostEqual(d.hedef_fps(2650, 1.5, 21, 5, 30), 2673.85, places=6)
        self.assertAlmostEqual(d.hedef_fps(2650, 1.5, 21), 2634.1, places=6)
        self.assertEqual(d.hedef_fps(2650, None, None, 5, 30), 2650)

    def test_app_rule_is_the_hand_rule(self):
        src = _read('lib/core/powder_temperature.dart')
        self.assertIn('final f = 1 + k / 100 * (todayTempC - t0) / 15;', src)
        self.assertIn('if (a == null || !a.isFinite || a < minTempC || a > maxTempC) return airC;', src)
        bs = _read('lib/features/ballistics/ballistics_screen.dart')
        self.assertIn('ammoC: _ammoTempC,', bs)
        self.assertIn('final rawTemperature = env(temperature, 15, 59);', bs)

    def test_box_key_unchanged_and_firearm_only(self):
        view = _read('lib/features/ballistics/hava_durumu_view.dart')
        self.assertEqual(view.count("Key('env-ammo-temp')"), 1)
        i = view.index("Key('environment-ammo-temp-header')")
        self.assertIn('if (_isFirearm) ...[', view[i - 600:i])


# ---------------------------------------------------------- İrtifa (#356)
class OneAltitudeBox(unittest.TestCase):
    def test_isa(self):
        self.assertAlmostEqual(d.isa_pressure_hpa(1500), 845.56, places=2)
        self.assertAlmostEqual(d.isa_pressure_hpa(0), 1013.25, places=9)

    def test_legacy_load_rule(self):
        self.assertEqual(d.legacy_altitude_shown({'mapAltitude': 5, 'altitude': 2}), 5)
        self.assertEqual(d.legacy_altitude_shown({'altitude': 2}), 2)
        self.assertIsNone(d.legacy_altitude_shown({'altitude': 2}, 'typed'))
        self.assertEqual(d.legacy_altitude_shown({'mapAltitude': 7, 'altitude': 2}, 'map'), 7)

    def test_code_matches_the_rule_and_keeps_old_data(self):
        src = _read('lib/features/ballistics/ballistics_screen.dart')
        self.assertIn("final fromMapKey = newFormat || si['mapAltitude'] != null;", src)
        self.assertIn("if (legacyPhone != null) 'altitude': legacyPhone,", src)
        self.assertIn("final rawAltitude = env(altitudeBox, 0, 0);", src)
        store = _read('lib/services/shot_settings_store.dart')
        for key in ("'altitude',", "'mapAltitude',"):
            self.assertIn(key, store[store.index('weatherKeys'):])


# ------------------------------------------------------- Garmin (#228/#353)
class GarminSameNumbers(unittest.TestCase):
    def test_watch_gets_the_hedef_numbers(self):
        src = _read('lib/features/ballistics/ballistics_screen.dart')
        self.assertIn('_publishWatch(requiredUp, requiredRight, click);', src)
        self.assertIn('up: ScopeDialMath.clicksFor(up, click),', src)
        res = _read('lib/features/ballistics/scope_results.dart')
        self.assertIn('ScopeDialMath.clicksFor(requiredUp, clickValue)', res)

    def test_ios_bridge_only_rewrites_ok(self):
        m = _read('garmin/ios_runner/SniperTurkGarminBridge.m')
        writes = re.findall(r'copy\[@"(\w+)"\]\s*=', m)
        self.assertEqual(writes, ['ok'])


if __name__ == '__main__':
    unittest.main()
