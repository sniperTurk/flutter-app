// Hedef'te sonuç en üstte (owner, 2026-10-15 12:50: "Hedef'te sonuç en
// üstte… çok haklısın"). Under the distance slider and above the reticle
// card: "Üst kule N klik" / "X MOA yukarı" and "Yan kule N klik" / "X sağ"
// or "rüzgâr yok". The numbers are the REQUIRED solution (the scope view's
// requiredUp / requiredRight, what "Kuleleri kur" dials), not the turret.
// Report: docs/reports/hedef_sonuc_ustte.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

// Gazi Sniper 6–36×56 FFP on a Hatsan Hercules .25 (catalog entries).
const _moaMetric = RifleProfile(
  id: 'p-sonuc-moa',
  name: 'MOA metre',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _mradMetric = RifleProfile(
  id: 'p-sonuc-mrad',
  name: 'MRAD metre',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.mrad,
);

const _moaYard = RifleProfile(
  id: 'p-sonuc-yard',
  name: 'MOA yard',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 27.432, // 30 yd
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
  distanceUnit: DistanceUnit.yard,
);

Future<void> _show(WidgetTester tester, RifleProfile profile) async {
  tester.view.physicalSize = const Size(390, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      home: Scaffold(
        body: BallisticsScreen(profile: profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

/// The texts of one result column, top to bottom.
List<String> _texts(WidgetTester tester, Key key) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .map((t) => t.data!)
    .toList();

String _fmt(double v) => v.abs().toStringAsFixed(1).replaceAll('.', ',');

/// Independent expectation from the scope view's required solution.
({List<String> up, List<String> right}) _expected(
  ScopeDialView d, {
  required bool windCalm,
}) {
  final upClicks = (d.requiredUp! / d.clickValue).round();
  final rightClicks = (d.requiredRight / d.clickValue).round();
  final unit = d.unit.label;
  String detail(double a, String pos, String neg) =>
      _fmt(a) == '0,0' ? '0,0 $unit' : '${_fmt(a)} $unit ${a > 0 ? pos : neg}';
  return (
    up: [
      'Üst kule',
      '${upClicks.abs()} klik',
      detail(d.requiredUp!, 'yukarı', 'aşağı'),
    ],
    right: [
      'Yan kule',
      '${rightClicks.abs()} klik',
      rightClicks == 0 && windCalm
          ? 'rüzgâr yok'
          : detail(d.requiredRight, 'sağ', 'sol'),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the row sits under the distance slider, above the reticle '
      'card', (tester) async {
    await _show(tester, _moaMetric);
    final row = find.byKey(TurretSolutionRow.rowKey);
    expect(row, findsOneWidget);
    final slider = find.byType(Slider).first;
    final card = find
        .ancestor(
          of: find.byType(ScopeDialView),
          matching: find.byType(MenzilCard),
        )
        .first;
    expect(
      tester.getTopLeft(row).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(slider).dy),
    );
    expect(
      tester.getBottomLeft(row).dy,
      lessThanOrEqualTo(tester.getTopLeft(card).dy),
    );
    expect(
      tester.getBottomLeft(row).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(ScopeDialKeys.reticle)).dy,
      ),
    );
    // Two columns side by side: Üst kule left, Yan kule right.
    final up = tester.getRect(find.byKey(TurretSolutionRow.elevationKey));
    final right = tester.getRect(find.byKey(TurretSolutionRow.windageKey));
    expect(up.right, lessThanOrEqualTo(right.left));
    expect((up.top - right.top).abs(), lessThan(0.5));
    expect(tester.takeException(), isNull);
  });

  for (final p in [_moaMetric, _mradMetric, _moaYard]) {
    testWidgets('numbers equal the solver solution: ${p.name}', (tester) async {
      await _show(tester, p);
      final d = _dial(tester);
      expect(d.unit, p.angularUnit);
      expect(d.requiredUp, isNotNull);
      final e = _expected(d, windCalm: true);
      expect(_texts(tester, TurretSolutionRow.elevationKey), e.up);
      expect(_texts(tester, TurretSolutionRow.windageKey), e.right);
      expect(
        _texts(tester, TurretSolutionRow.elevationKey)[2],
        contains(p.angularUnit.label),
      );

      // "Kuleleri kur" dials the same clicks the row shows.
      final kur = find.byKey(ScopeDialKeys.dialSolution);
      await tester.ensureVisible(kur);
      await tester.pumpAndSettle();
      await tester.tap(kur);
      await tester.pumpAndSettle();
      final after = _dial(tester);
      expect(
        '${after.elevationClicks.abs()} klik',
        _texts(tester, TurretSolutionRow.elevationKey)[1],
      );
      expect(
        '${after.windageClicks.abs()} klik',
        _texts(tester, TurretSolutionRow.windageKey)[1],
      );
    });
  }

  testWidgets('shows the required solution, not the dialled turret', (
    tester,
  ) async {
    await _show(tester, _moaMetric);
    final before = _texts(tester, TurretSolutionRow.elevationKey);
    expect(before[1], isNot('0 klik'));
    // "Kuleleri sıfırla" puts the turrets back to 0: the row stays on the
    // required solution.
    final reset = find.byKey(ScopeDialKeys.reset);
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(_dial(tester).elevationClicks, 0);
    expect(_texts(tester, TurretSolutionRow.elevationKey), before);
  });

  testWidgets('"rüzgâr yok" at 0 wind', (tester) async {
    await _show(tester, _moaMetric);
    final d = _dial(tester);
    expect(d.requiredRight, 0);
    expect(_texts(tester, TurretSolutionRow.windageKey), [
      'Yan kule',
      '0 klik',
      'rüzgâr yok',
    ]);
  });

  testWidgets('updates when the distance changes', (tester) async {
    await _show(tester, _moaMetric);
    final before = _texts(tester, TurretSolutionRow.elevationKey);
    final rangeBefore = _dial(tester).rangeM;
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('+5').first);
      await tester.pumpAndSettle();
    }
    final d = _dial(tester);
    expect(d.rangeM, greaterThan(rangeBefore));
    final e = _expected(d, windCalm: true);
    final after = _texts(tester, TurretSolutionRow.elevationKey);
    expect(after, e.up);
    expect(after, isNot(before));
  });

  testWidgets('VoiceOver reads each column as one sentence', (tester) async {
    final handle = tester.ensureSemantics();
    await _show(tester, _moaMetric);
    final e = _expected(_dial(tester), windCalm: true);
    expect(
      tester.getSemantics(find.byKey(TurretSolutionRow.elevationKey)).label,
      '${e.up[0]} ${e.up[1]}, ${e.up[2]}',
    );
    expect(
      tester.getSemantics(find.byKey(TurretSolutionRow.windageKey)).label,
      'Yan kule 0 klik, rüzgâr yok',
    );
    handle.dispose();
  });

  testWidgets('accent lines: amber for Üst kule, cyan for Yan kule', (
    tester,
  ) async {
    await _show(tester, _moaMetric);
    Color accent(Key key) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final border = (box.decoration as BoxDecoration).border! as Border;
      expect(border.left.width, 3);
      return border.left.color;
    }

    expect(accent(TurretSolutionRow.elevationKey), const Color(0xFFF5B031));
    expect(accent(TurretSolutionRow.windageKey), const Color(0xFF4CC3E8));
    // The big number: 34 pt, tabular figures.
    final big = tester.widget<Text>(
      find.descendant(
        of: find.byKey(TurretSolutionRow.elevationKey),
        matching: find.textContaining('klik'),
      ),
    );
    expect(big.style!.fontSize, 34);
    expect(
      big.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('no overflow at 320 pt and text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: MenzilTheme.dark(),
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: c!,
        ),
        home: const Scaffold(
          body: BallisticsScreen(
            profile: _mradMetric,
            view: BallisticsView.shot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(TurretSolutionRow.rowKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
