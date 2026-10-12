import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/estimated_bc.dart';
import 'package:sniper_turk/models/domain.dart';

Ammunition _ammo({
  WeaponPlatform platform = WeaponPlatform.pcp,
  AmmunitionType type = AmmunitionType.slug,
  double grain = 50,
  double caliberMm = 6.35,
  double? bc,
}) => Ammunition(
  id: 'a',
  brand: '',
  model: '',
  platform: platform,
  caliberMm: caliberMm,
  grain: grain,
  type: type,
  ballisticCoefficient: bc,
  ballisticModel: bc == null ? null : BallisticModel.g1,
);

void main() {
  test('PCP slug without BC gets SD / 0.825 as G1', () {
    // SD = 50 / (7000 · 0.25²) = 0.1143 lb/in²; / 0.825 = 0.139.
    final a = EstimatedBc.fill(_ammo());
    expect(a.ballisticCoefficient, closeTo(0.139, 1e-9));
    expect(a.ballisticModel, BallisticModel.g1);
  });

  test('PCP pellet uses the pellet form factor', () {
    // 25.39 gr .25: SD 0.0580; / 2.06 = 0.028.
    final bc = EstimatedBc.g1For(
      _ammo(type: AmmunitionType.pellet, grain: 25.39),
    );
    expect(bc, closeTo(0.028, 1e-9));
  });

  test('a given BC and a firearm are left alone', () {
    final given = _ammo(bc: 0.1);
    expect(identical(EstimatedBc.fill(given), given), isTrue);
    final firearm = _ammo(
      platform: WeaponPlatform.firearm,
      type: AmmunitionType.bullet,
    );
    expect(identical(EstimatedBc.fill(firearm), firearm), isTrue);
  });
}
