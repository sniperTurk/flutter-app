import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/tool_support.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/domain/compass_math.dart';
import 'package:sniper_turk/tools/domain/sight_height_geometry.dart';
import 'package:sniper_turk/tools/domain/sight_height_physical.dart';
import 'package:sniper_turk/tools/domain/tilt_math.dart';
import 'package:sniper_turk/tools/domain/weather_policy.dart';
import 'package:sniper_turk/tools/ports/tilt_provider.dart';

import 'support/tool_fakes.dart';

void main() {
  group('CompassMath', () {
    test('normalises and names directions', () {
      expect(CompassMath.normalize(-10), closeTo(350, 1e-9));
      expect(CompassMath.normalize(370), closeTo(10, 1e-9));
      // Turkish 16-wind abbreviations (K/D/G/B), not English N/E/S/W.
      expect(CompassMath.cardinal16(0), 'K');
      expect(CompassMath.cardinal16(22.5), 'KKD');
      expect(CompassMath.cardinal16(90), 'D');
      expect(CompassMath.cardinal16(180), 'G');
      expect(CompassMath.cardinal16(270), 'B');
      expect(CompassMath.cardinal16(315), 'KB');
      expect(CompassMath.wholeDegrees(359.6), 0);
    });
    test('shortest delta wraps across north', () {
      expect(CompassMath.shortestDelta(350, 10), closeTo(20, 1e-9));
      expect(CompassMath.shortestDelta(10, 350), closeTo(-20, 1e-9));
    });
  });

  group('TiltMath', () {
    test('flat phone is level', () {
      final a = TiltMath.angles(
        const GravityVector(0, 0, 9.81),
        TiltMode.flat,
      )!;
      expect(a.xDeg, closeTo(0, 1e-9));
      expect(a.yDeg, closeTo(0, 1e-9));
      expect(TiltMath.isLevel(a), isTrue);
    });
    test('unusable gravity returns null', () {
      expect(
        TiltMath.angles(const GravityVector(0, 0, 0.5), TiltMode.flat),
        isNull,
      );
    });
    test('pose follows gravity with hysteresis', () {
      const flat = GravityVector(0, 0, 9.81);
      const upright = GravityVector(0, 9.81, 0);
      const between = GravityVector(0, 7.5, 6.3); // |gz|/|g| ~ 0.64
      expect(TiltMath.poseFor(flat, TiltMode.upright), TiltMode.flat);
      expect(TiltMath.poseFor(upright, TiltMode.flat), TiltMode.upright);
      expect(TiltMath.poseFor(between, TiltMode.flat), TiltMode.flat);
      expect(TiltMath.poseFor(between, TiltMode.upright), TiltMode.upright);
    });
    test('format uses 0,1 resolution and never -0,0', () {
      expect(TiltMath.format(1.234), '1,2');
      expect(TiltMath.format(-0.01), '0,0');
    });
    test('filter only smooths', () {
      final f = GravityFilter(alpha: 0.5);
      f.add(const GravityVector(0, 0, 10));
      final v = f.add(const GravityVector(2, 0, 10));
      expect(v.x, closeTo(1, 1e-9));
    });
  });

  group('WeatherPolicy', () {
    final t0 = DateTime.utc(2026, 10, 3, 12);
    test('fresh / stale / expired by download age', () {
      final obs = observation(fetchedAt: t0);
      expect(
        WeatherPolicy.freshness(
          obs,
          TestClock(t0.add(const Duration(minutes: 5))),
        ),
        WeatherFreshness.fresh,
      );
      expect(
        WeatherPolicy.freshness(
          obs,
          TestClock(t0.add(const Duration(hours: 2))),
        ),
        WeatherFreshness.stale,
      );
      expect(
        WeatherPolicy.freshness(
          obs,
          TestClock(t0.add(const Duration(hours: 7))),
        ),
        WeatherFreshness.expired,
      );
    });
    test('coordinates are rounded for any cache key', () {
      expect(WeatherPolicy.roundCoordinate(39.912345), 39.91);
    });
  });

  group('SightHeightGeometry', () {
    test('scales from the objective outer diameter', () {
      // Objective 60 mm spans 120 px (0.5 mm/px); bore 130 px below axis.
      final r = SightHeightGeometry.measure(
        objectiveOuterDiameterMm: 60,
        objectiveTop: const PixelPoint(500, 100),
        objectiveBottom: const PixelPoint(500, 220),
        boreCentre: const PixelPoint(500, 290),
      )!;
      expect(r.mmPerPixel, closeTo(0.5, 1e-9));
      expect(r.heightMm, closeTo(65, 1e-9));
    });
    test('a bore point inside the objective disc is rejected', () {
      expect(
        SightHeightGeometry.measure(
          objectiveOuterDiameterMm: 60,
          objectiveTop: const PixelPoint(500, 100),
          objectiveBottom: const PixelPoint(500, 220),
          boreCentre: const PixelPoint(
            500,
            180,
          ), // axis at y=160: 20 px = 10 mm < 30 mm radius
        ),
        isNull,
      );
    });
    test('implausible or degenerate marks give null', () {
      expect(
        SightHeightGeometry.measure(
          objectiveOuterDiameterMm: 60,
          objectiveTop: const PixelPoint(0, 0),
          objectiveBottom: const PixelPoint(0, 5),
          boreCentre: const PixelPoint(0, 50),
        ),
        isNull,
      );
      expect(
        SightHeightGeometry.measure(
          objectiveOuterDiameterMm: 0,
          objectiveTop: const PixelPoint(0, 0),
          objectiveBottom: const PixelPoint(0, 100),
          boreCentre: const PixelPoint(0, 200),
        ),
        isNull,
      );
    });
  });

  group('ToolProfileUpdate (review fix)', () {
    const base = RifleProfile(
      id: 'p1',
      name: 'Bir',
      rifleId: 'hatsan-hercules-635',
      ammunitionId: 'gmaz-51',
      scopeId: 'gazi-6-36',
      muzzleVelocityMps: 270,
      zeroRangeM: 25,
      sightHeightMm: 60,
      pressureBar: 200,
    );

    test('applies a valid value and keeps every other field', () {
      final p = ToolProfileUpdate.apply(base, sightHeightMm: 62.4);
      expect(p.sightHeightMm, 62.4);
      expect(p.muzzleVelocityMps, 270);
      expect(p.pressureBar, 200);
      expect(p.id, 'p1');
    });

    test('rejects values the profile decoder would refuse later', () {
      expect(
        () => ToolProfileUpdate.apply(base, muzzleVelocityMps: 1600),
        throwsFormatException,
      );
      expect(
        () => ToolProfileUpdate.apply(base, sightHeightMm: 300),
        throwsFormatException,
      );
    });
  });

  group('SightHeightPhysical', () {
    test('bore radius + top wall + front gap + objective OUTER radius', () {
      final r = SightHeightPhysical.compute(
        boreDiameterMm: 6.36,
        barrelWallMm: 5.8,
        gapMm: 21.4,
        objectiveOuterDiameterMm: 64,
      )!;
      expect(r.totalMm, closeTo(62.38, 1e-9));
      expect(PhysicalSightHeight.roundedText(r.totalMm, 1), '62,4');
      expect(r.roundedMm, 62.4);
    });

    test('missing, zero, negative or non-finite input gives no result', () {
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: null,
          barrelWallMm: 5,
          gapMm: 5,
          objectiveOuterDiameterMm: 64,
        ),
        isNull,
      );
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: 6,
          barrelWallMm: 0,
          gapMm: 5,
          objectiveOuterDiameterMm: 64,
        ),
        isNull,
      );
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: 6,
          barrelWallMm: -1,
          gapMm: 5,
          objectiveOuterDiameterMm: 64,
        ),
        isNull,
      );
      expect(
        SightHeightPhysical.compute(
          boreDiameterMm: 6,
          barrelWallMm: 5,
          gapMm: double.nan,
          objectiveOuterDiameterMm: 64,
        ),
        isNull,
      );
    });
  });
}
