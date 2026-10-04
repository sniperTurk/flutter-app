"""Regression contracts for the M1 review fixes (2026-10-03).

Each test locks one defect found in the merged M1 package so it cannot
silently come back. See M1_REVIEW_FIXES.md for the reasoning.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'lib'
TOOLS_UI = LIB / 'features/tools'


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class PackagingTests(unittest.TestCase):
    def test_no_packaged_xcarchive_directory(self):
        # A real (non-symlink) .xcarchive directory under build/ is a shipped
        # build artefact; it also breaks the V323 symlink-safety test.
        build = ROOT / 'build'
        offenders = []
        if build.exists():
            for p in build.rglob('*.xcarchive'):
                if p.is_dir() and not p.is_symlink():
                    offenders.append(p.relative_to(ROOT).as_posix())
        self.assertEqual([], offenders)


class LevelLayoutTests(unittest.TestCase):
    def test_stretch_row_is_bounded_by_intrinsic_height(self):
        # M2 design: the level page is the Menzil circle + X/Y tube cluster.
        # It is sized by a LayoutBuilder with explicit tube/circle sizes, so
        # there is no unbounded stretch row; a stretch row, if one is ever
        # reintroduced, must still be wrapped in IntrinsicHeight.
        text = read('lib/features/tools/level_screen.dart')
        self.assertIn('LayoutBuilder(', text)
        for key in ('level-tube-x', 'level-tube-y', 'level-circle'):
            self.assertIn(f"Key('{key}')", text)
        if 'crossAxisAlignment: CrossAxisAlignment.stretch' in text:
            stretch = text.index('crossAxisAlignment: CrossAxisAlignment.stretch')
            self.assertIn('IntrinsicHeight(', text[max(0, stretch - 400):stretch])


class CompassTests(unittest.TestCase):
    def test_invalid_ios_heading_is_never_shown_as_a_bearing(self):
        adapter = read('lib/tools/adapters/flutter_compass_heading_provider.dart')
        self.assertIn('if (heading < 0) return const HeadingUnavailable(HeadingUnavailableReason.noReference);', adapter)
        self.assertIn('if (heading == null) return const HeadingUnavailable(HeadingUnavailableReason.noData);', adapter)
        port = read('lib/tools/ports/heading_provider.dart')
        self.assertIn('noReference,', port)

    def test_last_bearing_survives_a_still_phone(self):
        controller = read('lib/tools/state/compass_controller.dart')
        self.assertIn('if (_hadReading) return;', controller)

    def test_compass_is_portrait_locked_while_open(self):
        screen = read('lib/features/tools/compass_screen.dart')
        self.assertIn('DeviceOrientation.portraitUp', screen)
        self.assertIn('SystemChrome.setPreferredOrientations(DeviceOrientation.values);', screen)

    def test_turkish_wind_abbreviations(self):
        math = read('lib/tools/domain/compass_math.dart')
        self.assertIn("'K', 'KKD', 'KD', 'DKD', 'D'", math)
        self.assertNotIn("'NNE'", math)
        screen = read('lib/features/tools/compass_screen.dart')
        self.assertIn("{0: 'K', 90: 'D', 180: 'G', 270: 'B'}", screen)
        self.assertNotIn(".forEach((", screen)


class ProfileIntegrityTests(unittest.TestCase):
    def test_tools_write_profiles_only_through_validation(self):
        for name in ('chronograph_screen.dart', 'sight_height_screen.dart'):
            text = (TOOLS_UI / name).read_text(encoding='utf-8')
            with self.subTest(screen=name):
                self.assertIn('ToolProfileUpdate.apply(', text)
                self.assertIsNone(re.search(r'_profiles\.save\(RifleProfile\(', text))
        support = read('lib/features/tools/tool_support.dart')
        self.assertIn('ProfileInput.validate(', support)

    def test_chronograph_limit_matches_profile_limit(self):
        stats = read('lib/tools/domain/chronograph_stats.dart')
        self.assertIn('static const maxPlausibleMps = ProductionLimits.maxMuzzleVelocityMps;', stats)

    def test_shell_reloads_profiles_after_tools(self):
        hub = read('lib/features/tools/tools_screen.dart')
        self.assertIn('await onProfilesChanged?.call();', hub)
        home = read('lib/features/home/home_screen.dart')
        self.assertIn('onProfilesChanged: _load', home)


class SightHeightTests(unittest.TestCase):
    def test_project_decisions_are_shown(self):
        text = read('lib/features/tools/sight_height_screen.dart')
        self.assertIn('moderatör, susturucu veya alev gizleyen olmamalı', text)
        self.assertIn('namlu ağzına en yakın ön objektif', text)

    def test_portrait_side_photo_is_rejected(self):
        text = read('lib/features/tools/sight_height_screen.dart')
        self.assertIn('_notLandscape = img.width <= img.height;', text)
        self.assertIn("Key('sight-not-landscape')", text)


class ChronographPressureTests(unittest.TestCase):
    def test_pcp_pressure_is_available(self):
        text = read('lib/features/tools/chronograph_screen.dart')
        self.assertIn("Key('chrono-start-bar')", text)
        self.assertIn("Key('chrono-end-bar')", text)
        self.assertIn('ProductionLimits.maxPcpPressureBar', text)


class WeatherConfigTests(unittest.TestCase):
    def test_contact_is_configurable_and_still_fails_closed_by_default(self):
        cfg = read('lib/tools/config/tools_config.dart')
        self.assertIn("String.fromEnvironment('METNO_CONTACT')", cfg)
        self.assertIn("'SniperTurk/1.0 CONTACT_REQUIRED'", cfg)


if __name__ == '__main__':
    unittest.main()
