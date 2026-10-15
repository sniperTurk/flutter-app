// Kule klik sesi (owner, 2026-10-15 23:30: "Dürbün kulelerini çevirme klik
// sesi ekleyelim."; 23:31: "Kuleyi kuleden çevirirken de klik sesi
// gelsin."). Every click step the user turns on the top (elevation) or the
// side (windage) turret asks the sound service for one click, by an arrow
// tap or by dragging the drum; programmatic moves ("Kuleleri kur",
// "Kuleleri sıfırla", the Pro → Hedef auto-set) stay silent. The turret
// values move exactly as before. A fake sound service counts the clicks;
// no real audio plays in tests. Report: docs/reports/kule_klik_sesi.md.
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

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks, catalogued turret travel.
const _profile = RifleProfile(
  id: 'p-klik',
  name: 'Klik',
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
  int preloads = 0;

  @override
  void click() => clicks++;

  @override
  void preload() => preloads++;
}

/// The drum's drag step (`_TurretDrumState.pixelsPerClick`).
const double _px = 9;

const _up = 'Yükseklik kulesi 1 klik yukarı';
const _down = 'Yükseklik kulesi 1 klik aşağı';
const _right = 'Rüzgâr kulesi 1 klik sağa';
const _left = 'Rüzgâr kulesi 1 klik sola';

Widget _app(BallisticsView view) => MaterialApp(
  theme: MenzilTheme.dark(),
  builder: (context, c) =>
      ToolsServicesScope(services: testServices(), child: c!),
  home: Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  ),
);

Future<_FakeClickSound> _open(
  WidgetTester tester, {
  bool windage = true,
}) async {
  final fake = _FakeClickSound();
  TurretClickSound.instance = fake;
  addTearDown(
    () => TurretClickSound.instance = const SilentTurretClickSound(),
  );
  tester.view.physicalSize = const Size(430, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(BallisticsView.shot));
  await tester.pumpAndSettle();
  if (windage) {
    final toggle = find.byKey(ScopeDialKeys.turretToggle);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
  }
  return fake;
}

ScopeDialView _dial(WidgetTester tester) =>
    tester.widget<ScopeDialView>(find.byType(ScopeDialView));

int _elev(WidgetTester tester) => _dial(tester).elevationClicks;
int _wind(WidgetTester tester) => _dial(tester).windageClicks;

Future<void> _tap(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump();
}

/// Starts a drag on [drum] and moves it past the touch slop; the drum
/// counts its steps from there (its carry resets on drag start).
Future<TestGesture> _grab(
  WidgetTester tester,
  Finder drum,
  Axis axis,
) async {
  await tester.ensureVisible(drum);
  await tester.pumpAndSettle();
  final g = await tester.startGesture(tester.getCenter(drum));
  await g.moveBy(axis == Axis.horizontal
      ? const Offset(kTouchSlop + 2, 0)
      : const Offset(0, kTouchSlop + 2));
  await tester.pump();
  return g;
}

