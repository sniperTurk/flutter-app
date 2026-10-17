// Kule ChairGun ölçüsü (owner, 2026-10-18 01:25 Istanbul): ONE option,
// ChairGun's turret almost one to one in size, cylinder look, text layout
// and red index; only the colours are ours. ChairGun's 199 × 60 pt drum on
// its 402 pt screen is 194 × 58 pt on a 390 pt phone. The side turret is the
// same drum turned 90°: 58 × 194 pt, right edge on the reticle's right edge,
// centred on the horizontal line. The top one is centred on the vertical
// line, right above the reticle, joined to it by a darker trapezoid mount.
// The step chevrons are inside the drum (owner, 2026-10-17 21:07) with
// ≥ 44 × 44 pt tap areas that leave the three values free.
// Report: docs/reports/kule_chairgun_olcu.md.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/tool_fakes.dart';

// Gazi Sniper 6–36×56 FFP in MOA.
const _profile = RifleProfile(
  id: 'p-kule-chairgun',
  name: 'Kule',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
  angularUnit: AngularUnit.moa,
);

const _up = 'Yükseklik kulesi 1 klik yukarı';
const _down = 'Yükseklik kulesi 1 klik aşağı';
const _right = 'Rüzgâr kulesi 1 klik sağa';
const _left = 'Rüzgâr kulesi 1 klik sola';

class _FakeClickSound implements TurretClickSound {
  int clicks = 0;

  @override
  void click() => clicks++;

  @override
  void preload() {}
}

Future<_FakeClickSound> _open(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
  bool dial = false,
}) async {
  final fake = _FakeClickSound();
  TurretClickSound.instance = fake;
  addTearDown(() => TurretClickSound.instance = const SilentTurretClickSound());
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MenzilTheme.dark(),
      builder: (context, c) => ToolsServicesScope(
        services: testServices(),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
      ),
      home: const Scaffold(
        body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (dial) {
    // "Kuleleri kur" dials both turrets and slides the side one in.
    final kur = find.byKey(ScopeDialKeys.dialSolution);
    await tester.ensureVisible(kur);
    await tester.pumpAndSettle();
    await tester.tap(kur);
  } else {
    final toggle = find.byKey(ScopeDialKeys.turretToggle);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
  }
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(ScopeDialKeys.reticle));
  await tester.pumpAndSettle();
  return fake;
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

/// The drum's own painter (not the chevrons) under [of].
Finder _drumPaint(Key of) => find
    .descendant(
      of: find.byKey(of),
      matching: find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter != null &&
            w.painter is! TurretChevronPainter,
      ),
    )
    .first;

/// Text boxes the drum's painter draws, in its own coordinates.
List<Rect> _labels(Finder finder) {
  final labels = <Rect>[];
  expect(
    finder,
    paints..everything((method, args) {
      if (method == #drawParagraph) {
        final p = args[0] as ui.Paragraph;
        final o = args[1] as Offset;
        labels.add(o & Size(p.maxIntrinsicWidth, p.height));
      }
      return true;
    }),
  );
  return labels;
}

bool _inside(Rect inner, Rect outer, [double e = 0.01]) =>
    inner.left >= outer.left - e &&
    inner.top >= outer.top - e &&
    inner.right <= outer.right + e &&
    inner.bottom <= outer.bottom + e;

