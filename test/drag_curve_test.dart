import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/core/ballistic_engine.dart';
import 'package:sniper_turk/core/ballistic_input.dart';
import 'package:sniper_turk/core/drag_curve.dart';
import 'package:sniper_turk/core/drag_table.dart';
import 'package:sniper_turk/core/standard_drag_tables.dart';
import 'package:sniper_turk/data/user_catalog.dart';
import 'package:sniper_turk/features/profiles/drag_curve_field.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

const _csv = '''Mach,Cd
0.0,0.230
0.5,0.228
0.9,0.240
1.0,0.390
1.2,0.370
2.0,0.300
3.0,0.250
''';

// Lapua/QuickTARGET style: a text header, then "Cd Mach" per line.
const _drg = '''CFM Lapua 6.5 mm Scenar 139 gr
0.2300 0.000
0.2280 0.500
0.2400 0.900
0.3900 1.000
0.3700 1.200
0.3000 2.000
0.2500 3.000
''';

void main() {
  group('DragCurve.parse', () {
    test('CSV with Mach first and a header line', () {
      final c = DragCurve.parse(_csv);
      expect(c.length, 7);
      expect(c.first.mach, 0);
      expect(c[3].coefficient, closeTo(0.39, 1e-9));
    });

    test('.drg with Cd first is detected', () {
      final c = DragCurve.parse(_drg);
      expect(c.length, 7);
      expect(c.last.mach, 3);
      expect(c.last.coefficient, closeTo(0.25, 1e-9));
    });

    test('decimal comma with semicolons, unsorted input', () {
      final c = DragCurve.parse(
        '1,2;0,37\n0,0;0,23\n0,5;0,228\n2,0;0,30\n0,9;0,24\n',
      );
      expect([for (final p in c) p.mach], [0, 0.5, 0.9, 1.2, 2.0]);
    });

    test('too few points or a short curve is refused in Turkish', () {
      expect(
        () => DragCurve.parse('0 0.2\n1 0.3\n'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('En az'),
          ),
        ),
      );
      expect(
        () => DragCurve.parse('0 0.2\n0.2 0.2\n0.4 0.2\n0.6 0.2\n0.8 0.3\n'),
        throwsFormatException,
      );
    });

    test('JSON round trip', () {
      final c = DragCurve.parse(_csv);
      expect(DragCurve.fromJson(DragCurve.toJson(c))!.length, c.length);
      expect(
        DragCurve.fromJson([
          [0, 0.2],
        ]),
        isNull,
      );
    });
  });

  test('sectional density of a 168 gr .308', () {
    expect(
      DragCurve.sectionalDensity(grain: 168, diameterMm: 7.82),
      closeTo(0.253, 0.001),
    );
  });

  test('the G1 curve scaled by SD/BC reproduces the G1 solution', () {
    const bc = 0.462, grain = 168.0;
    final sd = DragCurve.sectionalDensity(grain: grain, diameterMm: 7.82);
    final own = DragTable([
      for (final s in StandardDragTables.g1.samples)
        DragSample(s.mach, s.coefficient * sd / bc),
    ]);
    BallisticInput input({DragTable? table}) => BallisticInput(
      muzzleVelocityMps: 800,
      grain: grain,
      zeroRangeM: 100,
      sightHeightMm: 45,
      rangesM: const [600],
      ballisticCoefficient: table == null ? bc : sd,
      ballisticModel: BallisticModel.g1,
      dragTable: table,
    );
    const engine = BallisticEngine();
    final g1 = engine.solve(input()).single;
    final custom = engine.solve(input(table: own)).single;
    expect(custom.dropM, closeTo(g1.dropM, 1e-6));
    expect(custom.velocityMps, closeTo(g1.velocityMps, 1e-6));
    // The table survives the copy helpers.
    expect(input(table: own).withRanges(const [300]).dragTable, same(own));
  });

  test('a stored curve reaches the ammunition record', () {
    final catalog = UserCatalog.fromManualEntries([
      {
        'id': 'a1',
        'kind': 'ammo',
        'platform': 'firearm',
        'brand': 'Lapua Scenar',
        'model': '',
        'caliberMm': 6.71,
        'grain': 139,
        'ammoType': 'bullet',
        'bc': 0.28,
        'bcModel': 'g1',
        'dragCurve': DragCurve.toJson(DragCurve.parse(_csv)),
      },
    ]);
    final a = catalog.ammunition.single;
    expect(a.dragCurve!.length, 7);
    expect(a.dragTable, isNotNull);
  });

  testWidgets('DragCurveField loads a file and shows the point count', (
    tester,
  ) async {
    List<DragSample>? got;
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DragCurveField(
              curve: got,
              readFile: () async => _drg,
              onChanged: (v) => setState(() => got = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ammo-curve-file')));
    await tester.pumpAndSettle();
    expect(got!.length, 7);
    expect(find.byKey(const Key('ammo-curve-chart')), findsOneWidget);
    expect(find.textContaining('7 nokta yüklendi'), findsOneWidget);
  });

  testWidgets('a bad file shows the reason', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.dark(),
        home: Scaffold(
          body: DragCurveField(
            curve: null,
            readFile: () async => 'merhaba',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('ammo-curve-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ammo-curve-error')), findsOneWidget);
  });
}