Future<void> _move(TestGesture g, WidgetTester tester, Axis axis, double d) async {
  await g.moveBy(axis == Axis.horizontal ? Offset(d, 0) : Offset(0, d));
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('one tap on each of the four arrows clicks once each', (
    tester,
  ) async {
    final fake = await _open(tester);
    expect(fake.clicks, 0);
    // The drums preload the sound so the first click is not late.
    expect(fake.preloads, greaterThan(0));
    for (final (tooltip, elev, wind) in const [
      (_up, 1, 0),
      (_down, -1, 0),
      (_right, 0, 1),
      (_left, 0, -1),
    ]) {
      final e = _elev(tester), w = _wind(tester), n = fake.clicks;
      await _tap(tester, tooltip);
      expect(fake.clicks, n + 1, reason: tooltip);
      // The turret moves one click, as before.
      expect(_elev(tester), e + elev, reason: tooltip);
      expect(_wind(tester), w + wind, reason: tooltip);
    }
    expect(fake.clicks, 4);
  });

  testWidgets('5 rapid taps click 5 times', (tester) async {
    final fake = await _open(tester);
    for (final tooltip in const [_up, _right]) {
      final e = _elev(tester), w = _wind(tester), n = fake.clicks;
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(fake.clicks, n + 5, reason: tooltip);
      expect(_elev(tester) - e + _wind(tester) - w, 5, reason: tooltip);
    }
  });

  for (final n in const [1, 7]) {
    testWidgets('dragging the top drum by $n click steps clicks $n times', (
      tester,
    ) async {
      final fake = await _open(tester, windage: false);
      final g = await _grab(
        tester,
        find.byKey(ScopeDialKeys.elevationDrum),
        Axis.horizontal,
      );
      final before = _elev(tester);
      final n0 = fake.clicks;
      for (var i = 0; i < n; i++) {
        await _move(g, tester, Axis.horizontal, _px);
        // In time with the steps: one click per step, as it happens.
        expect(fake.clicks - n0, i + 1);
      }
      await g.up();
      await tester.pumpAndSettle();
      // Dragging right dials UP, one click per 9 pt, as before.
      expect(_elev(tester), before + n);
      expect(fake.clicks - n0, n);
    });

    testWidgets('dragging the side drum by $n click steps clicks $n times', (
      tester,
    ) async {
      final fake = await _open(tester);
      final g = await _grab(
        tester,
        find.byKey(ScopeDialKeys.windageDrum),
        Axis.vertical,
      );
      final before = _wind(tester);
      final n0 = fake.clicks;
      for (var i = 0; i < n; i++) {
        await _move(g, tester, Axis.vertical, _px);
        expect(fake.clicks - n0, i + 1);
      }
      await g.up();
      await tester.pumpAndSettle();
      // Dragging down dials RIGHT, one click per 9 pt, as before.
      expect(_wind(tester), before + n);
      expect(fake.clicks - n0, n);
    });
  }

  testWidgets('dragging less than one click step is silent', (tester) async {
    final fake = await _open(tester);
    for (final (key, axis) in const [
      (ScopeDialKeys.elevationDrum, Axis.horizontal),
      (ScopeDialKeys.windageDrum, Axis.vertical),
    ]) {
      final e = _elev(tester), w = _wind(tester);
      final g = await _grab(tester, find.byKey(key), axis);
      await _move(g, tester, axis, _px - 3);
      await g.up();
      await tester.pumpAndSettle();
      expect(fake.clicks, 0, reason: '$key');
      expect(_elev(tester), e);
      expect(_wind(tester), w);
    }
  });

  testWidgets('at the travel limit the clicks stop', (tester) async {
    final fake = await _open(tester);
    for (final (key, axis, max, value) in [
      (
        ScopeDialKeys.elevationDrum,
        Axis.horizontal,
        _dial(tester).maxElevationClicks,
        _elev,
      ),
      (
        ScopeDialKeys.windageDrum,
        Axis.vertical,
        _dial(tester).maxWindageClicks,
        _wind,
      ),
    ]) {
      final g = await _grab(tester, find.byKey(key), axis);
      // One long move to 3 clicks short of the limit: one click per step.
      final start = value(tester);
      final n0 = fake.clicks;
      final far = max - 3 - start;
      await _move(g, tester, axis, far * _px);
      expect(value(tester), max - 3);
      expect(fake.clicks - n0, far);
      // 10 more steps: 3 reach the limit, the other 7 are silent.
      final n1 = fake.clicks;
      for (var i = 0; i < 10; i++) {
        await _move(g, tester, axis, _px);
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(value(tester), max, reason: '$key');
      expect(fake.clicks - n1, 3, reason: '$key');
    }
    // An arrow tap at the limit does not move and does not click.
    final n2 = fake.clicks;
    await _tap(tester, _up);
    await _tap(tester, _right);
    expect(fake.clicks, n2);
  });

  testWidgets('"Kuleleri kur" and "Kuleleri sıfırla" are silent', (
    tester,
  ) async {
    final fake = await _open(tester, windage: false);
    final kur = find.byKey(ScopeDialKeys.dialSolution);
    await tester.ensureVisible(kur);
    await tester.pumpAndSettle();
    await tester.tap(kur);
    await tester.pumpAndSettle();
    // 100 m with a 25 m zero: the solution moves the top turret.
    expect(_elev(tester), isNot(0));
    expect(fake.clicks, 0);
    final reset = find.byKey(ScopeDialKeys.reset);
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(_elev(tester), 0);
    expect(_wind(tester), 0);
    expect(fake.clicks, 0);
  });

  testWidgets('the Pro → Hedef auto-set is silent', (tester) async {
    final fake = _FakeClickSound();
    TurretClickSound.instance = fake;
    addTearDown(
      () => TurretClickSound.instance = const SilentTurretClickSound(),
    );
    tester.view.physicalSize = const Size(430, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(BallisticsView.pro));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('pro-shot-range')),
        matching: find.byType(TextField),
      ),
      '300',
    );
    await tester.pump();
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    expect(_elev(tester), greaterThan(0));
    expect(fake.clicks, 0);
  });
}
