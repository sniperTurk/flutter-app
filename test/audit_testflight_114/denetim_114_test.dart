// Denetim TestFlight 114 (2026-10-17): regression guards for the changes
// merged since TestFlight 113 (2101b3f). Report:
// docs/reports/denetim-testflight-114.md.
//
// References are independent of the app's Dart code (no other ballistic
// app is used anywhere):
//  * Miller twist rule (Miller 2005, Precision Shooting): hand calculation
//    in Python, .308" 168 gr, 1,215" (30,861 mm), 1:10", 2650 fps, 59 °F,
//    29,92 inHg → Sg 2,4591.
//  * Arken Optics OUTRIDER 3-18x50 SFP, manufacturer page
//    arkenopticsusa.com (read 2026-10-17): 0.25 MOA, 56 MOA elevation,
//    48 MOA windage, 14.4 in, FDR 29.2 oz. MOA → mrad = × π / 10,8.
//  * PCP mean: hand calculation (250 + 260) / 2 = 255 m/s = 836,6 fps.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/core/stability.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/data/scope_library.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/features/tools/tool_support.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';

RifleProfile _pcp({
  double muzzle = 300,
  double? min,
  double? max,
}) => RifleProfile(
  id: 'd114',
  name: 'D114',
  rifleId: 'd114-yok-rifle',
  ammunitionId: 'd114-yok-ammo',
  scopeId: 'd114-yok-scope',
  muzzleVelocityMps: muzzle,
  zeroRangeM: 30,
  sightHeightMm: 50,
  // An older profile's pressure: ToolProfileUpdate treats it as PCP when
  // the rifle record is not in the catalog.
  pressureBar: 150,
  pcpMinVelocityMps: min,
  pcpMaxVelocityMps: max,
);

