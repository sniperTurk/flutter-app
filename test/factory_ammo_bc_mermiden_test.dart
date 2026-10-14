// BC mermiden (owner, 2026-10-14). 13:55: "Bulabilirsek sorun yok!
// Kimsenin verisine ihtiyacımız yok ama ateşli tüfekler eksiksiz olmalı."
// 15:16: the remaining 52 BC-less loads stay empty (no estimates, no other
// sources). This PR adds one maker-printed BC (Winchester X651) and fixes
// FA007's weight. Report: docs/reports/bc_mermiden.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/models/domain.dart';

FactoryAmmo _one(String brand, String name, String cartridge) =>
    FactoryAmmoLibrary.all.singleWhere(
      (a) => a.brand == brand && a.name == name && a.cartridge == cartridge,
    );

void main() {
  test('Winchester 6.5 CM Power-Point 129 gr: catalogue BC 0.324 G1', () {
    final a = _one(
      'Winchester',
      'Super-X Power-Point 129 gr Power-Point',
      '6.5 Creedmoor',
    );
    expect(a.bc, 0.324);
    expect(a.bc! > 0, isTrue);
    expect(a.model, BallisticModel.g1);
    expect(a.bcSource, 'printed');
    final uri = Uri.parse(a.bcSourceUrl!);
    expect(uri.scheme, 'https');
    expect(uri.host, 'online.flippingbook.com');
    expect(a.note, contains('14.10.2026'));
    expect(a.note, contains('G1 kabul edildi'));
    expect(a.bcFromBullet, isFalse);
    // Same band as the Profil BC warning: grain/(7000·d²)/BC in 0.32..4.6.
    final d = a.diameterMm / 25.4;
    final i = a.grain / (7000 * d * d) / a.bc!;
    expect(i, inInclusiveRange(0.32, 4.6));
  });

  test('FA007 Aguila Standard Velocity is 40 gr per aguilaammo.com', () {
    final a = _one(
      'Aguila',
      '22 Long Rifle Standard Velocity Lead Solid Point',
      '.22 LR',
    );
    expect(a.grain, 40.0);
    expect(a.note, contains('40 gr'));
    expect(a.bc, isNull);
  });

  test('the other 52 firearm loads stay without BC (owner, 15:16)', () {
    final missing = FactoryAmmoLibrary.all.where((a) => a.bc == null).toList();
    expect(missing, hasLength(52));
    for (final a in missing) {
      expect(a.model, isNull, reason: a.name);
      expect(a.bcSource, isNull, reason: a.name);
    }
  });
}
