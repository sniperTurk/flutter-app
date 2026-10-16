import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/ballistics/ballistics_screen.dart';
import 'package:sniper_turk/models/domain.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';

// Gazi Sniper 6–36×56 FFP: 0.1 mrad clicks (same profile as the other
// ballistics widget tests).
const _profile = RifleProfile(
  id: 'p-watch',
  name: 'Saat profili',
  rifleId: 'hatsan-hercules-635',
  ammunitionId: 'gmaz-51',
  scopeId: 'gazi-6-36',
  muzzleVelocityMps: 270,
  zeroRangeM: 25,
  sightHeightMm: 60,
  pressureBar: 200,
);

class _FakeTransport implements WatchTransport {
  final sent = <Map<String, Object>>[];
  final controller = StreamController<Map<Object?, Object?>>.broadcast();

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    sent.add(message);
    return WatchSendResult.sent;
  }

  @override
  Stream<Map<Object?, Object?>> get incoming => controller.stream;
}

Widget _app(BallisticsView view) => MaterialApp(
  home: Scaffold(
    body: BallisticsScreen(profile: _profile, view: view),
  ),
);

void main() {
  testWidgets('Atış sends its solution to the watch and takes its distance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = _FakeTransport();
    WatchBridge.instance = WatchBridge(transport: t);
    addTearDown(() => WatchBridge.instance = WatchBridge());

    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    // Hava Durumu alone shows no turrets, so nothing goes to the watch yet.
    expect(t.sent.where((m) => m['ok'] == true), isEmpty);

    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    final first = t.sent.lastWhere((m) => m['ok'] == true);
    expect(first['profile'], 'Saat profili');
    expect(first['unit'], 'MRAD');
    expect(first['click'], 0.1);
    expect(first['range'], 100);
    expect(first['rangeUnit'], 'm');
    expect(first['rangeStep'], 5); // PCP: 5 m steps
    expect(first['up'], isA<int>());

    // The watch asks for 60 m: the phone solves and answers.
    t.controller.add({'type': 'setRange', 'value': 60});
    await tester.pumpAndSettle();
    final answer = t.sent.last;
    expect(answer['ok'], true);
    expect(answer['range'], 60);
    expect(answer['up'], isNot(first['up']));

    // Leaving Atış (inputs may change on Hava/Pro): the watch must not keep
    // showing the old clicks as current.
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    expect(t.sent.last['ok'], false);
    expect(t.sent.last.containsKey('up'), isFalse);
  });

  testWidgets('a shot angle from the Garmin level enters as Açı and is '
      'solved', (tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = _FakeTransport();
    WatchBridge.instance = WatchBridge(transport: t);
    addTearDown(() => WatchBridge.instance = WatchBridge());

    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    final first = t.sent.lastWhere((m) => m['ok'] == true);
    expect(first['angle'], 0.0);

    // "Açıyı gönder" on the watch: 12.5° up.
    t.controller.add({'type': 'setAngle', 'value': 12.5});
    await tester.pumpAndSettle();
    final answer = t.sent.last;
    expect(answer['ok'], true);
    expect(answer['angle'], 12.5);
    expect(answer['range'], first['range']);
    expect(answer['upAngle'], isNot(first['upAngle']));

    // Invalid angles change nothing.
    final before = t.sent.length;
    for (final v in <Object?>[double.nan, 90, -90, 'on iki', null]) {
      t.controller.add({'type': 'setAngle', 'value': v});
    }
    await tester.pumpAndSettle();
    expect(t.sent.skip(before).where((m) => m['angle'] != 12.5), isEmpty);

    // It stays the Açı of every later solution (here a watch distance).
    t.controller.add({'type': 'setRange', 'value': 60});
    await tester.pumpAndSettle();
    expect(t.sent.last['range'], 60);
    expect(t.sent.last['angle'], 12.5);
  });

  testWidgets('without a native watch side Atış works as before', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Default bridge over the real channel: no handler in tests.
    WatchBridge.instance = WatchBridge();
    await tester.pumpWidget(_app(BallisticsView.environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(BallisticsView.shot));
    await tester.pumpAndSettle();
    // Missing native side → MissingPluginException is swallowed (the
    // transport itself is covered in watch_bridge_test.dart).
    expect(tester.takeException(), isNull);
  });
}
