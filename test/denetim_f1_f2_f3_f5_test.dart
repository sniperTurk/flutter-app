// Denetim düzeltmeleri F1, F2, F3 (2026-10-14): the edge cases next to the
// audit repros in test/audit_2026_10_14/findings_audit_test.dart.
// Report: docs/reports/denetim_duzeltmeleri_f1_f2_f3_f5.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/scope_dial.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _catalogPcp = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
);

const _fxRifle = <String, dynamic>{
  'id': 'f_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Denetim',
  'model': '308',
  'caliberMm': 7.82,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _fxAmmo = <String, dynamic>{
  'id': 'f_ammo_fx',
  'kind': 'ammo',
  'platform': 'firearm',
  'brand': 'Denetim 168',
  'model': '',
  'caliberMm': 7.82,
  'grain': 168,
  'ammoType': 'bullet',
  'bc': 0.462,
  'bcModel': 'g1',
};

RifleProfile _fx(AngularUnit unit) => RifleProfile(
  id: 'f-fx',
  name: 'FX',
  rifleId: 'f_rifle_fx',
  ammunitionId: 'f_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
  angularUnit: unit,
);

Widget _app(RifleProfile profile, BallisticsView view) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(
    body: BallisticsScreen(profile: profile, view: view),
  ),
);

Future<void> _big(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 3000) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<double> _density(
  WidgetTester tester, {
  required String pressure,
  required String altitude,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: BallisticsScreen(profile: _catalogPcp)),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(BallisticsFieldKeys.temperature), '15');
  await tester.enterText(find.byKey(BallisticsFieldKeys.humidity), '0');
  await tester.enterText(find.byKey(BallisticsFieldKeys.pressure), pressure);
  await tester.enterText(find.byKey(BallisticsFieldKeys.altitude), altitude);
  await tester.ensureVisible(find.text('DOPE oluştur'));
  await tester.tap(find.text('DOPE oluştur'));
  await tester.pumpAndSettle();
  final text = tester
      .widget<Text>(find.textContaining('Hava yoğunluğu:'))
      .data!;
  final m = RegExp(r'Hava yoğunluğu: ([\d,]+)').firstMatch(text)!;
  return double.parse(m.group(1)!.replaceAll(',', '.'));
}

/// Types İrtifa / Basınç on Hava Durumu, then opens Hedef (Atış).
Future<void> _shotWith(
  WidgetTester tester, {
  required String pressure,
  required String altitude,
}) async {
  await _big(tester);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_app(_catalogPcp, BallisticsView.all));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(BallisticsFieldKeys.pressure), pressure);
  await tester.enterText(find.byKey(BallisticsFieldKeys.altitude), altitude);
  await tester.pump();
  await tester.pumpWidget(_app(_catalogPcp, BallisticsView.shot));
  await tester.pumpAndSettle();
}

const _note = Key('shot-pressure-from-altitude');

