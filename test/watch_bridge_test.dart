import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sniper_turk/services/watch/watch_bridge.dart';
import 'package:sniper_turk/services/watch/watch_solution.dart';

class _FakeTransport implements WatchTransport {
  WatchSendResult result = WatchSendResult.sent;
  final sent = <Map<String, Object>>[];
  final controller = StreamController<Map<Object?, Object?>>.broadcast();

  @override
  Future<WatchSendResult> send(Map<String, Object> message) async {
    sent.add(message);
    return result;
  }

  @override
  Stream<Map<Object?, Object?>> get incoming => controller.stream;
}

WatchSolution _solution({
  int range = 600,
  int up = 47,
  double upAngle = 4.7,
  double rightAngle = 0.6,
  double? angle,
  DateTime? at,
}) => WatchSolution(
  ok: true,
  profile: 'Tikka T3x .308',
  range: range,
  rangeUnit: 'm',
  rangeStep: 10,
  up: up,
  right: 6,
  upAngle: upAngle,
  rightAngle: rightAngle,
  unit: 'MRAD',
  click: 0.1,
  windSpeed: 3.04,
  windUnit: 'm/s',
  windClock: 3,
  angle: angle,
  at: at ?? DateTime.utc(2026, 10, 11, 14, 32),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatchSolution.toMessage', () {
    test('carries every field the watch shows', () {
      final m = _solution().toMessage();
      expect(m, {
        'v': 1,
        'ok': true,
        'profile': 'Tikka T3x .308',
        'at': DateTime.utc(2026, 10, 11, 14, 32).millisecondsSinceEpoch,
        'range': 600,
        'rangeUnit': 'm',
        'rangeStep': 10,
        'up': 47,
        'right': 6,
        'upAngle': 4.7,
        'rightAngle': 0.6,
        'unit': 'MRAD',
        'click': 0.1,
        'windSpeed': 3.0,
        'windUnit': 'm/s',
        'windClock': 3,
      });
    });

    test('an angle that rounds to zero is never negative', () {
      final m = _solution(rightAngle: -0.004).toMessage();
      expect(m['rightAngle'], 0.0);
      expect((m['rightAngle']! as double).isNegative, isFalse);
    });

    test('no solution sends no clicks', () {
      final m = WatchSolution.none(
        profile: 'Tikka',
        at: DateTime.utc(2026),
      ).toMessage();
      expect(m['ok'], false);
      expect(m.containsKey('up'), isFalse);
      expect(m.containsKey('right'), isFalse);
      expect(m.containsKey('range'), isFalse);
    });

    test('withTime only moves the timestamp', () {
      final s = _solution();
      final later = s.withTime(DateTime.utc(2027));
      expect(later.contentKey(), s.contentKey());
      expect(
        later.toMessage()['at'],
        DateTime.utc(2027).millisecondsSinceEpoch,
      );
    });

    test('carries the shot angle the solution used, 1 decimal', () {
      expect(_solution(angle: 12.54).toMessage()['angle'], 12.5);
      expect(_solution(angle: -3.06).toMessage()['angle'], -3.1);
      final flat = _solution(angle: -0.04).toMessage()['angle']! as double;
      expect(flat, 0.0);
      expect(flat.isNegative, isFalse);
    });

    test('without an angle (older callers) no angle field travels', () {
      expect(_solution().toMessage().containsKey('angle'), isFalse);
    });

    test('a changed angle is new content for the watch', () {
      expect(
        _solution(angle: 12.5).contentKey(),
        isNot(_solution(angle: 0).contentKey()),
      );
      expect(_solution(angle: 12.5).withTime(DateTime.utc(2027)).angle, 12.5);
    });

    test('no solution sends no angle', () {
      final m = WatchSolution.none(
        profile: 'Tikka',
        at: DateTime.utc(2026),
      ).toMessage();
      expect(m.containsKey('angle'), isFalse);
    });

    test('no wind entered sends no wind fields', () {
      final s = WatchSolution(
        ok: true,
        profile: 'P',
        range: 100,
        rangeUnit: 'm',
        rangeStep: 10,
        up: 0,
        right: 0,
        upAngle: 0,
        rightAngle: 0,
        unit: 'MOA',
        click: 0.25,
        windSpeed: 0,
        windUnit: 'm/s',
        at: DateTime.utc(2026),
      );
      expect(s.toMessage().containsKey('windSpeed'), isFalse);
    });
  });

  group('WatchBridge', () {
    test('same content is not resent within the refresh interval', () async {
      var now = DateTime.utc(2026, 1, 1, 10);
      final t = _FakeTransport();
      final bridge = WatchBridge(transport: t, clock: () => now);
      await bridge.publish(_solution());
      now = now.add(const Duration(seconds: 59));
      await bridge.publish(_solution());
      expect(t.sent, hasLength(1));
      await bridge.publish(_solution(up: 48));
      expect(t.sent, hasLength(2));
    });

    test('same content is refreshed after 60 s so the watch never '
        'calls an open, current solution stale', () async {
      var now = DateTime.utc(2026, 1, 1, 10);
      final t = _FakeTransport();
      final bridge = WatchBridge(transport: t, clock: () => now);
      await bridge.publish(_solution(at: now));
      now = now.add(const Duration(seconds: 60));
      await bridge.publish(_solution(at: now));
      expect(t.sent, hasLength(2));
      expect(t.sent.last['at'], now.millisecondsSinceEpoch);
    });

    test(
      'not delivered (no watch) is retried only after the interval',
      () async {
        var now = DateTime.utc(2026, 1, 1, 10);
        final t = _FakeTransport()..result = WatchSendResult.notDelivered;
        final bridge = WatchBridge(transport: t, clock: () => now);
        for (var i = 0; i < 30; i++) {
          await bridge.publish(_solution()); // e.g. every frame of a drag
        }
        expect(t.sent, hasLength(1));
        now = now.add(const Duration(seconds: 61));
        t.result = WatchSendResult.sent;
        await bridge.publish(_solution());
        expect(t.sent, hasLength(2));
      },
    );

    test('goes quiet for good when the native side is missing', () async {
      final t = _FakeTransport()..result = WatchSendResult.unavailable;
      final bridge = WatchBridge(transport: t);
      await bridge.publish(_solution());
      await bridge.publish(_solution(up: 1));
      expect(t.sent, hasLength(1));
      expect(bridge.available, isFalse);
    });

    test('a throwing transport never reaches the caller', () async {
      final bridge = WatchBridge(transport: _ThrowingTransport());
      await expectLater(bridge.publish(_solution()), completes);
    });

    test('only whole distances inside 1…max pass from the watch', () async {
      final t = _FakeTransport();
      final bridge = WatchBridge(transport: t, maxRange: 1500);
      final got = <int>[];
      final sub = bridge.rangeRequests.listen(got.add);
      for (final v in <Object?>[650, 0, -10, 2000, 12.5, '700', null, 1500]) {
        t.controller.add({'type': 'setRange', 'value': v});
      }
      t.controller.add({'type': 'other', 'value': 300});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got, [650, 1500]);
    });

    test('only finite shot angles inside ±60° pass from the watch', () async {
      final t = _FakeTransport();
      final bridge = WatchBridge(transport: t);
      final got = <double>[];
      final sub = bridge.angleRequests.listen(got.add);
      for (final v in <Object?>[
        12.5,
        double.nan,
        double.infinity,
        90,
        -60.0,
        60.01,
        '20',
        null,
        true,
        -3,
        12.54,
      ]) {
        t.controller.add({'type': 'setAngle', 'value': v});
      }
      t.controller.add({'type': 'setRange', 'value': 30});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got, [12.5, -60.0, -3.0, 12.5]);
    });

    test('a shot angle is never taken as a distance', () async {
      final t = _FakeTransport();
      final bridge = WatchBridge(transport: t);
      final got = <int>[];
      final sub = bridge.rangeRequests.listen(got.add);
      t.controller.add({'type': 'setAngle', 'value': 15});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(got, isEmpty);
    });
  });

  group('MethodChannelWatchTransport', () {
    const channel = MethodChannel('sniper_turk/watch_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('no native handler → unavailable, no exception', () async {
      final t = MethodChannelWatchTransport(channel);
      expect(await t.send({'v': 1}), WatchSendResult.unavailable);
    });

    test('native true → sent, false → notDelivered', () async {
      var answer = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'publish');
        return answer;
      });
      final t = MethodChannelWatchTransport(channel);
      expect(await t.send({'v': 1}), WatchSendResult.sent);
      answer = false;
      expect(await t.send({'v': 1}), WatchSendResult.notDelivered);
    });

    test('native error → notDelivered', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'x');
      });
      final t = MethodChannelWatchTransport(channel);
      expect(await t.send({'v': 1}), WatchSendResult.notDelivered);
    });

    test('fromWatch calls reach the incoming stream', () async {
      final t = MethodChannelWatchTransport(channel);
      final got = <Map<Object?, Object?>>[];
      final sub = t.incoming.listen(got.add);
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('fromWatch', {'type': 'setRange', 'value': 650}),
        ),
        (_) {},
      );
      await sub.cancel();
      expect(got, [
        {'type': 'setRange', 'value': 650},
      ]);
    });
  });
}

class _ThrowingTransport implements WatchTransport {
  @override
  Future<WatchSendResult> send(Map<String, Object> message) =>
      Future.error(StateError('boom'));

  @override
  Stream<Map<Object?, Object?>> get incoming => const Stream.empty();
}
