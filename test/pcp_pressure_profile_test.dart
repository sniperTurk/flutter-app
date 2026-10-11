// PCP tüp ve regülatör basıncı on the profile (owner, 2026-10-12):
// validation, storage, catalog coherence and the tools keep the values;
// a firearm never has them; older profiles read the same as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/pcp_pressure.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/data/profile_catalog_integrity.dart';
import 'package:sniper_turk/features/tools/tool_support.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';

const _pcp = RifleProfile(
  id: 'p',
  name: 'P',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 30,
  sightHeightMm: 60,
  pressureBar: 150,
  tubePressureBar: 250,
  pressureVelocityTable: [
    PressureVelocityPoint(bar: 120, mps: 255),
    PressureVelocityPoint(bar: 150, mps: 270),
  ],
);

ProfileInput _validate({
  WeaponPlatform platform = WeaponPlatform.pcp,
  String? regulator,
  String? tube,
  List<(String, String)> table = const [],
}) => ProfileInput.validate(
  name: 'P',
  muzzleVelocityText: '270',
  zeroRangeText: '30',
  sightHeightText: '60',
  platform: platform,
  pressureText: regulator,
  tubePressureText: tube,
  pressureTable: table,
);

void main() {
  group('ProfileInput', () {
    test('all empty: nothing stored (as before)', () {
      final i = _validate();
      expect(i.pressureBar, isNull);
      expect(i.tubePressureBar, isNull);
      expect(i.pressureVelocityTable, isEmpty);
    });

    test('values kept; comma decimals; fps stored as m/s', () {
      final i = _validate(
        regulator: '150',
        tube: '250,5',
        table: const [('120', '836,6'), ('', ''), ('150', '885,8')],
      );
      expect(i.pressureBar, 150);
      expect(i.tubePressureBar, 250.5);
      expect(i.pressureVelocityTable.length, 2);
      expect(i.pressureVelocityTable.first.bar, 120);
      expect(i.pressureVelocityTable.first.mps, closeTo(255, 0.01));
    });

    test('regulator must be below the tube pressure', () {
      expect(
        () => _validate(regulator: '250', tube: '200'),
        throwsFormatException,
      );
      expect(
        () => _validate(regulator: '200', tube: '200'),
        throwsFormatException,
      );
    });

    test('a half row, a duplicate pressure or a bad value is rejected', () {
      expect(
        () => _validate(table: const [('120', '')]),
        throwsFormatException,
      );
      expect(
        () => _validate(table: const [('120', '800'), ('120', '850')]),
        throwsFormatException,
      );
      expect(
        () => _validate(table: const [('501', '800'), ('120', '850')]),
        throwsFormatException,
      );
      expect(
        () => _validate(table: const [('100', '50'), ('120', '850')]),
        throwsFormatException,
      );
      expect(() => _validate(tube: '0'), throwsFormatException);
    });

    test('a firearm never stores them', () {
      final i = _validate(
        platform: WeaponPlatform.firearm,
        regulator: '150',
        tube: '250',
        table: const [('120', '800'), ('150', '850')],
      );
      expect(i.pressureBar, isNull);
      expect(i.tubePressureBar, isNull);
      expect(i.pressureVelocityTable, isEmpty);
    });
  });

  group('ProfileCodec', () {
    const codec = ProfileCodec();

    test('round trip', () {
      final back = codec.decode(codec.encode(_pcp));
      expect(back.pressureBar, 150);
      expect(back.tubePressureBar, 250);
      expect(back.pressureVelocityTable, _pcp.pressureVelocityTable);
    });

    test('an older profile without the new fields reads as before', () {
      final j = codec.encode(_pcp)
        ..remove('tubePressureBar')
        ..remove('pressureVelocity');
      final back = codec.decode(j);
      expect(back.pressureBar, 150);
      expect(back.tubePressureBar, isNull);
      expect(back.pressureVelocityTable, isEmpty);
    });

    test('a present malformed value is corruption', () {
      for (final bad in <Object>[
        'x',
        [
          {'bar': 120},
        ],
        [
          {'bar': 0, 'mps': 250},
        ],
        [
          {'bar': 120, 'mps': 2000},
        ],
      ]) {
        final j = codec.encode(_pcp)..['pressureVelocity'] = bad;
        expect(() => codec.decode(j), throwsFormatException);
      }
      final j = codec.encode(_pcp)..['tubePressureBar'] = 900;
      expect(() => codec.decode(j), throwsFormatException);
    });
  });

  group('ProfileCatalogIntegrity', () {
    const integrity = ProfileCatalogIntegrity();

    test('a PCP profile with the values resolves', () {
      expect(integrity.resolve(_pcp), isNotNull);
    });

    test('a firearm profile with PCP pressure data is incoherent', () {
      const firearm = RifleProfile(
        id: 'f',
        name: 'F',
        rifleId: 'ata-turqua-308',
        ammunitionId: 'firearm-manual',
        scopeId: 'gazi-6-36',
        muzzleVelocityMps: 800,
        zeroRangeM: 100,
        sightHeightMm: 45,
        tubePressureBar: 250,
      );
      expect(integrity.resolve(firearm), isNull);
    });
  });

  test('Hız Doğrulama keeps the PCP pressure data', () {
    final updated = ToolProfileUpdate.apply(_pcp, muzzleVelocityMps: 272);
    expect(updated.muzzleVelocityMps, closeTo(272, 1e-9));
    expect(updated.pressureBar, 150);
    expect(updated.tubePressureBar, 250);
    expect(updated.pressureVelocityTable, _pcp.pressureVelocityTable);
  });
}
