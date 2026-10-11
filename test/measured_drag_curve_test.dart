// Ölçülmüş sürüklenme eğrileri (owner, 2026-10-11): a library bullet with a
// measured Cd–Mach curve uses it; every other bullet keeps its G1/G7 BC, and
// adding curves never changes a G1/G7 solution.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_curve.dart';
import 'package:sniper_turk/core/drag_table.dart';
import 'package:sniper_turk/data/bullet_library.dart';
import 'package:sniper_turk/data/measured_drag_curves.dart';
import 'package:sniper_turk/data/measured_drag_lookup.dart';
import 'package:sniper_turk/features/profiles/profiles_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/profile_store.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/rifle_form.dart';

/// Test-only curve (shape of a boat-tail match bullet); not real data.
const _fixture = MeasuredDragCurve(
  id: 'test-fixture',
  brand: 'Hornady',
  name: '30 Cal .308 168 gr ELD Match',
  grain: 168.0,
  method: 'test',
  sourceUrl: 'https://example.invalid/test',
  license: 'cc0-1.0',
  points: [
    [0.5, 0.150],
    [0.8, 0.156],
    [0.95, 0.240],
    [1.0, 0.330],
    [1.1, 0.345],
    [1.5, 0.310],
    [2.0, 0.275],
    [2.5, 0.250],
  ],
);

LibraryBullet _bullet(String name) =>
    BulletLibrary.all.firstWhere((b) => b.brand == 'Hornady' && b.name == name);

BallisticInput _input(LibraryBullet b, {MeasuredDragCurve? curve}) {
  final samples = curve?.samples;
  return BallisticInput(
    muzzleVelocityMps: 810,
    grain: b.grain,
    zeroRangeM: 100,
    sightHeightMm: 45,
    rangesM: const [300, 600, 1000],
    ballisticCoefficient: samples == null
        ? b.bc
        : DragCurve.sectionalDensity(grain: b.grain, diameterMm: b.diameterMm),
    ballisticModel: samples == null ? b.model : BallisticModel.g1,
    dragTable: samples == null ? null : DragTable(samples),
  );
}

Future<void> _pickEldMatch168(WidgetTester tester) async {
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
  await chooseInSelect(tester, 'profile-platform', 'Ateşli Tüfek');
  await chooseInSelect(tester, 'rifle-caliber', '.308 Win');
  await chooseInSelect(tester, 'ammo-source', 'El dolumu');
  await chooseInSelect(tester, 'ammo-brand-select', 'Hornady');
  await tester.tap(find.byKey(const Key('ammo-model-select')));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('168 gr ELD Match').last);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => MeasuredDragLookup.debugOverride = null);

  test('every shipped curve is valid, sourced and linked to the library', () {
    for (final c in measuredDragCurves) {
      final s = c.samples;
      expect(s, isNotNull, reason: c.id);
      expect(s!.first.mach, lessThanOrEqualTo(0.8), reason: c.id);
      expect(s.last.mach, greaterThanOrEqualTo(2.0), reason: c.id);
      expect(c.sourceUrl, startsWith('https://'), reason: c.id);
      expect(c.license, isNotEmpty, reason: c.id);
      expect(
        BulletLibrary.all.where(
          (b) =>
              b.brand == c.brand &&
              b.name == c.name &&
              (b.grain - c.grain).abs() < 0.01,
        ),
        isNotEmpty,
        reason: c.id,
      );
    }
  });

  test('lookup finds only the exact bullet', () {
    MeasuredDragLookup.debugOverride = const [_fixture];
    final eld = _bullet('30 Cal .308 168 gr ELD Match');
    expect(MeasuredDragLookup.forBullet(eld), same(_fixture));
    expect(
      MeasuredDragLookup.forBullet(_bullet('30 Cal .308 178 gr ELD Match')),
      isNull,
    );
    MeasuredDragLookup.debugOverride = null;
    // Without the override only shipped curves count.
    expect(
      MeasuredDragLookup.forBullet(eld) == null,
      !measuredDragCurves.any((c) => c.name == eld.name),
    );
  });

  test('the curve drives the solver; other bullets keep G1/G7 unchanged', () {
    const engine = BallisticEngine();
    final eld168 = _bullet('30 Cal .308 168 gr ELD Match');
    final eld178 = _bullet('30 Cal .308 178 gr ELD Match');

    // Baseline before any measured curve exists.
    MeasuredDragLookup.debugOverride = const [];
    final before178 = engine.solve(
      _input(eld178, curve: MeasuredDragLookup.forBullet(eld178)),
    );
    final g7of168 = engine.solve(
      _input(eld168, curve: MeasuredDragLookup.forBullet(eld168)),
    );

    MeasuredDragLookup.debugOverride = const [_fixture];
    final after178 = engine.solve(
      _input(eld178, curve: MeasuredDragLookup.forBullet(eld178)),
    );
    final curve168 = engine.solve(
      _input(eld168, curve: MeasuredDragLookup.forBullet(eld168)),
    );

    // G1/G7 fallback: identical, point by point.
    for (var i = 0; i < before178.length; i++) {
      expect(after178[i].dropM, before178[i].dropM);
      expect(after178[i].velocityMps, before178[i].velocityMps);
    }
    // The measured curve is what the solver used.
    final direct = engine.solve(_input(eld168, curve: _fixture));
    for (var i = 0; i < curve168.length; i++) {
      expect(curve168[i].dropM, direct[i].dropM);
    }
    expect((curve168.last.dropM - g7of168.last.dropM).abs(), greaterThan(0.01));
  });

  testWidgets('a library bullet with a measured curve fills the curve', (
    tester,
  ) async {
    MeasuredDragLookup.debugOverride = const [_fixture];
    await _pickEldMatch168(tester);
    expect(find.byKey(const Key('ammo-curve')), findsOneWidget);
    expect(find.byKey(const Key('ammo-bc')), findsNothing);
    expect(find.textContaining('8 nokta yüklendi'), findsOneWidget);
  });

  testWidgets('without a curve the library bullet keeps its G7 BC', (
    tester,
  ) async {
    MeasuredDragLookup.debugOverride = const [];
    await _pickEldMatch168(tester);
    expect(find.byKey(const Key('ammo-curve')), findsNothing);
    final bc = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('ammo-bc')),
        matching: find.byType(TextField),
      ),
    );
    expect(bc.controller!.text, '0,263');
    expect(find.byKey(const Key('ammo-bc-model-g7')), findsOneWidget);
  });
}
