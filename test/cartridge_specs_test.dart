// Kalibre ölçüleri (2026-10-11): every Kalibre list entry has a sourced
// spec record; values come from C.I.P./SAAMI/maker sheets only.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/data/cartridge_specs.dart';
import 'package:sniper_turk/data/cartridges.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/rifle_library.dart';
import 'package:sniper_turk/models/domain.dart';

void main() {
  test('every Kalibre list name has a spec record', () {
    for (final (name, mm) in Cartridges.firearm) {
      final s = CartridgeSpecs.of(name);
      expect(s, isNotNull, reason: name);
      expect(s!.bulletDiameterMm, mm, reason: name);
      expect(s.bulletDiameterIn, closeTo(mm / 25.4, 0.0001), reason: name);
    }
    for (final (mm, label) in Cartridges.pcp) {
      expect(CartridgeSpecs.of(label)?.bulletDiameterMm, mm, reason: label);
    }
    expect(
      CartridgeSpecs.all.length,
      Cartridges.firearm.length + Cartridges.pcp.length,
    );
  });

  test('spec values are sourced and in range', () {
    for (final s in CartridgeSpecs.all.values) {
      for (final u in s.sources) {
        expect(u, startsWith('https://'), reason: s.name);
      }
      // A value without a source cannot exist.
      final hasValue = [
        s.caseLengthMm,
        s.maxCartridgeLengthMm,
        s.pmaxBar,
        s.mapPsi,
        s.twistIn,
      ].any((v) => v != null);
      if (hasValue) expect(s.sources, isNotEmpty, reason: s.name);
      expect(s.note.trim(), isNotEmpty, reason: s.name);
      if (s.caseLengthMm != null && s.maxCartridgeLengthMm != null) {
        expect(s.caseLengthMm!, lessThan(s.maxCartridgeLengthMm!));
      }
      if (s.pmaxBar != null) {
        expect(s.pmaxBar!, inInclusiveRange(500, 6000), reason: s.name);
      }
      if (s.mapPsi != null) {
        expect(s.mapPsi!, inInclusiveRange(10000, 90000), reason: s.name);
      }
      if (s.twistIn != null) {
        expect(s.twistIn!, inInclusiveRange(4, 30), reason: s.name);
      }
      if (s.bulletWeightMinGr != null) {
        expect(s.bulletWeightMinGr!, lessThanOrEqualTo(s.bulletWeightMaxGr!));
        expect(s.bulletWeightFrom, isNotNull, reason: s.name);
      }
    }
  });

  test('C.I.P. reference values (6,5 Creedmoor, .308 Win)', () {
    final cm = CartridgeSpecs.of('6.5 Creedmoor')!;
    expect(cm.caseLengthMm, 48.77);
    expect(cm.maxCartridgeLengthMm, 71.76);
    expect(cm.pmaxBar, 4350);
    expect(cm.twistIn, closeTo(8, 0.01));
    final w = CartridgeSpecs.of('.308 Win')!;
    expect(w.caseLengthMm, 51.18);
    expect(w.maxCartridgeLengthMm, 71.12);
    expect(w.pmaxBar, 4150);
  });

  test('new calibers are listed and linked to rifles and ammo', () {
    final names = {for (final (n, _) in Cartridges.firearm) n};
    for (final n in [
      '8x57 JR',
      '10.3x60 R',
      '5.45x39',
      '7.65x53 Arg',
      '7mm WSM',
      '7mm Rem SAUM',
      '7mm RUM',
      '.300 Rem SAUM',
      '.284 Win',
      '.300 H&H Mag',
      '.300 Savage',
    ]) {
      expect(names, contains(n));
      expect(CartridgeSpecs.of(n)!.added, isTrue, reason: n);
    }
    // Previously skipped by the generator for want of a caliber.
    expect(RifleLibrary.all.any((r) => r.cartridge == '10.3x60 R'), isTrue);
    expect(FactoryAmmoLibrary.all.any((a) => a.cartridge == '8x57 JR'), isTrue);
    expect(Cartridges.pcp.any((e) => e.$1 == 11.6), isTrue);
    expect(
      RifleLibrary.all.any(
        (r) =>
            r.platform == WeaponPlatform.pcp && r.cartridge == '11.60 mm (.45)',
      ),
      isTrue,
    );
    // Existing names keep their place: the popular block is unchanged.
    expect(Cartridges.firearm.first.$1, '.308 Win');
    expect(Cartridges.popularCount, 10);
  });

  test('no standard found: fields stay empty with a reason', () {
    final nato = CartridgeSpecs.of('7.62x51 NATO')!;
    expect(nato.caseLengthMm, isNull);
    expect(nato.pmaxBar, isNull);
    expect(nato.note, contains('STANAG'));
  });
}
