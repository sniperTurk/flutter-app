// Kule klik hızı (owner, 2026-10-16 20:42: "Dürbün kulelerinin klikleri
// çevirme hızı ile aynı değil."). A slow drag was right; a fast drag lost
// clicks: several drag updates reached the drum before the Hedef page
// rebuilt, each one counted from the stale turret value, so the drum turned
// but the click count and the click sound fell behind. Every 9 pt of finger
// travel must be exactly one click in the count and one click sound, also
// when many pointer moves arrive in one frame, and nothing beyond the travel
// limit. A fake sound service counts the clicks; no real audio plays.
// Report: docs/reports/kule_klik_hizi.md.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/features/ballistics/scope_dial_view.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/turret_click_sound.dart';
import 'package:sniper_turk/tools/tools_services.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';

import 'support/tool_fakes.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks, catalogued turret travel.
const _profile = RifleProfile(
  id: 'p-klik-hizi',
  name: 'Klik hızı',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

class _FakeClickSound implements TurretClickSound {
  int clicks = 0;

  @override
  void click() => clicks++;

  @override
  void preload() {}
}

/// The drum's drag step (`_TurretDrumState.pixelsPerClick`).
const double _px = 9;

const _up = 'Yükseklik kulesi 1 klik yukarı';
const _down = 'Yükseklik kulesi 1 klik aşağı';
const _right = 'Rüzgâr kulesi 1 klik sağa';
const _left = 'Rüzgâr kulesi 1 klik sola';

Widget _app() => MaterialApp(
  theme: MenzilTheme.dark(),
  builder: (context, c) =>
      ToolsServicesScope(services: testServices(), child: c!),
  home: const Scaffold(
    body: BallisticsScreen(profile: _profile, view: BallisticsView.shot),
  ),
);

Future<_FakeClickSound> _open(WidgetTester tester) async {
  final fake = _FakeClickSound();
  TurretClickSound.instance = fake;
  addTearDown(() => TurretClickSound.instance = const SilentTurretClickSound());
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  final toggle = find.byKey(ScopeDialKeys.turretToggle);
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
  return fake;
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

int _elev(WidgetTester tester) => _dial(tester).elevationClicks;
int _wind(WidgetTester tester) => _dial(tester).windageClicks;

Offset _along(Axis axis, double d) =>
    axis == Axis.horizontal ? Offset(d, 0) : Offset(0, d);

/// Starts a drag on [drum] and moves it past the touch slop in direction
/// [sign]. That first move may already turn the drum; callers measure from
/// the values and the click count after it.
Future<TestGesture> _grab(
  WidgetTester tester,
  Finder drum,
  Axis axis, {
  double sign = 1,
}) async {
  await tester.ensureVisible(drum);
  await tester.pumpAndSettle();
  final g = await tester.startGesture(tester.getCenter(drum));
  await g.moveBy(_along(axis, sign * (kTouchSlop + 2)));
  await tester.pump();
  return g;
}

/// [moves] pointer moves of [d] each, all delivered before one pump: the
/// drag updates reach the drum before the page rebuilds, as in a fast
/// swipe.
Future<void> _fastMoves(
  TestGesture g,
  WidgetTester tester,
  Axis axis,
  double d,
  int moves,
) async {
  for (var i = 0; i < moves; i++) {
    await g.moveBy(_along(axis, d));
  }
  await tester.pump();
}

typedef _Drum = (String, Key, Axis, int Function(WidgetTester));

const List<_Drum> _drums = [
  ('top (elevation)', ScopeDialKeys.elevationDrum, Axis.horizontal, _elev),
  ('side (windage)', ScopeDialKeys.windageDrum, Axis.vertical, _wind),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (name, key, axis, value) in _drums) {
    for (final sign in const [1.0, -1.0]) {
      final dir = sign > 0 ? 'forward' : 'back';
      for (final n in const [5, 12]) {
        testWidgets(
          '$name drum, fast drag $dir of $n×9 pt in one frame: $n clicks',
          (tester) async {
            final fake = await _open(tester);
            final g = await _grab(tester, find.byKey(key), axis, sign: sign);
            final before = value(tester);
            final n0 = fake.clicks;
            // n moves of 9 pt, all before one rebuild.
            await _fastMoves(g, tester, axis, sign * _px, n);
            expect(value(tester), before + sign.toInt() * n);
            expect(fake.clicks - n0, n);
            await g.up();
            await tester.pumpAndSettle();
            expect(value(tester), before + sign.toInt() * n);
            expect(fake.clicks - n0, n);
          },
        );
      }

      testWidgets(
        '$name drum, fast drag $dir in 3 pt moves: one click per 9 pt',
        (tester) async {
          final fake = await _open(tester);
          final g = await _grab(tester, find.byKey(key), axis, sign: sign);
          final before = value(tester);
          final n0 = fake.clicks;
          // 21 moves of 3 pt = 63 pt = 7 clicks, all before one rebuild.
          await _fastMoves(g, tester, axis, sign * 3, 21);
          await g.up();
          await tester.pumpAndSettle();
          expect(value(tester), before + sign.toInt() * 7);
          expect(fake.clicks - n0, 7);
        },
      );
    }

    testWidgets('$name drum, slow drag unchanged: one click per 9 pt step', (
      tester,
    ) async {
      final fake = await _open(tester);
      final g = await _grab(tester, find.byKey(key), axis);
      final before = value(tester);
      final n0 = fake.clicks;
      for (var i = 0; i < 6; i++) {
        await g.moveBy(_along(axis, _px));
        await tester.pump();
        expect(value(tester), before + i + 1);
        expect(fake.clicks - n0, i + 1);
      }
      for (var i = 0; i < 6; i++) {
        await g.moveBy(_along(axis, -_px));
        await tester.pump();
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(value(tester), before);
      expect(fake.clicks - n0, 12);
    });

    testWidgets('$name drum, fast drag past the travel limit stops there', (
      tester,
    ) async {
      final fake = await _open(tester);
      final max = key == ScopeDialKeys.elevationDrum
          ? _dial(tester).maxElevationClicks
          : _dial(tester).maxWindageClicks;
      final g = await _grab(tester, find.byKey(key), axis);
      final start = value(tester);
      final n0 = fake.clicks;
      // 20 steps more than the limit, plus 5 pt, all before one rebuild.
      await _fastMoves(g, tester, axis, _px, max - start + 20);
      await _fastMoves(g, tester, axis, 5, 1);
      expect(value(tester), max);
      expect(fake.clicks - n0, max - start);
      // The travel beyond the limit is not stored: 9 pt back is one click.
      final n1 = fake.clicks;
      await _fastMoves(g, tester, axis, -_px, 1);
      expect(value(tester), max - 1);
      expect(fake.clicks - n1, 1);
      await g.up();
      await tester.pumpAndSettle();
      expect(value(tester), max - 1);
      expect(fake.clicks - n1, 1);
    });
  }

  testWidgets('5 rapid arrow taps before a rebuild move and click 5 times', (
    tester,
  ) async {
    final fake = await _open(tester);
    for (final (tooltip, delta, value) in const [
      (_up, 1, _elev),
      (_down, -1, _elev),
      (_right, 1, _wind),
      (_left, -1, _wind),
    ]) {
      final arrow = find.byTooltip(tooltip);
      await tester.ensureVisible(arrow);
      await tester.pumpAndSettle();
      final before = value(tester), n0 = fake.clicks;
      for (var i = 0; i < 5; i++) {
        await tester.tap(arrow);
      }
      await tester.pump();
      expect(value(tester), before + 5 * delta, reason: tooltip);
      expect(fake.clicks - n0, 5, reason: tooltip);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('VoiceOver increase ×3 before a rebuild moves 3 clicks', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final fake = await _open(tester);
    for (final (key, value) in const [
      (ScopeDialKeys.elevationDrum, _elev),
      (ScopeDialKeys.windageDrum, _wind),
    ]) {
      final node = tester.getSemantics(find.byKey(key));
      final before = value(tester), n0 = fake.clicks;
      for (var i = 0; i < 3; i++) {
        node.owner!.performAction(node.id, SemanticsAction.increase);
      }
      await tester.pump();
      expect(value(tester), before + 3, reason: '$key');
      expect(fake.clicks - n0, 3, reason: '$key');
      final m0 = fake.clicks;
      final node2 = tester.getSemantics(find.byKey(key));
      for (var i = 0; i < 3; i++) {
        node2.owner!.performAction(node2.id, SemanticsAction.decrease);
      }
      await tester.pump();
      expect(value(tester), before, reason: '$key');
      expect(fake.clicks - m0, 3, reason: '$key');
    }
    handle.dispose();
  });
}
