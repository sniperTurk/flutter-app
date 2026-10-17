// Denetim 2026-10-17 (TestFlight öncesi uçtan uca hesap denetimi), main
// 9db11e3 vs TestFlight 110 (e7b29bf): #369, #370, #371, #372, #373.
// Report: docs/reports/denetim_2026_10_17.md. These tests stay in the suite
// as regression guards (CLAUDE.md). References are hand calculations:
//  - powder temperature: v = v0 · (1 + k/100 · (T − T0) / 15), the linear
//    "% per 15 °C" sensitivity of lib/core/powder_temperature.dart, with
//    the ICAO standard atmosphere 15 °C as the default air temperature;
//  - clicks = round(angle / click value).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/powder_temperature.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/shot_settings_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import '../support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_d17',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_d17',
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

RifleProfile _firearm({
  String id = 'p-d17',
  double mv = 800,
  double? coef,
  double? refC,
}) => RifleProfile(
  id: id,
  name: 'D17',
  rifleId: 'manual_rifle_d17',
  ammunitionId: 'manual_ammo_d17',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: mv,
  zeroRangeM: 100,
  sightHeightMm: 45,
  powderTempCoefPercentPer15C: coef,
  powderTempReferenceC: refC,
);

RifleProfile _pcp(String id) => RifleProfile(
  id: id,
  name: 'PCP',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _ammoKey = Key('env-ammo-temp');

Widget _app(RifleProfile p, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: p, view: view),
  ),
);

Future<void> _sized(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _type(WidgetTester tester, Key key, String v) async {
  await openProFor(tester, key);
  final f = find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(f);
  await tester.enterText(f, v);
  await tester.pump();
}

/// Types the air temperature on Hava Durumu, then opens Pro at the
/// "Bugünkü hız" line's box.
Future<void> _air(WidgetTester tester, RifleProfile p, String v) async {
  await tester.pumpWidget(_app(p, BallisticsView.environment));
  await tester.pumpAndSettle();
  await _type(tester, BallisticsFieldKeys.temperature, v);
  await tester.pumpWidget(_app(p, BallisticsView.pro));
  await tester.pumpAndSettle();
  await openProFor(tester, const Key('pro-powder-source'));
}

String? _today(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('pro-powder-today'))).data;

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

/// Required elevation at [range] m; [ammo] typed into Pro > Tüfek
/// düzeltmeleri > Mühimmat sıcaklığı first when given.
Future<double> _up(
  WidgetTester tester,
  RifleProfile p, {
  String? ammo,
  String range = '600',
}) async {
  await tester.pumpWidget(_app(p, BallisticsView.pro));
  await tester.pumpAndSettle();
  if (ammo != null) {
    await _type(tester, _ammoKey, ammo);
    await tester.pumpAndSettle();
  }
  await _type(tester, const Key('pro-shot-range'), range);
  await tester.pumpWidget(_app(p, BallisticsView.shot));
  await tester.pumpAndSettle();
  return _dial(tester).requiredUp!;
}

