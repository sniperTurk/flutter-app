// İrtifa warm-up (owner, 2026-10-14: "Hava Durumu sayfası açılınca al"):
// opening Hava Durumu starts ONE silent GPS request; "Basıncı telefondan al"
// then writes the warmed-up altitude at once. Memory only, never a prompt.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/tools/ports/location_provider.dart';

import 'support/tool_fakes.dart';

const _profile = RifleProfile(
  id: 'p1',
  name: 'Bir',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

const _noAltitude = LocationFix(39.9, 32.8);

class _Rig {
  final TestLocation location;
  final TestClock clock;
  final TestPressure pressure;

  /// 0: Hava Durumu shown; 1: another tab of the IndexedStack.
  final ValueNotifier<int> tab = ValueNotifier(0);
  _Rig(this.location, this.clock, this.pressure);

  void advance(Duration d) => clock.current = clock.current.add(d);
}

Future<_Rig> _open(
  WidgetTester tester, {
  LocationResult coarse = _noAltitude,
  LocationResult? precise,
  Completer<LocationResult>? hold,
  bool granted = true,
}) async {
  tester.view.physicalSize = const Size(430, 2600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final location = TestLocation(coarse)
    ..preciseResult = precise
    ..preciseHold = hold
    ..granted = granted;
  final rig = _Rig(
    location,
    TestClock(DateTime.utc(2026, 10, 14, 11)),
    TestPressure(),
  );
  addTearDown(rig.tab.dispose);
  await tester.pumpWidget(
    host(
      Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: rig.tab,
          builder: (context, index, _) => IndexedStack(
            index: index,
            children: const [
              BallisticsScreen(
                profile: _profile,
                view: BallisticsView.environment,
              ),
              SizedBox.expand(),
            ],
          ),
        ),
      ),
      services: testServices(
        location: location,
        clock: rig.clock,
        pressure: rig.pressure,
      ),
    ),
  );
  await tester.pump();
  return rig;
}

