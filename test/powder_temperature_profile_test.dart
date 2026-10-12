// Barut sıcaklığı on the profile (owner, 2026-10-11): the coefficient and
// the velocity's reference temperature live on Profil > Mühimmat (firearms
// only), the factory list fills them when the maker publishes a figure, and
// Atış / Hız Doğrulama scale the velocity with PowderTemperature.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/profile_input.dart';
import 'package:sniper_turk/data/factory_ammo_library.dart';
import 'package:sniper_turk/data/factory_powder_temperature.dart';
import 'package:sniper_turk/features/profiles/profile_field_info.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_codec.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

import 'support/rifle_form.dart';

const _base = RifleProfile(
  id: 'p1',
  name: 'P',
  rifleId: 'r',
  ammunitionId: 'a',
  scopeId: 's',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

const _withPowder = RifleProfile(
  id: 'p1',
  name: 'P',
  rifleId: 'r',
  ammunitionId: 'a',
  scopeId: 's',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: 1.5,
  powderTempReferenceC: 20,
);

ProfileInput _validate({
  String? coef,
  String? temp,
  WeaponPlatform platform = WeaponPlatform.firearm,
}) => ProfileInput.validate(
  name: 'P',
  muzzleVelocityText: '800',
  zeroRangeText: '100',
  sightHeightText: '45',
  platform: platform,
  powderCoefText: coef,
  powderTempText: temp,
);

Future<void> _openNew(WidgetTester tester, {bool firearm = true}) async {
  tester.view.physicalSize = const Size(430 * 3, 2600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.light(),
      home: ProfilesScreen(store: MemoryProfileStore()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Yeni profil'));
  await tester.pumpAndSettle();
  await chooseInSelect(
    tester,
    'profile-platform',
    firearm ? 'Ateşli Tüfek' : 'PCP Tüfek',
  );
}

String _text(WidgetTester tester, String key) => tester
    .widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    )
    .controller!
    .text;

Future<void> _pickHornady(WidgetTester tester, String model) async {
  await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
  await chooseInSelect(tester, 'ammo-model-select', model);
}

void main() {
  group('PowderTemperature', () {
    test('factor: 15 °C warmer at 1.5 %/15 °C is +1.5 %', () {
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1.5,
          referenceTempC: 20,
          todayTempC: 35,
        ),
        closeTo(1.015, 1e-12),
      );
      // Colder: slower.
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1.5,
          referenceTempC: 20,
          todayTempC: 5,
        ),
        closeTo(0.985, 1e-12),
      );
    });

    test('forProfile: the profile values win over the old Pro text', () {
      final r = PowderTemperature.forProfile(
        profile: _withPowder,
        platform: WeaponPlatform.firearm,
        legacyCoefText: '3',
        legacyTempText: '0',
      );
      expect(r.coef, 1.5);
      expect(r.referenceC, 20);
      expect(r.fromProfile, isTrue);
    });

    test('forProfile: a profile without values reads the old Pro text', () {
      final r = PowderTemperature.forProfile(
        profile: _base,
        platform: WeaponPlatform.firearm,
        legacyCoefText: '1,2',
        legacyTempText: ' 15 ',
      );
      expect(r.coef, 1.2);
      expect(r.referenceC, 15);
      expect(r.fromProfile, isFalse);
    });

    test('forProfile: nothing on PCP', () {
      final r = PowderTemperature.forProfile(
        profile: _withPowder,
        platform: WeaponPlatform.pcp,
        legacyCoefText: '1',
        legacyTempText: '20',
      );
      expect(r.coef, isNull);
      expect(r.referenceC, isNull);
    });
  });

  group('ProfileInput: Barut sıcaklığı', () {
    test('optional: none given is none', () {
      final i = _validate();
      expect(i.powderTempCoefPercentPer15C, isNull);
      expect(i.powderTempReferenceC, isNull);
    });

    test('both given are kept (comma decimals too)', () {
      final i = _validate(coef: '1,5', temp: '-5');
      expect(i.powderTempCoefPercentPer15C, 1.5);
      expect(i.powderTempReferenceC, -5);
    });

    test('only one of the pair is rejected', () {
      expect(() => _validate(coef: '1'), throwsFormatException);
      expect(() => _validate(temp: '20'), throwsFormatException);
    });

    test('out of the accepted bands is rejected', () {
      expect(() => _validate(coef: '11', temp: '20'), throwsFormatException);
      expect(() => _validate(coef: '1', temp: '61'), throwsFormatException);
      expect(() => _validate(coef: 'x', temp: '20'), throwsFormatException);
    });

    test('a PCP never stores it', () {
      final i = _validate(coef: '1', temp: '20', platform: WeaponPlatform.pcp);
      expect(i.powderTempCoefPercentPer15C, isNull);
      expect(i.powderTempReferenceC, isNull);
    });
  });

  group('ProfileCodec: Barut sıcaklığı', () {
    const codec = ProfileCodec();

    test('round trip', () {
      final back = codec.decode(codec.encode(_withPowder));
      expect(back.powderTempCoefPercentPer15C, 1.5);
      expect(back.powderTempReferenceC, 20);
    });

    test('an older profile without the fields has none', () {
      final j = codec.encode(_base)
        ..remove('powderTempCoef')
        ..remove('powderTempRefC');
      final back = codec.decode(j);
      expect(back.powderTempCoefPercentPer15C, isNull);
      expect(back.powderTempReferenceC, isNull);
    });

    test('a corrupt value is not silently dropped', () {
      final half = codec.encode(_withPowder)..['powderTempRefC'] = null;
      expect(() => codec.decode(half), throwsFormatException);
      final wild = codec.encode(_withPowder)..['powderTempCoef'] = 40;
      expect(() => codec.decode(wild), throwsFormatException);
      final text = codec.encode(_withPowder)..['powderTempRefC'] = '20';
      expect(() => codec.decode(text), throwsFormatException);
    });
  });

  group('FactoryPowderTempLibrary', () {
    tearDown(
      () => FactoryPowderTempLibrary.records = FactoryPowderTempLibrary.all,
    );

    test('every record is a maker figure for a listed factory round', () {
      for (final r in FactoryPowderTempLibrary.all) {
        expect(r.sourceUrl, startsWith('https://'), reason: r.name);
        expect(
          r.coefPercentPer15C.abs(),
          lessThanOrEqualTo(PowderTemperature.maxCoef),
          reason: r.name,
        );
        expect(
          r.referenceTempC,
          inInclusiveRange(
            PowderTemperature.minTempC,
            PowderTemperature.maxTempC,
          ),
          reason: r.name,
        );
        expect(
          FactoryAmmoLibrary.all.any(
            (a) => a.brand == r.brand && a.name == r.name,
          ),
          isTrue,
          reason: '${r.brand} ${r.name} is not in the factory list',
        );
      }
    });

    test('lookup is by exact brand and name', () {
      FactoryPowderTempLibrary.records = const [
        FactoryPowderTemp('Hornady', 'X 1', 1, 21, 'https://example.invalid'),
      ];
      expect(FactoryPowderTempLibrary.lookup('Hornady', 'X 1'), isNotNull);
      expect(FactoryPowderTempLibrary.lookup('Hornady', 'X 2'), isNull);
      expect(FactoryPowderTempLibrary.lookup('hornady', 'X 1'), isNull);
    });
  });

  test('the ⓘ texts say what, where and give an example', () {
    for (final t in [
      ProfileFieldInfo.powderCoef,
      ProfileFieldInfo.powderTemp,
    ]) {
      expect(t, contains('Örnek'));
      expect(t, isNot(contains('(')));
    }
    expect(ProfileFieldInfo.powderCoef, contains('kronograf'));
    expect(ProfileFieldInfo.powderCoef, contains('Yalnızca ateşli tüfek'));
  });

  group('Profil > Mühimmat', () {
    tearDown(
      () => FactoryPowderTempLibrary.records = FactoryPowderTempLibrary.all,
    );

    testWidgets('firearm: Katsayı | Ölçüm sıcaklığı side by side with ⓘ', (
      tester,
    ) async {
      await _openNew(tester);
      final k = find.byKey(const Key('profile-powder-coef'));
      final t = find.byKey(const Key('profile-powder-temp'));
      expect(k, findsOneWidget);
      expect(t, findsOneWidget);
      await tester.ensureVisible(k);
      await tester.pumpAndSettle();
      final kr = tester.getRect(k), tr = tester.getRect(t);
      expect((kr.top - tr.top).abs(), lessThan(1));
      expect(kr.right, lessThan(tr.left));
      // Labels without parentheses; the explanation sits behind ⓘ.
      expect(find.text('Barut katsayısı'), findsOneWidget);
      expect(find.text('Hız ölçüm sıcaklığı'), findsOneWidget);
      expect(
        find.descendant(of: k, matching: find.byType(MenzilInfoButton)),
        findsOneWidget,
      );
      // Empty until the shooter types (no example value in the box).
      expect(_text(tester, 'profile-powder-coef'), '');
      expect(_text(tester, 'profile-powder-temp'), '');
    });

    testWidgets('PCP: no Barut sıcaklığı', (tester) async {
      await _openNew(tester, firearm: false);
      expect(find.byKey(const Key('profile-powder-coef')), findsNothing);
      expect(find.byKey(const Key('profile-powder-temp')), findsNothing);
    });

    testWidgets('no maker figure: the boxes stay for the shooter', (
      tester,
    ) async {
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await _pickHornady(tester, 'ELD Match 168 gr ELD Match');
      expect(_text(tester, 'profile-velocity-fps'), '2700');
      expect(_text(tester, 'profile-powder-coef'), '');
      expect(_text(tester, 'profile-powder-temp'), '');
    });

    testWidgets('a maker figure fills the boxes; typed values stay', (
      tester,
    ) async {
      FactoryPowderTempLibrary.records = const [
        FactoryPowderTemp(
          'Hornady',
          'ELD Match 168 gr ELD Match',
          0.8,
          21,
          'https://example.invalid/test-only',
        ),
      ];
      await _openNew(tester);
      await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
      await chooseInSelect(tester, 'ammo-source', 'Fabrika fişeği');
      await _pickHornady(tester, 'ELD Match 168 gr ELD Match');
      expect(_text(tester, 'profile-powder-coef'), '0,8');
      expect(_text(tester, 'profile-powder-temp'), '21');

      // Another round without a figure: the automatic values go.
      await _pickHornady(tester, 'Match 178 gr BTHP Match');
      expect(_text(tester, 'profile-powder-coef'), '');
      expect(_text(tester, 'profile-powder-temp'), '');

      // A typed value is the shooter's own: a pick does not clear it.
      await enterRifleField(tester, 'profile-powder-coef', '1,2');
      await enterRifleField(tester, 'profile-powder-temp', '18');
      await _pickHornady(tester, 'Precision Hunter 178 gr ELD-X');
      expect(_text(tester, 'profile-powder-coef'), '1,2');
      expect(_text(tester, 'profile-powder-temp'), '18');
    });

    testWidgets('only one of the pair shows an error', (tester) async {
      await _openNew(tester);
      await enterRifleField(tester, 'profile-powder-coef', '1,5');
      expect(find.text('Sıcaklığı da girin.'), findsNothing); // not yet shown
      await enterRifleField(tester, 'profile-powder-coef', '15');
      expect(find.text('-10 ile 10 arasında bir değer girin.'), findsOneWidget);
    });
  });
}
