// Mühimmat sıcaklığı (Ö1, 2026-10-12): on a firearm the powder temperature
// correction uses the cartridge's own temperature when it is entered, the
// air temperature otherwise (the behaviour before). Without a powder
// coefficient on the profile nothing is corrected at all.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/environment_field_info.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_at',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_at',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Test 168',
  'model': '',
  'caliberMm': 7.62,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

RifleProfile _firearm({double? coef, double? refC}) => RifleProfile(
  id: 'p-at',
  name: 'AT',
  rifleId: 'manual_rifle_at',
  ammunitionId: 'manual_ammo_at',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: coef,
  powderTempReferenceC: refC,
);

const _pcp = RifleProfile(
  id: 'p-pcp',
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _ammoKey = Key('env-ammo-temp');

void main() {
  group('PowderTemperature.effectiveTempC', () {
    test('the ammunition temperature replaces the air when valid', () {
      expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: 33), 33);
      expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: null), 18);
      expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: 75), 18);
      expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: -51), 18);
      expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: double.nan), 18);
    });
  });

  group('ShotSettings.ammoTempText', () {
    test('round trip; an older save has none', () {
      final s = ShotSettings.fromJson(
        jsonDecode(
          jsonEncode(const ShotSettings(ammoTempText: '32,5').toJson()),
        ),
      );
      expect(s.ammoTempText, '32,5');
      expect(ShotSettings.fromJson(const {'sd': '9'}).ammoTempText, '');
    });
  });

  test('the ⓘ text says what, where, that it needs a coefficient', () {
    const t = EnvironmentFieldInfo.ammoTemperature;
    expect(t, contains('katsayı'));
    expect(t, contains('hava sıcaklığı'));
    expect(t, contains('Örnek'));
  });

  // The box is on Pro > Tüfek düzeltmeleri since 2026-10-16 (owner, design
  // PR #366); it was on Hava Durumu before. Behaviour unchanged.
  group('Pro Ayarlar', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_rifle, _ammo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Widget app(RifleProfile p, BallisticsView view) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: p, view: view),
      ),
    );

    Future<void> sized(WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<void> type(WidgetTester tester, Key key, String v) async {
      await openProFor(tester, key);
      final f = find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(f);
      await tester.enterText(f, v);
      await tester.pump();
    }

    /// The elevation the scope needs at 600 m with the current inputs.
    Future<double> up600(WidgetTester tester, RifleProfile p) async {
      await tester.pumpWidget(app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-shot-range'), '600');
      await tester.pumpWidget(app(p, BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredUp!;
    }

    /// Where the box lives: Pro Ayarlar (Tüfek düzeltmeleri opened by
    /// [type] / [openProFor]).
    Future<void> environment(WidgetTester tester, RifleProfile p) async {
      await tester.pumpWidget(app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
    }

    testWidgets('firearm: in Pro Tüfek düzeltmeleri, not on Hava Durumu; '
        'not on PCP', (tester) async {
      await sized(tester);
      await tester.pumpWidget(app(_firearm(), BallisticsView.environment));
      await tester.pumpAndSettle();
      expect(find.byKey(_ammoKey), findsNothing);
      expect(find.text('Mühimmat sıcaklığı'), findsNothing);

      await environment(tester, _firearm());
      await openProFor(tester, _ammoKey);
      expect(find.byKey(_ammoKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(_ammoKey),
          matching: find.text('Mühimmat sıcaklığı'),
        ),
        findsOneWidget,
      );
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(_ammoKey),
          matching: find.byType(TextField),
        ),
      );
      expect(field.decoration?.hintText, isNull);
      expect(field.decoration?.helperText, isNull);

      await tester.pumpWidget(const SizedBox());
      await environment(tester, _pcp);
      await openProFor(tester, _ammoKey);
      expect(find.byKey(_ammoKey), findsNothing);
      await tester.pumpWidget(app(_pcp, BallisticsView.environment));
      await tester.pumpAndSettle();
      expect(find.byKey(_ammoKey), findsNothing);
    });

    testWidgets('no coefficient: the field changes nothing', (tester) async {
      await sized(tester);
      final p = _firearm();
      final before = await up600(tester, p);
      await environment(tester, p);
      await type(tester, _ammoKey, '45');
      expect(await up600(tester, p), before);
    });

    testWidgets('with a coefficient: empty is the air temperature, a warm '
        'cartridge shoots flatter', (tester) async {
      await sized(tester);
      final p = _firearm(coef: 1.5, refC: 15);
      // Air 15 °C = reference: no correction, the result of before.
      final plain = await up600(tester, p);
      await environment(tester, p);
      await type(tester, _ammoKey, '15');
      expect(await up600(tester, p), plain);
      await environment(tester, p);
      await type(tester, _ammoKey, '35');
      final warm = await up600(tester, p);
      expect(warm, lessThan(plain));
      await environment(tester, p);
      await type(tester, _ammoKey, '');
      expect(await up600(tester, p), plain);
    });

    testWidgets('a value written by Kronograf reaches the open workspace '
        'and is not overwritten', (tester) async {
      await sized(tester);
      final p = _firearm();
      await tester.pumpWidget(app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
      const store = ShotSettingsStore();
      await store.save(p.id, const ShotSettings(sdText: '16,4'));
      ShotSettingsStore.notifyExternalWrite();
      await tester.pumpAndSettle();
      await openProFor(tester, const Key('pro-sd'));
      final sd = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('pro-sd')),
          matching: find.byType(TextField),
        ),
      );
      expect(sd.controller!.text, '16,4');
      // A later edit in the workspace keeps the new SD.
      await environment(tester, p);
      await type(tester, _ammoKey, '30');
      await tester.pumpAndSettle();
      expect((await store.load(p.id))!.sdText, '16,4');
    });

    testWidgets('the value is kept per profile', (tester) async {
      await sized(tester);
      final p = _firearm(coef: 1.5, refC: 15);
      await environment(tester, p);
      await type(tester, _ammoKey, '32');
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(ShotSettingsStore.keyFor(p.id))!;
      expect((jsonDecode(raw) as Map)['ammoTemp'], '32');

      await tester.pumpWidget(const SizedBox());
      await environment(tester, p);
      await openProFor(tester, _ammoKey);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(_ammoKey),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '32');
    });
  });
}