void main() {
  group('F1 pressure from İrtifa', () {
    testWidgets('both empty: standard atmosphere, 1013,25 hPa', (
      tester,
    ) async {
      final rho = await _density(tester, pressure: '', altitude: '');
      expect(rho, closeTo(1.2250, 0.001));
    });

    testWidgets('İrtifa 0: the ISA estimate is 1013,25 hPa', (tester) async {
      final rho = await _density(tester, pressure: '', altitude: '0');
      expect(rho, closeTo(1.2250, 0.001));
    });

    testWidgets('negative İrtifa: denser than sea level (-400 m)', (
      tester,
    ) async {
      // ISA: 1062,2 hPa at -400 m → 1,2842 kg/m³ dry at 15 °C.
      final rho = await _density(tester, pressure: '', altitude: '-400');
      expect(rho, closeTo(1.2842, 0.001));
    });

    testWidgets('a typed pressure always wins over İrtifa', (tester) async {
      final rho = await _density(tester, pressure: '1013.25', altitude: '1500');
      expect(rho, closeTo(1.2250, 0.001));
    });

    testWidgets('Hedef says so only when the pressure was estimated', (
      tester,
    ) async {
      await _shotWith(tester, pressure: '', altitude: '1500');
      expect(find.byKey(_note), findsOneWidget);
      expect(find.text('Basınç irtifadan tahmin edildi.'), findsOneWidget);

      await _shotWith(tester, pressure: '845', altitude: '1500');
      expect(find.byKey(_note), findsNothing);

      await _shotWith(tester, pressure: '', altitude: '');
      expect(find.byKey(_note), findsNothing);
    });
  });

  group('F2 turret travel with the zero angle', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_fxRifle, _fxAmmo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Future<ScopeDialView> view(WidgetTester tester, RifleProfile p) async {
      await _big(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(p, BallisticsView.pro));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(p, BallisticsView.shot));
      await tester.pumpAndSettle();
      return tester.widget<ScopeDialView>(find.byType(ScopeDialView));
    }

    testWidgets('MRAD and MOA turrets take the same angle off UP', (
      tester,
    ) async {
      final mrad = await view(tester, _fx(AngularUnit.mrad));
      final moa = await view(tester, _fx(AngularUnit.moa));
      for (final v in [mrad, moa]) {
        final half = v.halfElevationClicks!;
        expect(v.zeroAngleClicks, greaterThan(0));
        expect(v.maxElevationClicks, half - v.zeroAngleClicks);
        expect(v.maxElevationDownClicks, half + v.zeroAngleClicks);
      }
      // Same angle in both units, to within one click of each.
      final aMrad = mrad.zeroAngleClicks * mrad.clickValue;
      final aMoa = AngularUnit.moa.toMrad(moa.zeroAngleClicks * moa.clickValue);
      expect(aMoa, closeTo(aMrad, mrad.clickValue + moa.clickValue / 3.4));
      // .308 800 m/s, 45 mm, 100 m zero: ≈ 1,26 mrad (13 clicks).
      expect(mrad.zeroAngleClicks, 13);
      expect(mrad.maxElevationClicks, 117);
    });

    test('the zero angle is the solver\'s own (vacuum closed form)', () {
      final input = BallisticInput(
        muzzleVelocityMps: 800,
        grain: 168,
        zeroRangeM: 100,
        sightHeightMm: 45,
        rangesM: const [100],
      );
      // Low root of A·u² − x·u + (s + A) = 0, A = g·x²/2v²: 1,2161 mrad.
      expect(
        const BallisticEngine().zeroAngleMrad(input),
        closeTo(1.2161, 0.0005),
      );
      // G1 0,462: tools/formul_denetimi_2026_10_14.py zero_angle → 1,2601.
      final drag = BallisticInput(
        muzzleVelocityMps: 800,
        grain: 168,
        zeroRangeM: 100,
        sightHeightMm: 45,
        rangesM: const [100],
        ballisticCoefficient: 0.462,
        ballisticModel: BallisticModel.g1,
      );
      expect(
        const BallisticEngine().zeroAngleMrad(drag),
        closeTo(1.2601, 0.005),
      );
    });

    Widget dial({required int mount, required int zero}) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScopeDialView(
            unit: AngularUnit.mrad,
            clickValue: 0.1,
            elevationClicks: 0,
            windageClicks: 0,
            maxElevationClicks: 130 + mount - zero,
            maxElevationDownClicks: 130 - mount + zero,
            mountCantMoa: 60,
            mountCantClicks: mount,
            zeroAngleClicks: zero,
            travelKnown: true,
            halfElevationClicks: 130,
            maxWindageClicks: 120,
            onElevationChanged: (_) {},
            onWindageChanged: (_) {},
            requiredUp: 1,
            firstFocalPlane: true,
            rangeM: 200,
            samples: const [],
            toDisplayRange: (m) => m,
            distanceUnit: 'm',
            metric: true,
          ),
        ),
      ),
    );

    testWidgets('a mount blocks the zero only beyond half travel + zero', (
      tester,
    ) async {
      await _big(tester);
      // 60 MOA = 174 clicks of 0.1 mrad; half travel 130.
      await tester.pumpWidget(dial(mount: 174, zero: 41));
      expect(
        tester.widget<ScopeDialView>(find.byType(ScopeDialView)).mountBlocksZero,
        isTrue,
      );
      expect(find.byKey(ScopeDialKeys.mountZeroNote), findsOneWidget);
      await tester.pumpWidget(dial(mount: 174, zero: 44));
      expect(
        tester.widget<ScopeDialView>(find.byType(ScopeDialView)).mountBlocksZero,
        isFalse,
      );
      expect(find.byKey(ScopeDialKeys.mountZeroNote), findsNothing);
    });

    test('mount clicks themselves are unchanged (0 / 20 / 30 MOA)', () {
      expect(ScopeDialMath.mountCantClicks(0, 0.1, AngularUnit.mrad), 0);
      expect(ScopeDialMath.mountCantClicks(20, 0.1, AngularUnit.mrad), 58);
      expect(ScopeDialMath.mountCantClicks(30, 0.1, AngularUnit.mrad), 87);
      expect(ScopeDialMath.mountCantClicks(20, 0.25, AngularUnit.moa), 80);
    });
  });
}