void main() {
  group('D17 Mühimmat sıcaklığı (Pro > Tüfek düzeltmeleri, #370)', () {
    test('hand reference: 1,5 %/15 °C, T0 15 °C, 35 °C → ×1,02', () {
      // 1 + 1.5/100 · (35 − 15)/15 = 1.02 → 800 m/s · 1.02 = 816 m/s.
      final f = PowderTemperature.factor(
        coefPercentPer15C: 1.5,
        referenceTempC: 15,
        todayTempC: PowderTemperature.effectiveTempC(airC: 15, ammoC: 35),
      );
      expect(f, closeTo(1.02, 1e-12));
      expect(800 * f, closeTo(816, 1e-9));
      // Empty → the air temperature (15 °C = T0): no correction.
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1.5,
          referenceTempC: 15,
          todayTempC: PowderTemperature.effectiveTempC(airC: 15),
        ),
        1,
      );
      // Cold: 1 + 1.5/100 · (−5 − 15)/15 = 0.98.
      expect(
        PowderTemperature.factor(
          coefPercentPer15C: 1.5,
          referenceTempC: 15,
          todayTempC: PowderTemperature.effectiveTempC(airC: 15, ammoC: -5),
        ),
        closeTo(0.98, 1e-12),
      );
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_rifle, _ammo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    // The zero stays solved with the zeroing-day velocity (800 m/s) and
    // only the shot uses today's velocity (ballistics_screen.dart:2026-2041),
    // so the shown velocity is the number checked against the hand value.
    testWidgets('35 °C typed in Pro: velocity 816 m/s = 2677 fps', (
      tester,
    ) async {
      await _sized(tester);
      final p = _firearm(coef: 1.5, refC: 15);
      final plain = await _up(tester, p);
      final warm = await _up(tester, p, ammo: '35');
      // A warmer cartridge is faster: less elevation at 600 m.
      expect(warm, lessThan(plain));
      // 816 / 0.3048 = 2677.2 fps; 800 / 0.3048 = 2624.7 fps. The line
      // needs a typed air temperature (D17-1); 15 °C = T0, so only the
      // cartridge temperature moves the velocity.
      await _air(tester, p, '15');
      expect(_today(tester), 'Bugünkü hız: 2677 fps (profil 2625 fps).');
      // Same shot as with the air box empty (both 15 °C).
      expect(await _up(tester, p), closeTo(warm, 1e-9));
    });

    testWidgets('D17-1: with the air box empty a typed cartridge temperature '
        'still shows today\'s velocity', (tester) async {
      await _sized(tester);
      final p = _firearm(id: 'p-d17-1', coef: 1.5, refC: 15);
      await tester.pumpWidget(_app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
      await _type(tester, _ammoKey, '35');
      await tester.pumpAndSettle();
      // The solver uses 816 m/s here (air empty = 15 °C); the line is
      // missing because it needs a typed air temperature.
      expect(find.byKey(const Key('pro-powder-today')), findsOneWidget);
    }, skip: true); // D17-1 open (DÜŞÜK): pro_ayarlar_view.dart:760

    testWidgets('empty → air temperature: same as no correction at T0', (
      tester,
    ) async {
      await _sized(tester);
      final empty = await _up(tester, _firearm(coef: 1.5, refC: 15));
      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({});
      final plain = await _up(tester, _firearm(id: 'p-d17-plain'));
      expect(empty, closeTo(plain, 1e-9));
    });

    testWidgets('a value saved before the move (old install) loads into the '
        'Pro box and gives the same result as typing it', (tester) async {
      await _sized(tester);
      final p = _firearm(id: 'p-d17-old', coef: 1.5, refC: 15);
      // TestFlight 110 saved the box under the same key ('ammoTemp', °C).
      await const ShotSettingsStore().save(
        p.id,
        const ShotSettings(ammoTempText: '35'),
      );
      await tester.pumpWidget(_app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, _ammoKey);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(_ammoKey),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '35');
      final loaded = await _up(tester, p);
      await _air(tester, p, '15');
      expect(_today(tester), 'Bugünkü hız: 2677 fps (profil 2625 fps).');

      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({});
      final typed = await _up(
        tester,
        _firearm(id: 'p-d17-typed', coef: 1.5, refC: 15),
        ammo: '35',
      );
      expect(loaded, closeTo(typed, 1e-9));
    });

    testWidgets('PCP: a saved cartridge temperature changes nothing and '
        'there is no box', (tester) async {
      await _sized(tester);
      final a = _pcp('p-d17-pcp-a');
      final plain = await _up(tester, a, range: '50');
      final b = _pcp('p-d17-pcp-b');
      await const ShotSettingsStore().save(
        b.id,
        const ShotSettings(ammoTempText: '45'),
      );
      await tester.pumpWidget(const SizedBox());
      final saved = await _up(tester, b, range: '50');
      expect(saved, closeTo(plain, 1e-12));
      await tester.pumpWidget(_app(b, BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, _ammoKey);
      expect(find.byKey(_ammoKey), findsNothing);
      await tester.pumpWidget(_app(b, BallisticsView.environment));
      await tester.pumpAndSettle();
      expect(find.byKey(_ammoKey), findsNothing);
    });
  });

  group('D17 Hedef kompakt klik satırı (#370)', () {
    Future<void> row(
      WidgetTester tester, {
      required double up,
      required double right,
      bool calm = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MenzilTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: TurretSolutionRow(
                requiredUp: up,
                requiredRight: right,
                clickValue: 0.1,
                unit: AngularUnit.mrad,
                windCalm: calm,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('clicks and directions = round(angle / 0,1 MRAD)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      // 1,23 / 0,1 = 12,3 → 12 up; −0,34 / 0,1 = −3,4 → 3 left.
      await row(tester, up: 1.23, right: -0.34);
      expect(ScopeDialMath.clicksFor(1.23, 0.1), 12);
      expect(ScopeDialMath.clicksFor(-0.34, 0.1), -3);
      expect(
        find.text('Üst kule 12 klik yukarı', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Yan kule 3 klik sol', findRichText: true),
        findsOneWidget,
      );
      // The required MRAD angle is kept for VoiceOver (it was the visible
      // third line before #370; see report G-1).
      expect(
        find.bySemanticsLabel('Üst kule 12 klik, 1,2 MRAD yukarı'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Yan kule 3 klik, 0,3 MRAD sol'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('down, right, zero and calm', (tester) async {
      await row(tester, up: -0.56, right: 0.26);
      // −5,6 → −6 down; 2,6 → 3 right.
      expect(
        find.text('Üst kule 6 klik aşağı', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Yan kule 3 klik sağ', findRichText: true),
        findsOneWidget,
      );
      await row(tester, up: 0.02, right: 0, calm: true);
      expect(find.text('Üst kule 0 klik', findRichText: true), findsOneWidget);
      expect(
        find.text('Yan kule 0 klik rüzgâr yok', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
