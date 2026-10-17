"""Pre-TestFlight audit 2026-10-14b, area RUZ (Hava sayfası / rüzgâr /
Google Elevation, PR #307 e3c2e26).

Complements tools/test_elevation_key_wiring.py (which scans six folders of
the working tree for an `AIza…` key and checks the TestFlight dart-define):

* every TRACKED file (whole tree, not only six folders) and every reachable
  commit in git history are free of a Google API key;
* the key name appears in workflows only as `${{ secrets.… }}` and is never
  echoed/printed; ios-ci.yml (the PR gate) does not receive it;
* the Dart key constant is read only by the Elevation adapter, and the
  adapter neither logs nor persists anything;
* hand calculations for the En çok rüzgâr = Rüzgâr hızı × 1.5 box (the
  strings Dart's toStringAsFixed(1) produces) and the WEZ wind-uncertainty
  sigma, used by test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart.

stdlib only: python3 -m unittest tools/test_denetim_2026_10_14b_ruz.py
"""

import re
import shutil
import subprocess
import unittest
from decimal import ROUND_HALF_EVEN, Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KEY_RE = re.compile(r"AIza[0-9A-Za-z_\-]{30,}")
KEY_NAME = "GOOGLE_MAPS_IOS_API_KEY"


def _git(*args):
    return subprocess.run(
        ["git", "-C", str(ROOT), *args],
        capture_output=True,
        text=True,
        check=False,
    )


def _have_git():
    return shutil.which("git") is not None and (ROOT / ".git").exists()


class KeyNotCommittedTest(unittest.TestCase):
    @unittest.skipUnless(_have_git(), "git not available")
    def test_no_key_in_any_tracked_file(self):
        files = _git("ls-files", "-z").stdout.split("\0")
        hits = []
        for rel in files:
            if not rel:
                continue
            path = ROOT / rel
            if not path.is_file():
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            if KEY_RE.search(text):
                hits.append(rel)
        self.assertEqual([], hits)

    @unittest.skipUnless(_have_git(), "git not available")
    def test_no_key_in_reachable_git_history(self):
        # Note: CI checkouts and this sandbox may be shallow; the scan covers
        # every commit that is present locally.
        revs = _git("rev-list", "--all").stdout.split()
        self.assertTrue(revs, "no commits found")
        hits = []
        for start in range(0, len(revs), 50):
            out = _git(
                "grep", "-I", "-l", "-E", r"AIza[0-9A-Za-z_-]{30,}", *revs[start : start + 50]
            )
            # Exit 1 = no match; anything printed is a hit "rev:path".
            hits += [line for line in out.stdout.splitlines() if line.strip()]
        self.assertEqual([], hits[:10])


class KeyOnlyFromSecretsTest(unittest.TestCase):
    def _workflows(self):
        base = ROOT / ".github" / "workflows"
        return sorted(base.glob("*.yml")) + sorted(base.glob("*.yaml"))

    def test_key_name_is_only_assigned_from_secrets(self):
        for wf in self._workflows():
            for no, line in enumerate(wf.read_text(encoding="utf-8").splitlines(), 1):
                m = re.match(rf"\s*{KEY_NAME}\s*:\s*(.+)$", line)
                if m:
                    self.assertEqual(
                        "${{ secrets.%s }}" % KEY_NAME,
                        m.group(1).strip(),
                        f"{wf.name}:{no}",
                    )

    def test_key_is_never_echoed_or_traced(self):
        for wf in self._workflows():
            text = wf.read_text(encoding="utf-8")
            if KEY_NAME not in text:
                continue
            for no, line in enumerate(text.splitlines(), 1):
                low = line.strip()
                if re.match(r"(echo|printf|cat)\b", low) and KEY_NAME in low:
                    self.fail(f"{wf.name}:{no} prints the key: {line.strip()}")
                self.assertNotRegex(low, r"^set\s+-[a-z]*x", f"{wf.name}:{no} set -x")

    def test_pr_gate_does_not_receive_the_key(self):
        ci = ROOT / ".github/workflows/ios-ci.yml"
        if ci.exists():
            self.assertNotIn(KEY_NAME, ci.read_text(encoding="utf-8"))

    def test_testflight_maps_flag_follows_the_secret(self):
        tf = (ROOT / ".github/workflows/ios-testflight.yml").read_text(encoding="utf-8")
        self.assertIn('MAPS=false; [[ -n "${GOOGLE_MAPS_IOS_API_KEY:-}" ]] && MAPS=true', tf)


