// BC mermiden (owner, 2026-10-14 13:55): "Bulabilirsek sorun yok! Kimsenin
// verisine ihtiyacımız yok ama ateşli tüfekler eksiksiz olmalı." The 53
// BC-less firearm loads left after #296 were searched again; 14 got the load
// maker's own printed BC. Report: docs/reports/bc_mermiden.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/models/domain.dart';

/// (brand, name, cartridge, BC, URL host).
const _added = <(String, String, String, double, String)>[
  (
    'Winchester',
    'M22 40 gr Black Copper Plated Round Nose',
    '.22 LR',
    0.125,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super Suppressed 45 gr Black Copper Plated Round Nose',
    '.22 LR',
    0.141,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X 37 gr Hollow Point Copper Plated',
    '.22 LR',
    0.107,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X 40 gr Lead Round Nose Copper Plated',
    '.22 LR',
    0.116,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X 40 gr Power-Point Hollow Point Copper Plated',
    '.22 LR',
    0.098,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X 40 gr Power-Point HP Copper Plated',
    '.22 LR',
    0.098,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X Super Speed 37 gr Hollow Point Copper Plated',
    '.22 LR',
    0.111,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super X Super Speed 40 gr Round Nose Copper Plated',
    '.22 LR',
    0.119,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Varmint HV 40 gr Hyper Velocity Hollow Point Copper Plated',
    '.22 LR',
    0.105,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Wildcat 40 gr Copper Plated DynaPoint',
    '.22 LR',
    0.116,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Varmint HV 22 Win Mag 30 gr JHP',
    '.22 WMR',
    0.089,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Super-X Power-Point 129 gr Power-Point',
    '6.5 Creedmoor',
    0.324,
    'online.flippingbook.com',
  ),
  (
    'Winchester',
    'Power-Point 170 gr',
    '6.8 Western',
    0.431,
    'online.flippingbook.com',
  ),
  (
    'SWISS P',
    'SWISS P Target SX - 8.4 g / 130 gr',
    '6.5 Creedmoor',
    0.622,
    'swiss-p.com',
  ),
];

FactoryAmmo _one(String brand, String name, String cartridge) =>
    FactoryAmmoLibrary.all.singleWhere(
      (a) => a.brand == brand && a.name == name && a.cartridge == cartridge,
    );

void main() {
  test('the 14 loads carry the maker BC, a model and a source URL', () {
    expect(_added, hasLength(14));
    for (final (brand, name, cartridge, bc, host) in _added) {
      final a = _one(brand, name, cartridge);
      expect(a.bc, bc, reason: name);
      expect(a.bc! > 0, isTrue, reason: name);
      expect(a.model, BallisticModel.g1, reason: name);
      expect(a.bcSource, 'printed', reason: name);
      final uri = Uri.parse(a.bcSourceUrl!);
      expect(uri.scheme, 'https', reason: name);
      expect(uri.host, host, reason: name);
      expect(a.note, contains('14.10.2026'), reason: name);
      expect(a.bcFromBullet, isFalse, reason: name);
    }
  });

  test('unlabelled Winchester BCs say they were taken as G1', () {
    for (final (brand, name, cartridge, _, _) in _added) {
      if (brand != 'Winchester') continue;
      expect(_one(brand, name, cartridge).note, contains('G1 kabul edildi'));
    }
  });

  test('SWISS P Target SX: printed G1 0.622 and G7 0.308 (ICAO)', () {
    final a = _one(
      'SWISS P',
      'SWISS P Target SX - 8.4 g / 130 gr',
      '6.5 Creedmoor',
    );
    expect(a.bc, 0.622);
    expect(a.model, BallisticModel.g1);
    expect(a.bcG7, 0.308);
    expect(a.note, contains('ICAO'));
  });

  test('no added BC trips the firearm G1 plausibility band', () {
    // Same band as the Profil BC warning: grain/(7000·d²)/BC in 0.32..4.6.
    for (final (brand, name, cartridge, _, _) in _added) {
      final a = _one(brand, name, cartridge);
      final d = a.diameterMm / 25.4;
      final i = a.grain / (7000 * d * d) / a.bc!;
      expect(i, inInclusiveRange(0.32, 4.6), reason: name);
    }
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

  test('39 firearm loads are still without BC (bulunamadı)', () {
    final missing = FactoryAmmoLibrary.all.where((a) => a.bc == null).toList();
    expect(missing, hasLength(39));
    for (final a in missing) {
      expect(a.model, isNull, reason: a.name);
    }
  });
}
