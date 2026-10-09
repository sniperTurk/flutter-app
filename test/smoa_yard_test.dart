// SMOA turrets ("1/4 IN @ 100 YDS") and yard profiles (owner, 2026-10-09).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/core/units.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _ammo = <String, dynamic>{
  'id': 'c-yard',
  'kind': 'custom_ammunition',
  'platform': 'pcp',
  'brand': 'Deneme',
  'model': '.25 slug',
  'caliberMm': 6.35,
  'grain': 34,
  'ammoType': 'slug',
  'bc': 0.08,
  'bcModel': 'G1',
};

const _yardProfile = RifleProfile(
  id: 'p-yd',
  name: 'Yard',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'c-yard',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 280,
  zeroRangeM: 27.432, // 30 yd
  sightHeightMm: 60,
  distanceUnit: DistanceUnit.yard,
);

void main() {
  group('SMOA', () {
    test('1 SMOA = 1 inch at 100 yd = 1/3600 rad', () {
      expect(AngularUnit.smoa.toMrad(1), closeTo(0.0254 / 91.44 * 1000, 1e-12));
      expect(AngularUnit.smoa.toMrad(1), closeTo(0.277778, 1e-6));
      // 4.5 % smaller than a true MOA.
      expect(
        ScopeDialMath.convert(1, AngularUnit.smoa, AngularUnit.moa),
        closeTo(0.9549, 1e-4),
      );
      expect(AngularUnit.moa.toMrad(1), closeTo(Units.moaToMrad(1), 1e-12));
      expect(AngularUnit.smoa.label, 'SMOA');
      expect(AngularUnit.smoa.moaFamily, isTrue);
      expect(ScopeDialMath.standardClick(AngularUnit.smoa), 0.25);
    });

    test('a 30 MOA mount is 125 quarter-SMOA clicks (120 in MOA)', () {
      expect(ScopeDialMath.mountCantClicks(30, 0.25, AngularUnit.moa), 120);
      expect(ScopeDialMath.mountCantClicks(30, 0.25, AngularUnit.smoa), 125);
    });

    test('10 cm at 100 m in SMOA', () {
      final smoa = ScopeDialMath.angleAtRange(0.10, 100, AngularUnit.smoa);
      final moa = ScopeDialMath.angleAtRange(0.10, 100, AngularUnit.moa);
      expect(smoa / moa, closeTo(1 / 0.9549, 1e-3));
    });
  });

  group('profile codec', () {
    const codec = ProfileCodec();
    test('distanceUnit and SMOA round-trip; old profiles are metres', () {
      final j = codec.encode(
        const RifleProfile(
          id: 'a',
          name: 'A',
          rifleId: 'r',
          ammunitionId: 'm',
          scopeId: 's',
          muzzleVelocityMps: 280,
          zeroRangeM: 27.432,
          sightHeightMm: 60,
          angularUnit: AngularUnit.smoa,
          distanceUnit: DistanceUnit.yard,
        ),
      );
      final back = codec.decode(j);
      expect(back.distanceUnit, DistanceUnit.yard);
      expect(back.angularUnit, AngularUnit.smoa);
      final old = Map<String, dynamic>.of(j)..remove('distanceUnit');
      expect(codec.decode(old).distanceUnit, DistanceUnit.meter);
      final bad = Map<String, dynamic>.of(j)..['distanceUnit'] = 'mil';
      expect(() => codec.decode(bad), throwsFormatException);
    });
  });

  group('yard profile on Hedef', () {
    setUp(
      () => CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_ammo]),
      ),
    );
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    testWidgets('range dial, zero and table are in yards', (tester) async {
      tester.view.physicalSize = const Size(430, 2600) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget app(BallisticsView view) => MaterialApp(
        theme: MenzilTheme.light(),
        home: Scaffold(
          body: BallisticsScreen(profile: _yardProfile, view: view),
        ),
      );
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      // The shot range starts at a round 100 yd.
      expect(find.text('100'), findsOneWidget);
      expect(find.text('yd'), findsWidgets);

      await tester.pumpWidget(app(BallisticsView.table));
      await tester.pumpAndSettle();
      final make = find.text('DOPE oluştur');
      await tester.ensureVisible(make);
      await tester.tap(make);
      await tester.pumpAndSettle();
      // The zero is shown as 30 yd.
      expect(find.textContaining('Sıfır mesafesi 30.0 yd'), findsOneWidget);
    });
  });
}