void _noOverlap(Rect a, Rect b, String reason) {
  final i = a.intersect(b);
  expect(
    i.width <= 0.01 || i.height <= 0.01,
    isTrue,
    reason: '$reason: $a overlaps $b',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ChairGun 199 × 60 on 402 pt → 194 × 58 on 390 pt; 320 pt size', () {
    final d390 = ScopeTurretGeometry.drum(390);
    // 199 × 390 / 402 = 193,1 and 60 × 390 / 402 = 58,2; the owner set
    // 194 × 58.
    expect(d390.width, moreOrLessEquals(199 * 390 / 402, epsilon: 1));
    expect(d390.height, moreOrLessEquals(60 * 390 / 402, epsilon: 1));
    expect(d390.width, 194);
    expect(d390.height, 58);
    final d320 = ScopeTurretGeometry.drum(320);
    // 159,2 × 47,6 pt on a 320 pt phone (reported in the PR).
    expect(d320.width, moreOrLessEquals(159.18, epsilon: 0.01));
    expect(d320.height, moreOrLessEquals(47.59, epsilon: 0.01));
    // Never thinner than 44 pt.
    expect(ScopeTurretGeometry.drum(280).height, 44);
  });

  for (final (size, scale) in const [
    (Size(390, 844), 1.0),
    (Size(390, 844), 1.3),
    (Size(320, 568), 1.0),
    (Size(320, 568), 1.3),
    (Size(430, 932), 1.0),
  ]) {
    final name = '${size.width.toInt()}×${size.height.toInt()}, text ×$scale';

    testWidgets('$name: both drums the same size, placed as in ChairGun', (
      tester,
    ) async {
      await _open(tester, size, textScale: scale);
      expect(tester.takeException(), isNull);
      final want = ScopeTurretGeometry.drum(size.width);
      final reticle = tester.getRect(find.byKey(ScopeDialKeys.reticle));
      final top = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
      final side = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
      // Same drum: top L × T, side T × L (±0,5 pt).
      expect(top.width, moreOrLessEquals(want.width, epsilon: 0.5));
      expect(top.height, moreOrLessEquals(want.height, epsilon: 0.5));
      expect(side.width, moreOrLessEquals(top.height, epsilon: 0.5));
      expect(side.height, moreOrLessEquals(top.width, epsilon: 0.5));
      expect(top.height, greaterThanOrEqualTo(44));
      if (size.width == 390) {
        expect(top.width, moreOrLessEquals(194, epsilon: 0.5));
        expect(top.height, moreOrLessEquals(58, epsilon: 0.5));
      }
      // Side: right edge on the reticle's right edge, centred on the
      // horizontal line. Top: centred on the vertical line, right above the
      // reticle; only the mount lies between them.
      expect(side.right, moreOrLessEquals(reticle.right, epsilon: 0.5));
      expect(side.center.dy, moreOrLessEquals(reticle.center.dy, epsilon: 0.5));
      expect(top.center.dx, moreOrLessEquals(reticle.center.dx, epsilon: 0.5));
      expect(
        reticle.top - top.bottom,
        moreOrLessEquals(
          ScopeTurretGeometry.mountHeight(top.height),
          epsilon: 0.5,
        ),
      );
      // No overlap with L-R or the eye button (drum and mount).
      final toggle = tester.getRect(find.byKey(ScopeDialKeys.turretToggle));
      final eye = tester.getRect(find.byKey(ScopeDialKeys.labelsToggle));
      final mount = Rect.fromCenter(
        center: Offset(top.center.dx, (top.bottom + reticle.top) / 2),
        width: top.width * ScopeTurretGeometry.mountBottomShare,
        height: reticle.top - top.bottom,
      );
      for (final (n, r) in [('drum', top), ('mount', mount)]) {
        _noOverlap(r, toggle, '$n vs L-R');
        _noOverlap(r, eye, '$n vs eye');
      }
      _noOverlap(side, eye, 'side vs eye');
    });

    testWidgets('$name: chevron tap areas ≥ 44 × 44 inside the drum, the '
        'three values free', (tester) async {
      await _open(tester, size, textScale: scale);
      final top = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
      final side = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
      for (final (tip, drum, glyph) in [
        (_up, top, 'Yükseklik kulesi-step-plus'),
        (_down, top, 'Yükseklik kulesi-step-minus'),
        (_right, side, 'Rüzgâr kulesi-step-plus'),
        (_left, side, 'Rüzgâr kulesi-step-minus'),
      ]) {
        final area = tester.getRect(find.byTooltip(tip));
        expect(area.width, greaterThanOrEqualTo(44 - 0.01), reason: tip);
        expect(area.height, greaterThanOrEqualTo(44 - 0.01), reason: tip);
        expect(_inside(area, drum), isTrue, reason: '$tip $area in $drum');
        final g = tester.getRect(find.byKey(ValueKey(glyph)));
        expect(_inside(g, area), isTrue, reason: '$glyph $g in $area');
      }
      // Top: ‹ at the left end, › at the right end.
      expect(
        tester.getRect(find.byTooltip(_up)).left,
        moreOrLessEquals(top.left, epsilon: 0.5),
      );
      expect(
        tester.getRect(find.byTooltip(_down)).right,
        moreOrLessEquals(top.right, epsilon: 0.5),
      );
      // Side: ^ at the top end, v at the bottom end.
      expect(
        tester.getRect(find.byTooltip(_right)).top,
        moreOrLessEquals(side.top, epsilon: 0.5),
      );
      expect(
        tester.getRect(find.byTooltip(_left)).bottom,
        moreOrLessEquals(side.bottom, epsilon: 0.5),
      );
      final chevrons = [
        for (final tip in const [_up, _down, _right, _left])
          tester.getRect(find.byTooltip(tip)),
      ];

      // Top values: three on the middle row, previous / CURRENT / next,
      // the current one on the vertical line, none under a tap area and all
      // inside the drum.
      final t = _labels(_drumPaint(ScopeDialKeys.elevationDrum));
      final topValues = [
        for (final l in t)
          if ((l.center.dy - top.height / 2).abs() < 1) l.shift(top.topLeft),
      ]..sort((a, b) => a.center.dx.compareTo(b.center.dx));
      expect(topValues, hasLength(3));
      expect(
        topValues[1].center.dx,
        moreOrLessEquals(top.center.dx, epsilon: 0.5),
      );
      // The current value is the largest.
      expect(topValues[1].height, greaterThan(topValues[0].height));
      expect(topValues[1].height, greaterThan(topValues[2].height));
      // Side values: three in a column next to the ticks.
      final s = _labels(_drumPaint(ScopeDialKeys.windageDrumBox));
      final cx = side.width * ScopeTurretGeometry.sideValuesCentreShare;
      final sideValues = [
        for (final l in s)
          if ((l.center.dx - cx).abs() < 1) l.shift(side.topLeft),
      ]..sort((a, b) => a.center.dy.compareTo(b.center.dy));
      expect(sideValues, hasLength(3));
      expect(
        sideValues[1].center.dy,
        moreOrLessEquals(side.center.dy, epsilon: 0.5),
      );
      for (final (drum, values) in [(top, topValues), (side, sideValues)]) {
        for (final v in values) {
          expect(_inside(v, drum), isTrue, reason: '$v in $drum');
          for (final a in chevrons) {
            _noOverlap(v, a, 'value vs chevron area');
          }
        }
      }
    });

    testWidgets('$name: no overflow with both turrets dialled', (tester) async {
      await _open(tester, size, textScale: scale, dial: true);
      expect(tester.takeException(), isNull);
      expect(_dial(tester).elevationClicks, isNot(0));
      expect(find.byKey(ScopeDialKeys.windageDrumBox), findsOneWidget);
    });
  }

  testWidgets('one tap on each chevron = one click and one click sound', (
    tester,
  ) async {
    final sound = await _open(tester, const Size(390, 844));
    for (final (tip, delta, horizontal) in const [
      (_up, 1, true),
      (_down, -1, true),
      (_right, 1, false),
      (_left, -1, false),
    ]) {
      final e = _dial(tester).elevationClicks;
      final w = _dial(tester).windageClicks;
      final before = sound.clicks;
      await tester.ensureVisible(find.byTooltip(tip));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(tip));
      await tester.pumpAndSettle();
      expect(
        _dial(tester).elevationClicks,
        horizontal ? e + delta : e,
        reason: tip,
      );
      expect(
        _dial(tester).windageClicks,
        horizontal ? w : w + delta,
        reason: tip,
      );
      expect(sound.clicks, before + 1, reason: tip);
    }
  });

  testWidgets('the drum is navy with a red index; the side one is the top '
      'one turned', (tester) async {
    await _open(tester, const Size(390, 844));
    final top = tester.getRect(find.byKey(ScopeDialKeys.elevationDrum));
    final side = tester.getRect(find.byKey(ScopeDialKeys.windageDrumBox));
    final danger = MenzilColors.dark.danger;
    final ti = TurretIndex.top(top.size);
    final si = TurretIndex.side(side.size);
    // Top index: bottom centre, pointing up. Side: left centre, pointing
    // right. Same size.
    expect(ti.center.dx, moreOrLessEquals(top.width / 2, epsilon: 0.01));
    expect(ti.bottom, lessThanOrEqualTo(top.height));
    expect(si.center.dy, moreOrLessEquals(side.height / 2, epsilon: 0.01));
    expect(si.left, greaterThanOrEqualTo(0));
    expect(ti.width, moreOrLessEquals(si.height, epsilon: 0.01));
    expect(ti.height, moreOrLessEquals(si.width, epsilon: 0.01));
    expect(
      _drumPaint(ScopeDialKeys.elevationDrum),
      paints
        ..path(color: danger, includes: [Offset(ti.center.dx, ti.bottom - 1)]),
    );
    expect(
      _drumPaint(ScopeDialKeys.windageDrumBox),
      paints
        ..path(color: danger, includes: [Offset(si.left + 1, si.center.dy)]),
    );
  });
}
