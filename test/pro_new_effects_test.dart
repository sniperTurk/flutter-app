// Rüzgâr bölgeleri, aerodinamik sıçrama, sıfır ofseti and isabet olasılığı
// (owner, 2026-10-09).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/pro_sections.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_nx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_nx',
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
const _profile = RifleProfile(
  id: 'p-nx',
  name: 'NX',
  rifleId: 'manual_rifle_nx',
  ammunitionId: 'manual_ammo_nx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

BallisticInput _input({WindZones? zones}) => BallisticInput(
  muzzleVelocityMps: 800,
  grain: 168,
  zeroRangeM: 100,
  sightHeightMm: 45,
  rangesM: const [600],
  ballisticCoefficient: 0.462,
  ballisticModel: BallisticModel.g1,
  environment: const EnvironmentData(windMps: 2, windDirectionDeg: 90),
  windZones: zones,
);

void main() {
  group('Rüzgâr bölgeleri (solver)', () {
    const engine = BallisticEngine();
    test('zones equal to the shooter wind change nothing', () {
      final a = engine.solve(_input()).single;
      final b = engine
          .solve(
            _input(zones: const WindZones(rangeM: 600, midMps: 2, farMps: 2)),
          )
          .single;
      expect(b.windMrad, closeTo(a.windMrad, 1e-12));
    });

    test('a stronger wind at the target drifts more', () {
      final a = engine.solve(_input()).single;
      final b = engine
          .solve(
            _input(zones: const WindZones(rangeM: 600, midMps: 2, farMps: 6)),
          )
          .single;
      expect(b.windMrad.abs(), greaterThan(a.windMrad.abs()));
    });
  });

  group('Pro → Hedef', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_rifle, _ammo]),
      );
    });
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Widget app(BallisticsView view) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: _profile, view: view),
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

    ScopeDialView dial(WidgetTester tester) =>
        tester.widget<ScopeDialView>(find.byType(ScopeDialView));

    testWidgets('sıfır ofseti: a high group needs less up, a right one '
        'more left', (tester) async {
      await sized(tester);
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final before = dial(tester);

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      // 1 cm high and 1 cm right at 100 m = 0.1 mrad each.
      await type(tester, const Key('pro-zero-up'), '1');
      await type(tester, const Key('pro-zero-right'), '1');
      expect(
        tester.widget<Text>(find.byKey(const Key('pro-summary-angle'))).data,
        'düz',
      );

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final after = dial(tester);
      final d = before.unit.fromMrad(0.1);
      expect(before.requiredUp! - after.requiredUp!, closeTo(d, 1e-3));
      expect(before.requiredRight - after.requiredRight, closeTo(d, 1e-3));
    });

    testWidgets('Pro distance: Hedef opens there, dialled, right turret open', (
      tester,
    ) async {
      await sized(tester);
      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      // The distance box sits above the closed boxes, always visible.
      final f = find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      );
      expect(f, findsOneWidget);
      expect(find.byKey(const Key('pro-range-map')), findsOneWidget);
      await tester.enterText(f, '300');
      await tester.pump();

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final d = dial(tester);
      expect(d.rangeM, closeTo(300, 1e-9));
      // 300 m with a 100 m zero: the solution is dialled up already.
      expect(d.elevationClicks, greaterThan(0));
      expect(find.byKey(const ValueKey('windage-open')), findsOneWidget);
      expect(find.text('Vuruş noktası: artı işaretinde'), findsOneWidget);
    });

    testWidgets('DOPE kartı: the button builds a PDF and hands it to share', (
      tester,
    ) async {
      await sized(tester);
      List<int>? pdf;
      String? name;
      BallisticsScreenTestHooks.sharePdf = (bytes, file) async {
        pdf = bytes;
        name = file;
      };
      addTearDown(() => BallisticsScreenTestHooks.sharePdf = null);
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final button = find.byKey(const Key('shot-dope-pdf'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(button);
        for (var i = 0; i < 50 && pdf == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pump();
      expect(pdf, isNotNull);
      expect(String.fromCharCodes(pdf!.take(4)), '%PDF');
      expect(name, endsWith('.pdf'));
    });

    testWidgets('isabet olasılığı appears once a group size is given', (
      tester,
    ) async {
      await sized(tester);
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shot-hit-probability')), findsNothing);

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-group'), '2');
      await type(tester, const Key('pro-sd'), '10');

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final text = tester
          .widget<Text>(find.byKey(const Key('shot-hit-probability')))
          .data!;
      final pct = int.parse(RegExp(r'%(\d+)').firstMatch(text)!.group(1)!);
      // 2 cm group vs a 10 cm ring at 100 m: almost always a hit.
      expect(pct, greaterThan(90));
    });

    testWidgets('Yerçekimi: stronger gravity drops more, off = standard', (
      tester,
    ) async {
      await sized(tester);
      // At the zero range gravity changes nothing; look at 600 m.
      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('pro-shot-range')),
          matching: find.byType(TextField),
        ),
        '600',
      );
      await tester.pump();
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final before = dial(tester).requiredUp!;

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      // The summary shows only while the box is closed.
      expect(
        tester.widget<Text>(find.byKey(const Key('pro-summary-gravity'))).data,
        'kapalı',
      );
      await openProFor(tester, const Key('pro-gravity-switch'));
      final sw = find.byKey(const Key('pro-gravity-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-gravity'), '9.832');
      await tester.pumpAndSettle();
      final effect = tester
          .widget<Text>(find.byKey(const Key('pro-gravity-effect')))
          .data!;
      expect(effect, contains('daha çok'));

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      expect(dial(tester).requiredUp!, greaterThan(before));
    });

    testWidgets('a crosswind from the left drops a right-twist bullet', (
      tester,
    ) async {
      await sized(tester);
      await tester.pumpWidget(app(BallisticsView.environment));
      await tester.pumpAndSettle();
      final wind = find.descendant(
        of: find.byKey(BallisticsFieldKeys.wind),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(wind);
      await tester.enterText(wind, '5');
      await tester.pump();

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      await openProFor(tester, const Key('pro-spin-switch'));
      // A firearm profile sees powder temperature, not the PCP note.
      expect(find.byKey(const Key('pro-powder-coef')), findsOneWidget);
      expect(find.byKey(const Key('pro-spin-pcp-note')), findsNothing);
      final sw = find.byKey(const Key('pro-spin-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-bullet-length'), '31');

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final note = tester
          .widget<Text>(find.byKey(const Key('shot-spin-drift')))
          .data!;
      expect(note, contains('rüzgâr sıçraması'));
      expect(note, contains('aşağı'));
    });
  });
}