void main() {
  group('#388 PCP En düşük | En yüksek → ortalama', () {
    test('pair 250 / 260 m/s, Tüfek 300 → 255 m/s (836,6 fps)', () {
      final p = _pcp(min: 250, max: 260);
      expect(p.velocityMps, 255);
      expect(UnitSystem.mpsToFps(p.velocityMps), closeTo(836.6, 0.05));
    });

    test('equal pair 255 / 255 saves and is used', () {
      final input = ProfileInput.validate(
        name: 'Eşit',
        muzzleVelocityText: '300',
        zeroRangeText: '30',
        sightHeightText: '50',
        platform: WeaponPlatform.pcp,
        pcpMinVelocityText: '255',
        pcpMaxVelocityText: '255',
      );
      expect(input.pcpMinVelocityMps, 255);
      expect(input.pcpMaxVelocityMps, 255);
      expect(_pcp(min: 255, max: 255).velocityMps, 255);
    });

    test('only En yüksek typed → refused (pair rule)', () {
      expect(
        () => ProfileInput.validate(
          name: 'Tek',
          muzzleVelocityText: '300',
          zeroRangeText: '30',
          sightHeightText: '50',
          platform: WeaponPlatform.pcp,
          pcpMaxVelocityText: '260',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('firearm: typed PCP pair is dropped, velocity = Namlu çıkış hızı',
        () {
      final input = ProfileInput.validate(
        name: 'Ateşli',
        muzzleVelocityText: '800',
        zeroRangeText: '100',
        sightHeightText: '40',
        platform: WeaponPlatform.firearm,
        pcpMinVelocityText: '250',
        pcpMaxVelocityText: '260',
      );
      expect(input.pcpMinVelocityMps, isNull);
      expect(input.pcpMaxVelocityMps, isNull);
    });

    test('older profile with only one value loads, uses Tüfek 300', () {
      const codec = ProfileCodec();
      for (final p in [_pcp(min: 250), _pcp(max: 260)]) {
        final back = codec.decode(codec.encode(p));
        expect(back.velocityMps, 300);
        expect(back.pcpMinVelocityMps, p.pcpMinVelocityMps);
        expect(back.pcpMaxVelocityMps, p.pcpMaxVelocityMps);
      }
    });

    test('reversed pair in memory is not averaged (falls back to Tüfek)', () {
      expect(_pcp(min: 260, max: 250).velocityMps, 300);
    });

    test('Araçlar: pair → one velocity refused; lone value → written, kept',
        () {
      expect(
        () => ToolProfileUpdate.apply(
          _pcp(min: 250, max: 260),
          muzzleVelocityMps: 270,
        ),
        throwsA(isA<FormatException>()),
      );
      final lone = ToolProfileUpdate.apply(
        _pcp(min: 250),
        muzzleVelocityMps: 270,
      );
      expect(lone.muzzleVelocityMps, 270);
      expect(lone.pcpMinVelocityMps, 250);
      expect(lone.velocityMps, 270);
    });

    test(
      'D114-2: Profiller listesi shows the velocity the calculation uses',
      () {
        // 250 / 260 m/s pair, Tüfek 300 m/s: Hedef uses 255 m/s = 837 fps;
        // the list line shows the Tüfek box, 984 fps.
        final line = profileListSummary(_pcp(min: 250, max: 260));
        expect(line, contains('837 fps'));
      },
      skip: 'D114-2 (ORTA): Profil özeti / Profiller listesi / Kronograf '
          'Tüfek kartındaki hızı gösteriyor, hesap ortalamayı kullanıyor.',
    );
  });

  group('#387 Mermi uzunluğu 150 mm → Miller Sg', () {
    test('Miller Sg matches the hand calculation (2,4591)', () {
      final sg = Stability.millerSg(
        grain: 168,
        caliberMm: 0.308 * 25.4,
        twistIn: 10,
        lengthMm: 1.215 * 25.4,
        velocityMps: UnitSystem.fpsToMps(2650),
        temperatureC: 15,
        pressureHpa: 1013.25,
      );
      expect(sg, closeTo(2.4591, 0.002));
    });

    test('150 mm (the new limit) gives a finite, positive, tiny Sg', () {
      final sg = Stability.millerSg(
        grain: 30,
        caliberMm: 6.35,
        twistIn: 17,
        lengthMm: 150,
        velocityMps: UnitSystem.fpsToMps(900),
        temperatureC: 15,
        pressureHpa: 1013.25,
      );
      expect(sg.isFinite, isTrue);
      expect(sg, greaterThan(0));
      expect(Stability.classify(sg), StabilityLevel.unstable);
      expect(Stability.lengthCalibers(150, 6.35), closeTo(150 / 6.35, 1e-9));
    });
  });

  group('#390 Arken Optics SFP (manufacturer values)', () {
    double mrad(double moa) => moa * math.pi / 10.8;
    ScopeOptic byId(String id) =>
        ScopeLibrary.all.firstWhere((s) => s.id == id);

    test('OUTRIDER 3-18x50 SFP = arkenopticsusa.com page', () {
      final s = byId('lib-arken-optics-outrider-3-18x50-sfp');
      expect(s.clickValue, 0.25);
      expect(s.clickUnit, AngularUnit.moa);
      expect(s.firstFocalPlane, isFalse);
      expect(s.elevationRangeMrad, closeTo(mrad(56), 0.005));
      expect(s.windageRangeMrad, closeTo(mrad(48), 0.005));
      expect(s.lengthMm, closeTo(14.4 * 25.4, 0.05));
      expect(s.weightG, closeTo(29.2 * 28.349523125, 0.1));
    });

    test('OUTRIDER 2-12x42 and LH-6 ranges: MOA → mrad', () {
      final a = byId('lib-arken-optics-outrider-2-12x42-sfp');
      expect(a.elevationRangeMrad, closeTo(mrad(90), 0.005));
      expect(a.windageRangeMrad, closeTo(mrad(80), 0.005));
      final b = byId('lib-arken-optics-lh-6-1-6x24-sfp');
      expect(b.elevationRangeMrad, closeTo(mrad(180), 0.005));
      expect(b.windageRangeMrad, closeTo(mrad(180), 0.005));
      expect(b.clickValue, 0.25);
    });
  });
}