Finder _field(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(_field(key)).controller!.text;

Future<void> _tap(WidgetTester tester) async {
  final button = find.byKey(const Key('environment-phone-pressure'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
}

Future<void> _lifecycle(WidgetTester tester, List<AppLifecycleState> s) async {
  for (final state in s) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

const _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];
const _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  testWidgets('opening Hava Durumu starts one silent precise request', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      precise: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    expect(rig.location.calls, [(precise: true, askPermission: false)]);
    // Silent: no status text, nothing written, no spinner.
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('irtifa GPS'), findsNothing);
    expect(find.textContaining('irtifa alınamadı'), findsNothing);
    // Rebuilds while the page stays visible start nothing more.
    await tester.pump(const Duration(seconds: 1));
    expect(rig.location.calls, hasLength(1));
  });

  testWidgets('a tap 3 s later writes pressure AND the warm-up altitude', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      precise: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    rig.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await _tap(tester);
    expect(rig.pressure.reads, 1);
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');
    expect(
      find.text(
        "Basınç telefondan alındı: 912,4 hPa · irtifa GPS'ten 900 m.",
      ),
      findsOneWidget,
    );
    // No second GPS request on the tap.
    expect(rig.location.calls, hasLength(1));
  });

  testWidgets('a warm-up older than 10 min: a fresh request on the tap', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      coarse: const LocationFix(39.9, 32.8, altitudeM: 1200),
      precise: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    rig.advance(const Duration(minutes: 10, seconds: 1));
    await _tap(tester);
    expect(rig.location.calls, [
      (precise: true, askPermission: false),
      (precise: false, askPermission: true),
    ]);
    expect(_text(tester, BallisticsFieldKeys.altitude), '1200');
  });

  testWidgets('a warm-up without usable altitude: the tap asks as today', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      coarse: const LocationFix(39.9, 32.8, altitudeM: 1200),
      precise: _noAltitude,
    );
    rig.advance(const Duration(seconds: 3));
    await _tap(tester);
    expect(rig.location.calls, hasLength(2));
    expect(rig.location.calls.last, (precise: false, askPermission: true));
    expect(_text(tester, BallisticsFieldKeys.altitude), '1200');
  });

  testWidgets('no permission: no warm-up GPS request and no prompt', (
    tester,
  ) async {
    final rig = await _open(tester, granted: false);
    expect(rig.location.calls, [(precise: true, askPermission: false)]);
    expect(rig.location.gpsRequests, 0);
    expect(rig.location.prompts, 0);
    // The button keeps today's behaviour: it may ask.
    await _tap(tester);
    expect(rig.location.prompts, 1);
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    expect(find.textContaining('irtifa alınamadı, elle girin'), findsOneWidget);
  });

  testWidgets('a running warm-up is awaited for what is left of 8 s', (
    tester,
  ) async {
    final hold = Completer<LocationResult>();
    final rig = await _open(tester, hold: hold);
    rig.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await _tap(tester);
    hold.complete(const LocationFix(39.9, 32.8, altitudeM: 850));
    await tester.pump();
    await tester.pump();
    expect(_text(tester, BallisticsFieldKeys.altitude), '850');
    expect(rig.location.calls, hasLength(1));
  });

  testWidgets('a warm-up silent past the 8 s: "irtifa alınamadı" as today', (
    tester,
  ) async {
    final hold = Completer<LocationResult>();
    final rig = await _open(tester, hold: hold);
    rig.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await _tap(tester);
    // 8 s from the warm-up's start: 5 s after the tap.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
    expect(find.textContaining('irtifa alınamadı, elle girin'), findsOneWidget);
    hold.complete(const LocationFix(39.9, 32.8, altitudeM: 850));
    await tester.pump();
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
  });

  testWidgets('a typed İrtifa is never overwritten', (tester) async {
    final hold = Completer<LocationResult>();
    final rig = await _open(tester, hold: hold);
    await _tap(tester);
    // Typed while the button waits for the GPS.
    await tester.enterText(_field(BallisticsFieldKeys.altitude), '1500');
    hold.complete(const LocationFix(39.9, 32.8, altitudeM: 850));
    await tester.pump();
    await tester.pump();
    expect(_text(tester, BallisticsFieldKeys.pressure), '912.4');
    expect(_text(tester, BallisticsFieldKeys.altitude), '1500');

    // Typed after the fill: a later warm-up never writes into the box.
    rig.location
      ..preciseHold = null
      ..preciseResult = const LocationFix(39.9, 32.8, altitudeM: 700);
    rig.tab.value = 1;
    await tester.pump();
    rig.advance(const Duration(minutes: 11));
    rig.tab.value = 0;
    await tester.pump();
    await tester.pump();
    expect(rig.location.calls, hasLength(2));
    expect(_text(tester, BallisticsFieldKeys.altitude), '1500');
  });

  testWidgets('Sıfırla empties İrtifa; the next tap fills it again', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      precise: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    await _tap(tester);
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');
    final reset = find.byKey(const Key('environment-pressure-reset'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pump();
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
    expect(_text(tester, BallisticsFieldKeys.pressure), '');
    await _tap(tester);
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');
    expect(rig.location.calls, hasLength(1));
  });

  testWidgets('re-visible after > 10 min: one new warm-up; sooner: none', (
    tester,
  ) async {
    final rig = await _open(
      tester,
      precise: const LocationFix(39.9, 32.8, altitudeM: 900),
    );
    expect(rig.location.calls, hasLength(1));
    rig.tab.value = 1;
    await tester.pump();
    rig.advance(const Duration(minutes: 9));
    rig.tab.value = 0;
    await tester.pump();
    expect(rig.location.calls, hasLength(1));

    rig.tab.value = 1;
    await tester.pump();
    rig.advance(const Duration(minutes: 2));
    rig.tab.value = 0;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(rig.location.calls, [
      (precise: true, askPermission: false),
      (precise: true, askPermission: false),
    ]);
    // The new warm-up is fresh: the tap uses it without asking again.
    await _tap(tester);
    expect(_text(tester, BallisticsFieldKeys.altitude), '900');
    expect(rig.location.calls, hasLength(2));
  });

  testWidgets('hidden tab: no warm-up until Hava Durumu is shown', (
    tester,
  ) async {
    final location = TestLocation(_noAltitude);
    final tab = ValueNotifier(1);
    addTearDown(tab.dispose);
    await tester.pumpWidget(
      host(
        Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: tab,
            builder: (context, index, _) => IndexedStack(
              index: index,
              children: const [
                BallisticsScreen(
                  profile: _profile,
                  view: BallisticsView.environment,
                ),
                SizedBox.expand(),
              ],
            ),
          ),
        ),
        services: testServices(location: location),
      ),
    );
    await tester.pump();
    expect(location.calls, isEmpty);
    tab.value = 0;
    await tester.pump();
    expect(location.calls, hasLength(1));
  });

  testWidgets('background drops the running warm-up; no pending timers', (
    tester,
  ) async {
    final hold = Completer<LocationResult>();
    final rig = await _open(tester, hold: hold);
    await _lifecycle(tester, _toBackground);
    // The cancelled request's answer is ignored.
    hold.complete(const LocationFix(39.9, 32.8, altitudeM: 850));
    await tester.pump();
    rig.location
      ..preciseHold = null
      ..preciseResult = _noAltitude;
    await _lifecycle(tester, _toForeground);
    // Visible again: the warm-up asks once more (the first was dropped).
    expect(rig.location.calls, hasLength(2));
    await _tap(tester);
    expect(rig.location.calls, hasLength(3));
    expect(_text(tester, BallisticsFieldKeys.altitude), '');
    expect(find.textContaining('irtifa alınamadı, elle girin'), findsOneWidget);
  });

  testWidgets('dispose with a running warm-up leaves nothing pending', (
    tester,
  ) async {
    final hold = Completer<LocationResult>();
    final rig = await _open(tester, hold: hold);
    expect(rig.location.calls, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    hold.complete(const LocationFix(39.9, 32.8, altitudeM: 850));
    await tester.pump();
    // The test framework fails on pending timers after this point.
  });
}
