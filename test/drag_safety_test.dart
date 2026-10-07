import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/drag_safety.dart';
import 'package:sniper_turk/models/domain.dart';

List<DragWarningKind> kinds({
  double v = 250,
  double? bc = 0.03,
  BallisticModel? model = BallisticModel.g1,
  WeaponPlatform platform = WeaponPlatform.pcp,
}) => DragSafety.assess(
  muzzleVelocityMps: v,
  environment: const EnvironmentData(),
  ballisticCoefficient: bc,
  ballisticModel: model,
  platform: platform,
).map((w) => w.kind).toList();

void main() {
  group('Mach warnings (O13)', () {
    test('a normal PCP speed is quiet', () {
      expect(kinds(v: 240), isEmpty);
    });
    test('Mach 0.8 and above warns', () {
      // ~340 m/s sound speed in the default atmosphere: 0.8 Mach is ~272 m/s.
      expect(kinds(v: 280), [DragWarningKind.transonicMuzzle]);
    });
    test('supersonic muzzle speed is its own warning', () {
      expect(kinds(v: 400), [DragWarningKind.supersonicMuzzle]);
    });
    test('hot air raises the speed of sound so the same speed is quieter', () {
      final cold = DragSafety.assess(
        muzzleVelocityMps: 275,
        environment: const EnvironmentData(temperatureC: -20),
        ballisticCoefficient: 0.03,
        ballisticModel: BallisticModel.g1,
        platform: WeaponPlatform.pcp,
      );
      final hot = DragSafety.assess(
        muzzleVelocityMps: 275,
        environment: const EnvironmentData(temperatureC: 40),
        ballisticCoefficient: 0.03,
        ballisticModel: BallisticModel.g1,
        platform: WeaponPlatform.pcp,
      );
      expect(cold, isNotEmpty);
      expect(hot, isEmpty);
    });
  });

  group('BC and drag-law checks (O14)', () {
    test('a typical pellet G1 coefficient is quiet', () {
      expect(kinds(bc: 0.028), isEmpty);
    });
    test('a rifle-bullet sized BC on an airgun warns', () {
      expect(kinds(bc: 0.45), [DragWarningKind.bcOutOfRange]);
      expect(kinds(bc: 0.001), [DragWarningKind.bcOutOfRange]);
    });
    test('G7 on an airgun is flagged as information', () {
      final w = DragSafety.assess(
        muzzleVelocityMps: 240,
        environment: const EnvironmentData(),
        ballisticCoefficient: 0.015,
        ballisticModel: BallisticModel.g7,
        platform: WeaponPlatform.pcp,
      );
      expect(w.map((e) => e.kind), [DragWarningKind.airgunWithG7]);
      expect(w.single.level, DragWarningLevel.info);
    });
    test('firearms are not judged by the airgun BC range', () {
      expect(
        kinds(
          v: 800,
          bc: 0.45,
          model: BallisticModel.g7,
          platform: WeaponPlatform.firearm,
        ),
        [DragWarningKind.supersonicMuzzle],
      );
    });
    test('no coefficient, no coefficient warnings', () {
      expect(kinds(bc: null, model: null), isEmpty);
    });
  });
}
