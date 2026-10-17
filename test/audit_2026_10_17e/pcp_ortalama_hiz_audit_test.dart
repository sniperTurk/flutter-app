// Denetim 2026-10-17e (feat/pcp-ortalama-hiz): PCP En düşük | En yüksek
// namlu çıkış hızı → the velocity every calculation uses → the correction.
//
// Path checked: the fps the user types (as the editor sends it, fps → m/s)
// → ProfileInput.validate → RifleProfile (codec round trip, as it is saved
// and loaded) → RifleProfile.velocityMps → the solver's correction.
//
// References are independent of the app's Dart code:
//  * the mean is a hand calculation: (830 + 860) / 2 = 845 fps;
//  * the corrections come from tools/formula_reference.py (CIPM-2007 air,
//    PCHIP drag table, Dormand–Prince integrator; written from the
//    published formulas, not from the Dart source): 18 gr, G1 0,031, .217",
//    zero 30 m, sight 50 mm, 15 °C, 1013,25 hPa, %50:
//      845 fps: 50 m 1,2517 mrad, 100 m 6,7532 mrad
//      950 fps: 50 m 0,9054 mrad, 100 m 5,3710 mrad
//    Tolerance as in test/formula_reference_vectors_test.dart: the modelling
//    spread, max(0,03 mrad, %0,5), well below one click (0,1 mrad).
// No other ballistic app is used anywhere.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/core/unit_system.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';

const _air = EnvironmentData(
  temperatureC: 15,
  pressureHpa: 1013.25,
  humidityPercent: 50,
);

/// What the editor does with the typed fps boxes, then save and load.
RifleProfile _saved({
  required String rifleFps,
  String? minFps,
  String? maxFps,
}) {
  String mps(String fps) => UnitSystem.fpsToMps(double.parse(fps)).toString();
  final input = ProfileInput.validate(
    name: 'Denetim',
    muzzleVelocityText: mps(rifleFps),
    zeroRangeText: '30',
    sightHeightText: '50',
    platform: WeaponPlatform.pcp,
    pcpMinVelocityText: minFps == null ? null : mps(minFps),
    pcpMaxVelocityText: maxFps == null ? null : mps(maxFps),
  );
  final p = RifleProfile(
    id: 'den17e',
    name: input.name,
    rifleId: 'r',
    ammunitionId: 'a',
    scopeId: 's',
    muzzleVelocityMps: input.muzzleVelocityMps,
    pcpMinVelocityMps: input.pcpMinVelocityMps,
    pcpMaxVelocityMps: input.pcpMaxVelocityMps,
    zeroRangeM: input.zeroRangeM,
    sightHeightMm: input.sightHeightMm,
  );
  const codec = ProfileCodec();
  return codec.decode(codec.encode(p));
}

List<double> _corrections(double mps) => [
  for (final point in const BallisticEngine().solve(
    BallisticInput(
      muzzleVelocityMps: mps,
      grain: 18,
      zeroRangeM: 30,
      sightHeightMm: 50,
      rangesM: const [50, 100],
      environment: _air,
      ballisticCoefficient: 0.031,
      ballisticModel: BallisticModel.g1,
    ),
  ))
    point.correctionMrad,
];

void main() {
  const ref845 = [1.2517, 6.7532];
  const ref950 = [0.9054, 5.3710];

  for (final (label, minFps, maxFps, fps, ref) in const [
    ('A: Tüfek 950, En düşük 830, En yüksek 860', '830', '860', '845', ref845),
    ('B: Tüfek 950, ikisi boş', null, null, '950', ref950),
  ]) {
    test('$label → $fps fps, corrections match the reference', () {
      final p = _saved(rifleFps: '950', minFps: minFps, maxFps: maxFps);
      expect(UnitSystem.mpsToFps(p.velocityMps).toStringAsFixed(0), fps);
      final got = _corrections(p.velocityMps);
      for (final (i, r) in ref.indexed) {
        expect(got[i], closeTo(r, math.max(0.03, 0.005 * r.abs())));
      }
    });
  }

  test('C: only En düşük 830 → not saved (the pair rule); an older profile '
      'saved with only one loads and uses Tüfek 950', () {
    expect(
      () => _saved(rifleFps: '950', minFps: '830'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'En düşük ve en yüksek hızın ikisini de girin.',
        ),
      ),
    );
    const codec = ProfileCodec();
    final lone = codec.decode(
      codec.encode(
        RifleProfile(
          id: 'lone',
          name: 'Lone',
          rifleId: 'r',
          ammunitionId: 'a',
          scopeId: 's',
          muzzleVelocityMps: UnitSystem.fpsToMps(950),
          pcpMinVelocityMps: UnitSystem.fpsToMps(830),
          zeroRangeM: 30,
          sightHeightMm: 50,
        ),
      ),
    );
    expect(lone.pcpMinVelocityMps, closeTo(UnitSystem.fpsToMps(830), 1e-9));
    expect(UnitSystem.mpsToFps(lone.velocityMps).toStringAsFixed(0), '950');
    final got = _corrections(lone.velocityMps);
    for (final (i, r) in ref950.indexed) {
      expect(got[i], closeTo(r, math.max(0.03, 0.005 * r.abs())));
    }
  });

  test('reversed 860 / 830: refused with the Turkish message', () {
    expect(
      () => _saved(rifleFps: '950', minFps: '860', maxFps: '830'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'En düşük namlu çıkış hızı en yüksek hızdan büyük olamaz.',
        ),
      ),
    );
  });

  test('845 and 950 fps are clearly different (the mean is really used)', () {
    expect(ref845[1] - ref950[1], greaterThan(1));
  });
}
