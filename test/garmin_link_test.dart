import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/features/tools/garmin_pair_tile.dart';
import 'package:sniper_turk/features/tools/tools_screen.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/ui/menzil_theme.dart';
import 'package:sniper_turk/ui/menzil_widgets.dart';

class _Link implements WatchTransport {
  WatchSendResult result;
  Object? error;
  final sent = <Map<String, Object>>[];
  final controller = StreamController<Map<Object?, Object?>>.broadcast();

  _Link(this.result);

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    sent.add(message);
    final e = error;
    if (e != null) throw e;
    return result;
  }

  @override
  Stream<Map<Object?, Object?>> get incoming => controller.stream;
}

class _FakeGarmin implements GarminLink {
  int? count;
  int selects = 0;
  final changes = StreamController<int>.broadcast();

  _FakeGarmin(this.count);

  @override
  Future<int?> deviceCount() async => count;

  @override
  Stream<int> get deviceCountChanges => changes.stream;

  @override
  Future<bool> selectDevice() async {
    selects++;
    return count != null;
  }
}

Widget _host(Widget child) => MaterialApp(
  theme: MenzilTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MultiWatchTransport', () {
    test('every link gets the message; any sent → sent', () async {
      final apple = _Link(WatchSendResult.notDelivered);
      final garmin = _Link(WatchSendResult.sent);
      final t = MultiWatchTransport([apple, garmin]);
      expect(await t.send({'v': 1}), WatchSendResult.sent);
      expect(apple.sent, hasLength(1));
      expect(garmin.sent, hasLength(1));
    });

    test('unavailable only when no link has a native side', () async {
      final t = MultiWatchTransport([
        _Link(WatchSendResult.unavailable),
        _Link(WatchSendResult.unavailable),
      ]);
      expect(await t.send({'v': 1}), WatchSendResult.unavailable);
      final mixed = MultiWatchTransport([
        _Link(WatchSendResult.unavailable),
        _Link(WatchSendResult.notDelivered),
      ]);
      expect(await mixed.send({'v': 1}), WatchSendResult.notDelivered);
    });

    test('a throwing link does not hide the other one', () async {
      final broken = _Link(WatchSendResult.sent)..error = StateError('boom');
      final ok = _Link(WatchSendResult.sent);
      final t = MultiWatchTransport([broken, ok]);
      expect(await t.send({'v': 1}), WatchSendResult.sent);
    });

    test('messages from both watches arrive on one stream', () async {
      final apple = _Link(WatchSendResult.sent);
      final garmin = _Link(WatchSendResult.sent);
      final t = MultiWatchTransport([apple, garmin]);
      final got = <Object?>[];
      final sub = t.incoming.listen((m) => got.add(m['value']));
      apple.controller.add({'type': 'setRange', 'value': 600});
      garmin.controller.add({'type': 'setRange', 'value': 650});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got, [600, 650]);
    });

    test('a Garmin range request reaches WatchBridge', () async {
      final apple = _Link(WatchSendResult.unavailable);
      final garmin = _Link(WatchSendResult.sent);
      final bridge = WatchBridge(
        transport: MultiWatchTransport([apple, garmin]),
      );
      final got = <int>[];
      final sub = bridge.rangeRequests.listen(got.add);
      garmin.controller.add({'type': 'setRange', 'value': 700});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got, [700]);
    });
  });

  group('GarminLink', () {
    const channel = MethodChannel('sniper_turk/garmin_test');
    const devices = EventChannel('sniper_turk/garmin_test/devices');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockStreamHandler(devices, null);
    });

    test('no Garmin bridge → null, false, no exception', () async {
      final link = GarminLink(channel, devices);
      expect(await link.deviceCount(), isNull);
      expect(await link.selectDevice(), isFalse);
      expect(await link.deviceCountChanges.toList(), isEmpty);
    });

    test('device count events arrive on deviceCountChanges', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 0);
      messenger.setMockStreamHandler(
        devices,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success(0);
            events.success(2);
          },
        ),
      );
      final link = GarminLink(channel, devices);
      expect(await link.deviceCountChanges.take(2).toList(), [0, 2]);
    });

    test('bridge answers count and selection', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return call.method == 'deviceCount' ? 2 : true;
      });
      final link = GarminLink(channel);
      expect(await link.deviceCount(), 2);
      expect(await link.selectDevice(), isTrue);
      expect(calls, ['deviceCount', 'selectDevice']);
    });
  });

  group('GarminPairTile', () {
    testWidgets('invisible without a Garmin bridge', (tester) async {
      await tester.pumpWidget(_host(GarminPairTile(link: _FakeGarmin(null))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tool-garmin')), findsNothing);
      expect(find.text('Garmin saati'), findsNothing);
    });

    testWidgets('no watch chosen yet: tap opens Garmin Connect', (
      tester,
    ) async {
      final g = _FakeGarmin(0);
      await tester.pumpWidget(_host(GarminPairTile(link: g)));
      await tester.pumpAndSettle();
      expect(find.text('Garmin saati'), findsOneWidget);
      expect(find.textContaining('Saat seçilmedi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tool-garmin')));
      expect(g.selects, 1);
    });

    testWidgets('shows how many watches are shared', (tester) async {
      await tester.pumpWidget(_host(GarminPairTile(link: _FakeGarmin(1))));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 saat bağlı'), findsOneWidget);
    });

    testWidgets('uses the Araçlar tile look: white icon on grey-blue', (
      tester,
    ) async {
      await tester.pumpWidget(_host(GarminPairTile(link: _FakeGarmin(1))));
      await tester.pumpAndSettle();
      final tile = tester.widget<MenzilToolTile>(find.byType(MenzilToolTile));
      expect(tile.plainIcon, isTrue);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(MenzilToolTile),
          matching: find.byIcon(Icons.watch_outlined),
        ),
      );
      expect(icon.color, MenzilToolTile.plainIconColor);
    });

    testWidgets('a new count from Garmin Connect updates the subtitle', (
      tester,
    ) async {
      final g = _FakeGarmin(0);
      await tester.pumpWidget(_host(GarminPairTile(link: g)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saat seçilmedi'), findsOneWidget);
      g.changes.add(2);
      await tester.pumpAndSettle();
      expect(find.textContaining('2 saat bağlı'), findsOneWidget);
      expect(find.textContaining('Saat seçilmedi'), findsNothing);
    });

    testWidgets('Araçlar without the bridge has no Garmin tile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const ToolsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tool-garmin')), findsNothing);
      expect(find.byKey(const Key('tool-usage-guide')), findsOneWidget);
    });
  });
}
