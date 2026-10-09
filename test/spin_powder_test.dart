// Spin drift (Litz) and powder temperature sensitivity on Pro Ayarlar
// (owner, 2026-10-09), plus the zero-day velocity in the solvers.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/data/catalog_repository.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _rifle = <String, dynamic>{
  'id': 'manual_rifle_fx',
  'kind': 'rifle',
  'platform': 'firearm',
  'brand': 'Test',
  'model': '308',
  'caliberMm': 7.62,
  'barrelLengthMm': 600,
  'twistDirection': 'right',
  'twistRateIn': 10,
};
const _ammo = <String, dynamic>{
  'id': 'manual_ammo_fx',
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
  id: 'p-fx',
  name: 'FX',
  rifleId: 'manual_rifle_fx',
  ammunitionId: 'manual_ammo_fx',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 800,
  zeroRangeM: 100,
  sightHeightMm: 45,
);

BallisticInput _input({double v = 800, double? zeroV, double range = 100}) =>
    BallisticInput(
      muzzleVelocityMps: v,
      grain: 168,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: [range],
      ballisticCoefficient: 0.462,
      ballisticModel: BallisticModel.g1,
      zeroMuzzleVelocityMps: zeroV,
    );

void main() {
  group('zero-day velocity', () {
    const engine = BallisticEngine();
    test('same as today changes nothing', () {
      final a = engine.solve(_input(range: 500)).single;
      final b = engine.solve(_input(range: 500, zeroV: 800)).single;
      expect(b.correctionMrad, closeTo(a.correctionMrad, 1e-12));
    });
    test('a faster day hits high at the zero range', () {
      final p = engine.solve(_input(v: 820, zeroV: 800)).single;
      // Correction < 0 = dial down: the impact is above the aim point.
      expect(p.correctionMrad, lessThan(-0.01));
      final q = engine.solve(_input(v: 820)).single;
      expect(q.correctionMrad, closeTo(0, 1e-3));
    });
    test('vacuum honours it too', () {
      final p = engine
          .vacuumDope(
            muzzleVelocityMps: 820,
            grain: 168,
            zeroRangeM: 100,
            sightHeightMm: 45,
            rangesM: const [100],
            zeroVelocityMps: 800,
          )
          .single;
      expect(p.correctionMrad, lessThan(0));
    });
  });

  group('Pro: spin drift and powder temperature', () {
    setUp(
      () => CatalogRepository.installUserCatalog(
        UserCatalog.fromManualEntries([_rifle, _ammo]),
      ),
    );
    tearDown(() => CatalogRepository.installUserCatalog(UserCatalog.empty));

    Widget app(BallisticsView view) => MaterialApp(
      theme: MenzilTheme.light(),
      home: Scaffold(
        body: BallisticsScreen(profile: _profile, view: view),
      ),
    );

    Future<void> type(WidgetTester tester, Key key, String v) async {
      final f = find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(f);
      await tester.enterText(f, v);
      await tester.pump();
    }

    testWidgets('right twist drifts right; the turret dials left', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final off = tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredRight;

      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      final sw = find.byKey(const Key('pro-spin-switch'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-bullet-length'), '31');

      await tester.pumpWidget(app(BallisticsView.shot));
      await tester.pumpAndSettle();
      final on = tester
          .widget<ScopeDialView>(find.byType(ScopeDialView))
          .requiredRight;
      expect(on, lessThan(off)); // more LEFT
      final note = tester
          .widget<Text>(find.byKey(const Key('shot-spin-drift')))
          .data!;
      expect(note, contains('sağa'));
      // Litz at 100 m (~0.13 s) for a .308 168 gr: a few millimetres.
      final cm = double.parse(
        RegExp(r'([\d.]+) cm').firstMatch(note)!.group(1)!,
      );
      expect(cm, inInclusiveRange(0.05, 3));
    });

    testWidgets('a warmer day raises today\'s velocity', (tester) async {
      tester.view.physicalSize = const Size(430, 3000) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(BallisticsView.environment));
      await tester.pumpAndSettle();
      await type(tester, BallisticsFieldKeys.temperature, '35');
      await tester.pumpWidget(app(BallisticsView.pro));
      await tester.pumpAndSettle();
      await type(tester, const Key('pro-powder-coef'), '1,5');
      await type(tester, const Key('pro-powder-temp'), '20');
      // 15 °C warmer at 1.5 %/15 °C: 800 m/s -> 812 m/s = 2664 fps.
      final today = tester
          .widget<Text>(find.byKey(const Key('pro-powder-today')))
          .data!;
      expect(
        today,
        contains('${(812 * 3.280839895).toStringAsFixed(0)} fps'),
      );
    });
  });
}
