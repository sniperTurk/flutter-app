// Kule tasarım seçenekleri (owner, 2026-10-17 21:17). Design-only: the
// five options are drawn only under a TurretStyleScope; the app has none.
// Checks the owner's hard rules for every option at 390 and 320 pt, and
// that the shipped turret is unchanged without (or with "current") style.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

/// Phone width → reticle side on the Hedef card (28 pt each side).
const _phones = {390.0: 334.0, 320.0: 264.0};

Future<ValueNotifier<(int, int)>> _pump(
  WidgetTester tester, {
  required double phone,
  TurretStyle? style,
}) async {
  final height = phone == 390 ? 844.0 : 568.0;
  tester.view.physicalSize = Size(phone, height * 3) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final clicks = ValueNotifier<(int, int)>((0, 0));
  Widget view = ValueListenableBuilder<(int, int)>(
    valueListenable: clicks,
    builder: (context, v, _) => ScopeDialView(
      unit: AngularUnit.mrad,
      clickValue: 0.1,
      elevationClicks: v.$1,
      windageClicks: v.$2,
      maxElevationClicks: 130,
      maxWindageClicks: 130,
      onElevationChanged: (e) => clicks.value = (e, clicks.value.$2),
      onWindageChanged: (w) => clicks.value = (clicks.value.$1, w),
      requiredUp: 1.5,
      rangeM: 50,
      samples: const [],
      toDisplayRange: (m) => m,
      distanceUnit: 'm',
      metric: true,
    ),
  );
  if (style != null) view = TurretStyleScope(style: style, child: view);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(phone, height)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: view,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return clicks;
}

Future<void> _openSide(WidgetTester tester) async {
  await tester.tap(find.byKey(ScopeDialKeys.turretToggle));
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void main() {
  test('option 1 is the main session draft: 230 × 72, chevrons', () {
    const d = TurretDesign.secenek1;
    expect(d.length, 230);
    expect(d.thickness, 72);
    expect(d.arrow, TurretArrowLook.chevron);
    expect(TurretStyle.secenek1.design, same(d));
    expect(TurretStyle.current.design, isNull);
    expect(TurretDesign.all, hasLength(5));
  });

  testWidgets('the shipped turret is unchanged by the design switch', (
    tester,
  ) async {
    for (final phone in _phones.keys) {
      await _pump(tester, phone: phone);
      await _openSide(tester);
      final top = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
      final side = tester.getRect(find.byKey(ScopeDialKeys.windageDrum));
      final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));

      await _pump(tester, phone: phone, style: TurretStyle.current);
      await _openSide(tester);
      expect(tester.getRect(find.byKey(ScopeDialKeys.elevationDrum)), top);
      expect(tester.getRect(find.byKey(ScopeDialKeys.windageDrum)), side);
      expect(tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox)), box);
    }
  });

  for (final style in TurretStyle.values.skip(1)) {
    final design = style.design!;
    for (final MapEntry(key: phone, value: side) in _phones.entries) {
      testWidgets(
        'seçenek ${design.number} at ${phone.toInt()} pt keeps the rules',
        (tester) async {
          final clicks = await _pump(tester, phone: phone, style: style);
          await _openSide(tester);
          expect(tester.takeException(), isNull);

          final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
          expect(reticle.width, closeTo(side, 0.5));
          final top = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
          final right = tester.getRect(find.byKey(ScopeDialKeys.windageDrum));

          // Same size: the side turret is the top one turned 90°.
          expect(right.height, closeTo(top.width, 0.5));
          expect(right.width, closeTo(top.height, 0.5));
          if (phone == 390) {
            expect(top.width, closeTo(design.length, 0.5));
            expect(top.height, closeTo(design.thickness, 0.5));
          }
          expect(top.height, greaterThanOrEqualTo(44 - 1e-6));

          // Top zero over the reticle's vertical line; side zero on its
          // horizontal line, right edge on the reticle square's edge.
          expect(top.center.dx, closeTo(reticle.center.dx, 0.5));
          expect(right.center.dy, closeTo(reticle.center.dy, 0.5));
          expect(right.right, closeTo(reticle.right, 0.5));
          expect(top.bottom, lessThanOrEqualTo(reticle.top + 0.5));

          // L-R stays clear of the top turret.
          final lr = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
          expect(lr.left, greaterThanOrEqualTo(top.right - 0.5));

          // Arrows inside the drum at its ends, each at least 44 × 44 pt.
          for (final (name, drum) in [
            ('Yükseklik kulesi', top),
            ('Rüzgâr kulesi', right),
          ]) {
            for (final end in ['plus', 'minus']) {
              final cap = _rect(tester, '$name-cap-$end');
              expect(cap.width, greaterThanOrEqualTo(44 - 1e-6));
              expect(cap.height, greaterThanOrEqualTo(44 - 1e-6));
              expect(drum.inflate(0.5).contains(cap.topLeft), isTrue);
              expect(drum.inflate(0.5).contains(cap.bottomRight), isTrue);
            }
          }
          // The window (numbers, labels) lies between the caps.
          final box = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
          expect(
            box.top,
            closeTo(_rect(tester, 'Rüzgâr kulesi-cap-plus').bottom, 0.5),
          );
          expect(
            box.bottom,
            closeTo(_rect(tester, 'Rüzgâr kulesi-cap-minus').top, 0.5),
          );

          // The caps step the turret one click, as the shipped arrows.
          await tester.tap(find.byKey(const ValueKey('Yükseklik kulesi-cap-plus')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('Rüzgâr kulesi-cap-minus')));
          await tester.pumpAndSettle();
          expect(clicks.value, (1, -1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
