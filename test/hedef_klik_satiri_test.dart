// Hedef klik satırı (owner, 2026-10-17 11:51–11:52 Istanbul, TestFlight 112:
// "Üst kule klik sayısını sağ çizgiye yasla. Solda bulunan çizgiyi
// kaldır." then "yap"). The Üst kule half has no bar and ends 5 pt before
// the blue bar; the Yan kule half is unchanged. Report:
// docs/reports/hedef_klik_satiri.md.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

// Gazi Sniper 6–36×56 FFP on a Hatsan Hercules .25 (catalog entries).
const _profile = RifleProfile(
  id: 'p-klik-satiri',
  name: 'Klik satırı',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _amber = Color(0xFFF5B031);
const _cyan = Color(0xFF4CC3E8);

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: MenzilTheme.dark(),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Scaffold(body: home),
);

Future<void> _hedef(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      const BallisticsScreen(profile: _profile, view: BallisticsView.shot),
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _in(Key key, Type type) =>
    find.descendant(of: find.byKey(key), matching: find.byType(type));

/// Every bar (left border) drawn inside the click line, with its colour.
List<Color> _bars(WidgetTester tester) => [
  for (final b in tester.widgetList<DecoratedBox>(
    _in(TurretSolutionRow.rowKey, DecoratedBox),
  ))
    if (b.decoration case BoxDecoration(border: final Border border))
      if (border.left.width > 0) border.left.color,
];

String _text(WidgetTester tester, Key key) =>
    tester.widget<RichText>(_in(key, RichText)).text.toPlainText();

void _checkLayout(WidgetTester tester, {required String tag}) {
  final row = tester.getRect(find.byKey(TurretSolutionRow.rowKey));
  final up = tester.getRect(find.byKey(TurretSolutionRow.elevationKey));
  final upText = tester.getRect(_in(TurretSolutionRow.elevationKey, RichText));
  final bar = tester.getRect(
    _in(TurretSolutionRow.windageKey, DecoratedBox).first,
  );
  final rightText = tester.getRect(_in(TurretSolutionRow.windageKey, RichText));
  // Only the blue bar is left; no orange bar.
  expect(_bars(tester), [_cyan], reason: tag);
  expect(_bars(tester), isNot(contains(_amber)), reason: tag);
  // Üst kule text ends 5 pt before the blue bar, the same gap as from the
  // blue bar's right edge to "Yan kule" (8 pt padding under a 3 pt bar,
  // as on main).
  final gapUp = bar.left - upText.right;
  final gapRight = rightText.left - (bar.left + 3);
  expect(
    gapUp,
    moreOrLessEquals(TurretSolutionRow.dividerGap, epsilon: 0.5),
    reason: tag,
  );
  expect(gapRight, moreOrLessEquals(5, epsilon: 0.5), reason: tag);
  // Text inside the line, nothing drawn left of the row.
  expect(upText.left, greaterThanOrEqualTo(row.left - 0.01), reason: tag);
  expect(rightText.right, lessThanOrEqualTo(row.right + 0.01), reason: tag);
  // Yan kule half unchanged: same place and width as on main (halves of
  // the row with 12 pt between them), bar 3 pt at its left edge.
  final half = (row.width - 12) / 2;
  final yan = tester.getRect(find.byKey(TurretSolutionRow.windageKey));
  expect(
    yan.left - row.left,
    moreOrLessEquals(half + 12, epsilon: 0.01),
    reason: tag,
  );
  expect(yan.width, moreOrLessEquals(half, epsilon: 0.01), reason: tag);
  expect(up.width, moreOrLessEquals(half, epsilon: 0.01), reason: tag);
  expect(bar.left, moreOrLessEquals(yan.left, epsilon: 0.01), reason: tag);
  expect(row.height, greaterThanOrEqualTo(TurretSolutionRow.lineHeight));
  for (final key in const [
    TurretSolutionRow.elevationKey,
    TurretSolutionRow.windageKey,
  ]) {
    final p = tester.renderObject<RenderParagraph>(_in(key, RichText));
    expect(p.didExceedMaxLines, isFalse, reason: tag);
  }
  // ignore: avoid_print
  print(
    'HEDEF_KLIK_SATIRI|$tag|satir=${row.width.toStringAsFixed(1)}'
    '|ust_sag=${upText.right.toStringAsFixed(1)}'
    '|mavi_cizgi=${bar.left.toStringAsFixed(1)}'
    '|bosluk_ust=${gapUp.toStringAsFixed(1)}'
    '|bosluk_yan=${gapRight.toStringAsFixed(1)}'
    '|ust="${_text(tester, TurretSolutionRow.elevationKey)}"'
    '|yan="${_text(tester, TurretSolutionRow.windageKey)}"',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('390 pt: no bar left of Üst kule, text ends 5 pt before the '
      'blue bar, Yan kule unchanged', (tester) async {
    await _hedef(tester);
    expect(tester.takeException(), isNull);
    _checkLayout(tester, tag: '390x1.0');
    // Text styles of the Yan kule half unchanged.
    final rich = tester.widget<RichText>(
      _in(TurretSolutionRow.windageKey, RichText),
    );
    final root = (rich.text as TextSpan).children!.single as TextSpan;
    final spans = root.children!.cast<TextSpan>();
    expect(spans[0].text, 'Yan kule ');
    expect(spans[0].style!.fontSize, 12.5);
    expect(spans[0].style!.color, const Color(0xFF9CB1C0));
    expect(spans[1].style!.fontSize, 15);
    expect(spans[1].style!.fontWeight, FontWeight.w600);
    // Üst kule right-aligned in its half.
    expect(rich.textAlign, TextAlign.left);
    expect(
      tester
          .widget<RichText>(_in(TurretSolutionRow.elevationKey, RichText))
          .textAlign,
      TextAlign.right,
    );
  });

  testWidgets('numbers are the scope view\'s required solution (same as '
      'main)', (tester) async {
    await _hedef(tester);
    final d = tester.widget<ScopeDialView>(find.byType(ScopeDialView));
    final upClicks = (d.requiredUp! / d.clickValue).round();
    final rightClicks = (d.requiredRight / d.clickValue).round();
    expect(upClicks, isNot(0));
    expect(rightClicks, 0);
    expect(
      _text(tester, TurretSolutionRow.elevationKey),
      'Üst kule ${upClicks.abs()} klik ${upClicks > 0 ? 'yukarı' : 'aşağı'}',
    );
    expect(
      _text(tester, TurretSolutionRow.windageKey),
      'Yan kule 0 klik rüzgâr yok',
    );
  });

  for (final scale in const [1.0, 1.3]) {
    testWidgets('320 pt ×$scale on the Hedef page: no overflow, same gap', (
      tester,
    ) async {
      await _hedef(tester, width: 320, textScale: scale);
      expect(tester.takeException(), isNull);
      _checkLayout(tester, tag: '320x$scale');
    });
  }

  testWidgets('long values at 320 pt ×1.3: "Üst kule 1234 klik yukarı" '
      'shrinks, every digit kept, no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: TurretSolutionRow(
              requiredUp: 123.4,
              requiredRight: -98.7,
              clickValue: 0.1,
              unit: AngularUnit.mrad,
              windCalm: false,
            ),
          ),
        ),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      _text(tester, TurretSolutionRow.elevationKey),
      'Üst kule 1234 klik yukarı',
    );
    expect(
      _text(tester, TurretSolutionRow.windageKey),
      'Yan kule 987 klik sol',
    );
    _checkLayout(tester, tag: '320x1.3-uzun');
  });
}