class DartKeyHandlingTest(unittest.TestCase):
    ADAPTER = "lib/tools/adapters/google_elevation_provider.dart"
    # Hava verisi from Google (owner, 2026-10-17): the second key reader.
    WEATHER_ADAPTER = "lib/tools/adapters/google_weather_provider.dart"

    def test_only_the_adapter_reads_the_key(self):
        users = []
        for path in (ROOT / "lib").rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            if KEY_NAME in text or "keyFromBuild" in text:
                users.append(path.relative_to(ROOT).as_posix())
        self.assertEqual(sorted([self.ADAPTER, self.WEATHER_ADAPTER]), sorted(users))

    def test_adapter_never_logs_or_stores(self):
        src = (ROOT / self.ADAPTER).read_text(encoding="utf-8")
        for banned in (
            "print(",
            "debugPrint(",
            "log(",
            "SharedPreferences",
            "developer",
            "toString()",
        ):
            self.assertNotIn(banned, src, banned)
        # Failures carry only an enum reason, never the URL (which holds
        # the key) or an exception message.
        args = re.findall(r"ElevationUnavailable\(([^)]*)\)", src)
        self.assertTrue(args)
        for a in args:
            self.assertRegex(a.strip(), r"^ElevationFailure\.\w+$", a)

    def test_no_request_without_a_key_comes_first(self):
        src = (ROOT / self.ADAPTER).read_text(encoding="utf-8")
        body = src[src.index("Future<ElevationResult> elevation(") :]
        self.assertLess(body.index("ElevationFailure.noKey"), body.index("await _once("))


class GoogleWeatherKeyHandlingTest(unittest.TestCase):
    """The Google Weather adapter (2026-10-17) holds the same key."""

    ADAPTER = DartKeyHandlingTest.WEATHER_ADAPTER

    def _src(self):
        return (ROOT / self.ADAPTER).read_text(encoding="utf-8")

    def test_adapter_never_logs_or_stores(self):
        src = self._src()
        for banned in (
            "print(",
            "debugPrint(",
            "log(",
            "SharedPreferences",
            "developer",
            "toString()",
        ):
            self.assertNotIn(banned, src, banned)

    def test_failures_never_carry_the_url_or_an_exception_text(self):
        src = self._src()
        # Every WeatherFailure message is a literal; the only interpolation
        # allowed is the HTTP status code.
        for m in re.finditer(r"WeatherFailure\(\s*WeatherFailureKind\.\w+,\s*'([^']*)'", src):
            interp = re.findall(r"\$\{?(\w+)", m.group(1))
            self.assertTrue(all(v == "code" for v in interp), m.group(0))
        self.assertNotRegex(src, r"on \w+ catch \(e")

    def test_no_request_without_a_key_comes_first(self):
        src = self._src()
        body = src[src.index("Future<WeatherObservation> fetch(") :]
        self.assertLess(
            body.index("WeatherFailureKind.notConfigured"), body.index(".get(")
        )

    def test_bundle_header_and_rounded_location(self):
        src = self._src()
        self.assertIn("'X-Ios-Bundle-Identifier': bundleId", src)
        self.assertIn("static const bundleId = 'com.sniperturk.sniperTurk';", src)
        self.assertEqual(2, src.count("WeatherPolicy.roundCoordinate("))


def dart_fixed1(x: float) -> str:
    """Dart's toStringAsFixed(1): correctly rounded from the exact binary
    value of the double (ties cannot occur for doubles at 1 decimal except
    exact binary halves, which round half-even in both)."""
    return str(Decimal(x).quantize(Decimal("0.1"), rounding=ROUND_HALF_EVEN))


class WindMaxHandCalcTest(unittest.TestCase):
    GUST = 1.5

    def test_auto_value_strings(self):
        # Values the Dart audit test asserts (box text after Düzeltme al).
        self.assertEqual("7.5", dart_fixed1(5.0 * self.GUST))
        self.assertEqual("12.0", dart_fixed1(8.0 * self.GUST))
        self.assertEqual("6.0", dart_fixed1(4.0 * self.GUST))
        self.assertEqual("3.0", dart_fixed1(2.0 * self.GUST))

    def test_binary_rounding_artifact_is_within_display_precision(self):
        # 3.3 × 1.5 = 4.95 exactly on paper, 4.949999… as a double: Dart
        # shows "4.9". Below the box's 0.1 m/s precision (observation only).
        self.assertEqual("4.9", dart_fixed1(3.3 * self.GUST))
        self.assertAlmostEqual(3.3 * self.GUST, 4.95, places=12)

    def test_calm_wind_gives_zero_bracket(self):
        # Owner rule "En çok rüzgâr = Rüzgâr hızı × 1,5": a calm fetch
        # (0 m/s) gives 0, i.e. no bracket (the pre-#291 automatic fill
        # emptied the box for w <= 0). RUZ-1 (fixed 2026-10-15): a changed
        # wind empties a button-filled box.
        self.assertEqual(0.0, 0.0 * self.GUST)

    def test_wez_wind_sigma(self):
        # sigmaX = (windMax - wind) / 2 / (m/s per mil): ±(max−wind) read as
        # a 2σ band. Wind 4, max 6, 2.5 m/s per mil → 0.4 mil.
        self.assertAlmostEqual((6.0 - 4.0) / 2 / 2.5, 0.4, places=12)


class ElevationBoundsTest(unittest.TestCase):
    def test_parse_bounds_cover_real_terrain(self):
        src = (ROOT / DartKeyHandlingTest.ADAPTER).read_text(encoding="utf-8")
        m = re.search(r"m < (-?\d+) \|\| m > (\d+)", src)
        self.assertIsNotNone(m)
        low, high = int(m.group(1)), int(m.group(2))
        # Dead Sea shore about -430 m; Everest 8849 m (independent geography).
        self.assertLess(low, -430)
        self.assertGreater(high, 8849)


if __name__ == "__main__":
    unittest.main()
