// BC'si olmayan ateşli tüfek fişekleri (owner, 2026-10-14: "ateşli tüfekler
// eksiksiz olmalı"): yalnız üreticinin kendi BC'si ya da üreticinin adını
// verdiği merminin üreticisinin BC'si. Rapor: docs/reports/bc_mermiden.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/models/domain.dart';

FactoryAmmo _find(String brand, String name, String cartridge) =>
    FactoryAmmoLibrary.all.singleWhere(
      (a) => a.brand == brand && a.name == name && a.cartridge == cartridge,
    );

/// Form factor i = SD / BC must sit inside the firearm bounds of
/// ProfilesScreen._bcPlausibilityWarning (G1 0.32–4.6, G7 0.63–1.8).
bool _plausible(FactoryAmmo a) {
  final dIn = a.diameterMm / 25.4;
  final i = a.grain / (7000 * dIn * dIn) / a.bc!;
  return switch (a.model) {
    BallisticModel.g1 => i >= 0.32 && i <= 4.6,
    BallisticModel.g7 => i >= 0.63 && i <= 1.8,
    _ => false,
  };
}

void main() {
  final changed = [
    _find(
      'Winchester',
      'Super-X Power-Point 129 gr Power-Point',
      '6.5 Creedmoor',
    ),
  ];

  test('her yeni BC: > 0, model, kaynak URL, makul kesit yoğunluğu', () {
    for (final a in changed) {
      expect(a.bc, isNotNull, reason: a.name);
      expect(a.bc!, greaterThan(0), reason: a.name);
      expect(a.model, isNotNull, reason: a.name);
      expect(a.bcSourceUrl, startsWith('https://'), reason: a.name);
      expect(a.note, isNotNull, reason: a.name);
      expect(_plausible(a), isTrue, reason: a.name);
    }
  });

  test('Winchester X651: katalog BC 0,324, etiketsiz → G1', () {
    final a = changed.single;
    expect(a.bc, 0.324);
    expect(a.model, BallisticModel.g1);
    expect(a.bcSource, 'printed');
    expect(a.bcFromBullet, isFalse);
  });

  test('FA007 Aguila Standard Velocity LSP 40 gr (29 gr .22 Short)', () {
    final a = _find(
      'Aguila',
      '22 Long Rifle Standard Velocity Lead Solid Point',
      '.22 LR',
    );
    expect(a.grain, 40.0);
  });
}
